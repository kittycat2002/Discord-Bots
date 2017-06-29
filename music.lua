local discordia = require('discordia')
local fs = require('fs')
local json = require('json')
local timer = require('timer')
local client = discordia.Client()
local config,_,err = json.parse(fs.readFileSync("music.config"))
musiclist = {}
queue = {}
local function musiclistfunction(dir)
  for i=1,#fs.readdirSync(dir) do
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
    if channel.memberCount > 1 then
      musiclistfunction(config.musicdir)
	  if #queue > 0 then
	    music = queue[1]
		table.remove(queue,1)
	  else
		music = musiclist[math.random(1,#musiclist)]
	  end
	  musicname = string.gsub(string.sub(string.sub(music.name,string.find(music.name,'^.*%.')),1,-2),"[%-_]"," ")
	  client:setGameName(musicname)
      connection:playFile(music.dir.."/"..music.name)
	  client:setGameName()
	end
    timer.sleep(1000)
  end
end)

client:on('messageCreate', function(message)
  if message.member.roleCount > 0 then
    if string.lower(string.sub(message.content,1,7)) == "!queue " then
      musiclistfunction(config.musicdir)
      for i=1,#musiclist do
	    musicq = musiclist[i]
	    if string.lower(string.gsub(string.sub(string.sub(musicq.name,string.find(musicq.name,'^.*%.')),1,-2),"[%-_]"," ")) == string.lower(string.gsub(string.sub(message.content,8),"[%-_]"," ")) then
	      table.insert(queue,musicq)
		  break
	    end
      end
    elseif string.lower(string.sub(message.content,1,11)) == "!clearqueue" then
	  queue = {}
	elseif string.lower(string.sub(message.content,1,13)) == "!queueremove " then
	  if tonumber(string.sub(message.content,14)) then
	    table.remove(queue,tonumber(string.sub(message.content,14)))
	  end
	end
  end
  if string.lower(string.sub(message.content,1,10)) == "!queuelist" then
    if #queue == 0 then
	  message.channel:sendMessage("The queue is currently empty.")
	else
	  local queuelist = ""
      for i=1,#queue do
	    queuelist = queuelist..i..": "..string.gsub(string.sub(string.sub(queue[i].name,string.find(queue[i].name,'^.*%.')),1,-2),"[%-_]"," ").."\n"
	  end
	  message.channel:sendMessage(queuelist)
	end
  end
end)

if err then
  print("Json error.\n"..err)
elseif not fs.existsSync(config.musicdir) then
  print(config.musicdir.." does not exist.")
elseif #fs.readdirSync(config.musicdir) == 0 then
  print("Nothing found in "..config.musicdir)
else
musiclistfunction(config.musicdir)
local token = fs.readFileSync('music.token')
client.voice:loadOpus('libopus-x64')
client.voice:loadSodium('libsodium-x64')
client:run(token)
end