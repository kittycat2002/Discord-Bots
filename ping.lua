local discordia = require('discordia')
local fs = require('fs')
local json = require('json')
local client = discordia.Client()
local config = json.parse(fs.readFileSync("ping.config") or '[]') or {}

client:on('ready', function()
  print("bot connected to discord with id "..client.user.id)
  role = client:getGuild(config.guild):getRole('name',config.role)
end)

client:on('messageCreate', function(message)
  if not message.author.bot and message.guild and message:mentionsObject(client.user) then
    if message.member:hasRole(role) then
	  message.member:removeRole(role)
	  message.channel:sendMessage('Removed '..message.member.name..' from the ping role')
	else
	  message.member:addRole(role)
	  message.channel:sendMessage('Added '..message.member.name..' to the ping role')
	end
  end
end)

local token = fs.readFileSync('ping.token')
client:run(token)