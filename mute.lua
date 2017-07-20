local discordia = require('discordia')
local fs = require('fs')
local json = require('json')
local client = discordia.Client()

local function tabtostr(tab,s,e)
  local str = ''
  for i = (s or 1),(e or #tab) do
	str = str..tab[i]..' '
  end
  return string.sub(str,1,-2)
end

function mute(user,guild)
  if type(guild) == 'string' then
    guild = client:getGuild(guild)
  end
  local function getuser(member)
    return member.username == string.sub(user,1,-6) and member.discriminator == string.sub(user,-4)
  end
  local function getrole(role)
    return string.lower(role.name) == 'muted'
  end
  local member = guild:findMember(getuser)
  local muted = guild:findRole(getrole)
  if muted then
    member:addRole(muted)
	member:setMute(true)
  end
end
function unmute(user,guild)
  if type(guild) == 'string' then
    guild = client:getGuild(guild)
  end
  local function getuser(member)
    return member.username == string.sub(user,1,-6) and member.discriminator == string.sub(user,-4)
  end
  local function getrole(role)
    return string.lower(role.name) == 'muted'
  end
  local member = guild:findMember(getuser)
  local muted = guild:findRole(getrole)
  if muted and member then
    member:removeRole(muted)
	member:setMute(false)
  end
end
function unmutetimed()
  local mutelist = json.parse(fs.readFileSync("mute.config")) or {}
  local mod = 0
  for i=1,#mutelist do
    i = i-mod
    if mutelist[i].duration < os.time() then
	  unmute(mutelist[i].user..'#'..mutelist[i].discriminator,mutelist[i].guild)
	  local function getuser(member)
        return member.username == mutelist[i].user and member.discriminator == mutelist[i].discriminator
      end
	  client:getGuild(mutelist[i].guild):getChannel(mutelist[i].channel):sendMessage('Unmuted '..client:getGuild(mutelist[i].guild):findMember(getuser).name..'.')
      table.remove(mutelist,i)
	  mod = mod+1
	end
  end
  fs.writeFileSync("mute.config",json.stringify(mutelist))
end
client:on('ready', function()
  print("bot connected to discord with id "..client.user.id)
  unmutetimed()
end)

client:on('heartbeat', function()
unmutetimed()
end)

client:on('messageCreate', function(message)
  if not message.author.bot then
    unmutetimed()
    local arg = message.content
	local args = {}
	local i = 0
	if arg then
	  while #arg > 0 do
		i = i + 1
		if string.match(arg,'^%s+') then
	  	  _,j = string.find(arg,'^%s+')
		elseif string.match(arg,'^[\'"]') then
		  if string.match(arg, "^%b''") then
			args[i] = string.sub(string.match(arg, "^%b''"),2,-2)
			_,j = string.find(arg,"^%b''")
		  elseif string.match(arg, '^%b""') then
			args[i] = string.sub(string.match(arg, '^%b""'),2,-2)
			_,j = string.find(arg,'^%b""')
		  else
		    i = i - 1
		    args[i] = args[i]..string.match(arg, "[^%s]+")
			_,j = string.find(arg,"[^%s]+")
		  end
		else
		  args[i] = string.match(arg, "[^%s\"']+")
		  _,j = string.find(arg,"[^%s\"']+")
		end
		arg = string.sub(arg,j+1)
		if not args[i] then
		  i = i - 1
		end
	  end
	end
	canmute = nil
	for role in message.guild:getMember(message.author.id).roles do
	  if role.permissions:has('manageMessages') then
	    canmute = true
		break
	  end
	end
	if args[1] == "!unmute" and canmute then
	  local mutelist = json.parse(fs.readFileSync("mute.config")) or {}
      local str = tabtostr(args,2)
	  local str = string.gsub(str,"^%s*","")
	  local sub1,sub2 = string.find(str,".*#%d%d%d%d")
	  if sub1 then
		local user = string.sub(str,sub1,sub2)
		for i = 1,#mutelist do
		  if mutelist[i].user == string.sub(user,1,-6) and mutelist[i].discriminator == string.sub(user,-4) and mutelist[i].guild == message.guild.id then
			table.remove(mutelist,i)
			fs.writeFileSync("mute.config",json.stringify(mutelist))
			unmute(user,message.guild)
			local function getuser(member)
			  return member.username == string.sub(user,1,-6) and member.discriminator == string.sub(user,-4)
			end
			message.channel:sendMessage('Unmuted '..message.guild:findMember(getuser).name..'.')
			break
		  end
		end
	  end
	elseif args[1] == "!mute" and canmute then
	  local mutelist = json.parse(fs.readFileSync("mute.config")) or {}
	  local str = tabtostr(args,2)
	  local str = string.gsub(str,"^%s*","")
      local sub1,sub2 = string.find(str,".*#%d%d%d%d")
      if sub1 then
        local user = string.sub(str,sub1,sub2)
        local str = string.sub(str,sub2+1)
        local d = tonumber(string.sub(string.match(str,'%d+d') or '',1,-2))
		local h = tonumber(string.sub(string.match(str,'%d+h') or '',1,-2))
		local m = tonumber(string.sub(string.match(str,'%d+m') or '',1,-2))
		local s = tonumber(string.sub(string.match(str,'%d+s') or '',1,-2))
		local time = (s or 0) + (m or 0) * 60 + (h or 0) * 3600 + (d or 0) * 86400
		local d = math.floor(time/86400)
		local distime = time - d * 86400
		local h = math.floor(distime/3600)
		local distime = distime - h * 3600
		local m = math.floor(distime/60)
		local distime = distime - m * 60
		local s = distime
		if time > 0 then
		  for i = 1,#mutelist+1 do
			if i == #mutelist+1 then
			  local function getuser(member)
				return member.username == string.sub(user,1,-6) and member.discriminator == string.sub(user,-4)
			  end
			  mutelist[i] = {user=string.sub(user,1,-6),discriminator=string.sub(user,-4),guild=message.guild.id,channel=message.channel.id,duration=os.time()+time}
			  fs.writeFileSync("mute.config",json.stringify(mutelist))
			  mute(user,message.guild)
			  message.channel:sendMessage('Muted '..message.guild:findMember(getuser).name..' for '..(d > 0 and d..'d ' or '')..(h > 0 and h..'h ' or '')..(m > 0 and m..'m ' or '')..(s > 0 and s..'s' or '')..'.')
			  break
			elseif mutelist[i].user == string.sub(user,1,-6) and mutelist[i].discriminator == string.sub(user,-4) and mutelist[i].guild == message.guild.id then
			  mutelist[i].duration = os.time()+time
			  message.channel:sendMessage('Muted '..message.guild:findMember(getuser).name..' for '..(d > 0 and d..'d ' or '')..(h > 0 and h..'h ' or '')..(m > 0 and m..'m ' or '')..(s > 0 and s..'s' or '')..'.')
			  break
			end
		  end
		end
      end
	end
  end
end)

local token = fs.readFileSync('mute.token')
client:run(token)