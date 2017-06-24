local discordia = require('discordia')
local fs = require('fs')
local timer = require('timer')
local client = discordia.Client()
musiclist = fs.readdirSync('music')
client:on('ready', function()
  print("bot connected to discord with id "..client.user.id)
  channel = client:getGuild('216411946017095693'):getVoiceChannel('327510823603798016')
  connection = channel:join()
  while true do
    music = musiclist[math.random(1,#musiclist)]
	if channel.memberCount > 1 then
	  client:setGameName(string.sub(music,1,-5))
      connection:playFile("music/"..music)
	  client:setGameName()
	end
    timer.sleep(1000)
  end
end)

local token = fs.readFileSync('music.token')
client.voice:loadOpus('libopus-x64')
client.voice:loadSodium('libsodium-x64')
client:run(token)