local discordia = require('discordia')
local fs = require('fs')
local json = require('json')
local client = discordia.Client()

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
  if muted then
    member:removeRole(muted)
  end
end
function unmutetimed()
  local mutelist = json.parse(fs.readFileSync("mute.config")) or {}
  local mod = 0
  for i=1,#mutelist do
    i = i-mod
    if mutelist[i].duration < os.time() then
	  unmute(mutelist[i].user..'#'..mutelist[i].discriminator,mutelist[i].guild)
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
	canmute = nil
	for role in message.guild:getMember(message.author.id).roles do
	  if role.permissions:has('manageMessages') then
	    canmute = true
		break
	  end
	end
	if string.sub(message.content,1,7) == "!unmute" and canmute then
	  local mutelist = json.parse(fs.readFileSync("mute.config")) or {}
	  local str = message.content
      local str = string.sub(str,9)
	  local str = string.gsub(str,"^%s*","")
	  local sub1,sub2 = string.find(str,".*#%d%d%d%d")
	  if sub1 then
		local user = string.sub(str,sub1,sub2)
		for i = 1,#mutelist do
		  if mutelist[i].user == string.sub(user,1,-6) and mutelist[i].discriminator == string.sub(user,-4) and mutelist[i].guild == message.guild.id then
			table.remove(mutelist,i)
			fs.writeFileSync("mute.config",json.stringify(mutelist))
			unmute(user,message.guild)
			break
		  end
		end
	  end
	elseif string.sub(message.content,1,5) == "!mute" and canmute then
	  local mutelist = json.parse(fs.readFileSync("mute.config")) or {}
	  local str = message.content
      local str = string.sub(str,7)
	  local str = string.gsub(str,"^%s*","")
      local sub1,sub2 = string.find(str,".*#%d%d%d%d")
      if sub1 then
        local user = string.sub(str,sub1,sub2)
        local str = string.sub(str,sub2+1)
        duration = tonumber(string.reverse(string.sub(string.reverse(str),string.find(string.reverse(str),"%d*"))))
		if duration then
		  for i = 1,#mutelist+1 do
			if i == #mutelist+1 then
			  mutelist[i] = {user=string.sub(user,1,-6),discriminator=string.sub(user,-4),guild=message.guild.id,duration=os.time()+duration*60}
			  fs.writeFileSync("mute.config",json.stringify(mutelist))
			  mute(user,message.guild)
			  break
			elseif mutelist[i].user == string.sub(user,1,-6) and mutelist[i].discriminator == string.sub(user,-4) and mutelist[i].guild == message.guild.id then
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