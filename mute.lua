local botlib = require('botlib')
local discordia = require('discordia')
local fs = require('fs')
local json = require('json')
local client = discordia.Client()
local config = json.parse(fs.readFileSync("mute.config") or '[]') or {}

function mute(user,guild)
  if type(guild) == 'string' then
    guild = client:getGuild(guild)
  end
  local function getuser(member)
    return member.username == string.sub(user,1,-6) and member.discriminator == string.sub(user,-4)
  end
  local function getrole(role)
    return string.lower(role.name) == string.lower(config.role)
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
    return string.lower(role.name) == string.lower(config.role)
  end
  local member = guild:findMember(getuser)
  local muted = guild:findRole(getrole)
  if muted and member then
    member:removeRole(muted)
	member:setMute(false)
  end
end
function unmutetimed()
  local mutelist = json.parse(fs.readFileSync("muted.list") or '[]') or {}
  local mod = 0
  for i=1,#mutelist do
    i = i-mod
    if mutelist[i].duration and mutelist[i].duration < os.time() then
	  unmute(mutelist[i].user..'#'..mutelist[i].discriminator,mutelist[i].guild)
	  local function getuser(member)
        return member.username == mutelist[i].user and member.discriminator == mutelist[i].discriminator
      end
	  client:getGuild(mutelist[i].guild):getChannel(mutelist[i].channel):sendMessage('Unmuted '..client:getGuild(mutelist[i].guild):findMember(getuser).name..'.')
      table.remove(mutelist,i)
	  mod = mod+1
	end
  end
  fs.writeFileSync("muted.list",json.stringify(mutelist))
end
client:on('ready', function()
  print("bot connected to discord with id "..client.user.id)
  unmutetimed()
end)

client:on('heartbeat', function()
unmutetimed()
end)

client:on('messageCreate', function(message)
  if not message.author.bot and message.guild then
    unmutetimed()
    local args = botlib.command(message.content)
	canmute = nil
	for role in message.guild:getMember(message.author.id).roles do
	  if role.permissions:has('manageMessages') then
	    canmute = true
		break
	  end
	end
	if args[1] == "!unmute" and canmute then
	  local mutelist = json.parse(fs.readFileSync("muted.list") or '[]') or {}
      local str = botlib.tabtostr(args,2)
	  local str = string.gsub(str,"^%s*","")
	  local sub1,sub2 = string.find(str,".*#%d%d%d%d")
	  if sub1 then
		local user = string.sub(str,sub1,sub2)
		for i = 1,#mutelist do
		  if mutelist[i].user == string.sub(user,1,-6) and mutelist[i].discriminator == string.sub(user,-4) and mutelist[i].guild == message.guild.id then
			table.remove(mutelist,i)
			fs.writeFileSync("muted.list",json.stringify(mutelist))
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
	  local mutelist = json.parse(fs.readFileSync("muted.list") or '[]') or {}
	  local str = botlib.tabtostr(args,2)
	  local str = string.gsub(str,"^%s*","")
      local sub1,sub2 = string.find(str,".*#%d%d%d%d")
      if sub1 then
        local user = string.sub(str,sub1,sub2)
        local time,display = botlib.time(string.sub(str,sub2+1))
		for i = 1,#mutelist+1 do
		  if i == #mutelist+1 then
			local function getuser(member)
			  return member.username == string.sub(user,1,-6) and member.discriminator == string.sub(user,-4)
			end
			mutelist[i] = {user=string.sub(user,1,-6),discriminator=string.sub(user,-4),guild=message.guild.id,channel=message.channel.id,duration = time > 0 and (os.time()+time) or nil}
			fs.writeFileSync("muted.list",json.stringify(mutelist))
			mute(user,message.guild)
			message.channel:sendMessage('Muted '..message.guild:findMember(getuser).name..(time > 0 and (' for '..display) or ' indefinitely.'))
			break
		  elseif mutelist[i].user == string.sub(user,1,-6) and mutelist[i].discriminator == string.sub(user,-4) and mutelist[i].guild == message.guild.id then
			break
		  end
		end
      end
	end
  end
end)

local token = fs.readFileSync('mute.token')
client:run(token)