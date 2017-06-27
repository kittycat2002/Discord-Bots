local discordia = require('discordia')
local fs = require('fs')
local json = require('json')
local timer = require('timer')
local client = discordia.Client()
local config,_,err = json.parse(fs.readFileSync("music.config"))
musiclist = {}

client:on('ready', function()
  print("bot connected to discord with id "..client.user.id)
  channel = client:getGuild(config.guild):getVoiceChannel(config.channel)
  connection = channel:join()
  client:setGameName('Never Gonna Give You Up')
  connection:playFile(config.musicdir.."/Never Gonna Give You Up.mp3")
  client:setGameName()
end)

if err then
  print("Json error.\n"..err)
elseif not fs.existsSync(config.musicdir) then
  print(config.musicdir.." does not exist.")
elseif #fs.readdirSync(config.musicdir) == 0 then
  print("Nothing found in "..config.musicdir)
else
local token = fs.readFileSync('music.token')
client.voice:loadOpus('libopus-x64')
client.voice:loadSodium('libsodium-x64')
client:run(token)
end