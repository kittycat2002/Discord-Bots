local discordia = require('discordia')
local fs = require('fs')
local json = require('json')
local timer = require('timer')
local client = discordia.Client()
musiclist = fs.readdirSync('music')
local config = json.parse(fs.readFileSync("music.config"))
client:on('ready', function()
  print("bot connected to discord with id "..client.user.id)
  channel = client:getGuild(config.guild):getVoiceChannel(config.channel)
  connection = channel:join()
  while true do
    music = musiclist[math.random(1,#musiclist)]
	if channel.memberCount > 1 then
	  musicname = string.sub(music,string.find(music,'^.*%.'))
	  musicname = string.sub(musicname,1,-2)
	  musicname = string.gsub(musicname,"[%-_]"," ")
	  client:setGameName(musicname)
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