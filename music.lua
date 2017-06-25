local discordia = require('discordia')
local fs = require('fs')
local json = require('json')
local timer = require('timer')
local client = discordia.Client()
local config = json.parse(fs.readFileSync("music.config"))
musiclist = {}
local function musiclistfunction(dir)
  for i=1,#fs.readdirSync(dir) do
	print(fs.statSync(dir.."/"..fs.readdirSync(dir)[i]).type)
	if fs.statSync(dir.."/"..fs.readdirSync(dir)[i]).type == 'directory' then
	  musiclistfunction(dir.."/"..fs.readdirSync(dir)[i])
	else
	  table.insert(musiclist,{dir=dir,name=fs.readdirSync(dir)[i]})
	end
  end
end

client:on('ready', function()
  print("bot connected to discord with id "..client.user.id)
  channel = client:getGuild(config.guild):getVoiceChannel(config.channel)
  connection = channel:join()
  while true do
    if os.date('%m') == '04' and os.date('%d') == '01' then
      music = 'Never Gonna Give You Up.mp3'
	else  
	  music = musiclist[math.random(1,#musiclist)]
	end
	if channel.memberCount > 1 then
	  musicname = string.sub(music.name,string.find(music.name,'^.*%.'))
	  musicname = string.sub(musicname,1,-2)
	  musicname = string.gsub(musicname,"[%-_]"," ")
	  client:setGameName(musicname)
      connection:playFile(music.dir.."/"..music.name)
	  client:setGameName()
	end
    timer.sleep(1000)
  end
end)

if not fs.existsSync(config.musicdir) then
  print(config.musicdir.." does not exist.")
elseif #fs.readdirSync(config.musicdir) == 0 then
  print("Nothing found in "..config.musicdir)
else
musiclistfunction(config.musicdir)
local token = fs.readFileSync('music.token')
client.voice:loadOpus('libopus-x64')
client.voice:loadSodium('libsodium-x64')
client:run('MzE3MTcwNjkzOTQ1MTYzNzg1.DDFypQ.V7K6IMRHivA7TgEyRQNP-Zs69l4')
end