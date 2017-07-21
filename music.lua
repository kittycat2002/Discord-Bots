local discordia = require('discordia')
local fs = require('fs')
local http = require('http')
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

local function tabtostr(tab,s,e)
  local str = ''
  for i = (s or 1),(e or #tab) do
	str = str..tab[i]..' '
  end
  return string.sub(str,1,-2)
end
client:on('ready', function()
  print("bot connected to discord with id "..client.user.id)
  channel = client:getGuild(config.guild):getVoiceChannel(config.channel)
  queuechannel = client:getGuild(config.guild):getTextChannel(config.queuechannel)
  connection = channel:join()
  client:setGameName()
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
	  queuechannel:sendMessage('Now playing '..musicname)
	  client:setGameName(musicname)
	  connection:playFile(music.dir.."/"..music.name)
	  client:setGameName()
	end
	timer.sleep(1000)
  end
end)

client:on('messageCreate', function(message)
  if not message.author.bot and message.channel.id == config.queuechannel then
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
		    i = math.max(i -1,1)
		    args[i] = (args[i] or '')..string.match(arg, "[^%s]+")
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
	if message.member.roleCount > 0 then
	  if args[1] == "!queue" and args[2] == "clear" then
		queue = {}
		message.channel:sendMessage('Cleared the queue.')
	  elseif args[1] == "!queue" and args[2] == "remove" then
		if queue[tonumber(args[3])] then
		  message.channel:sendMessage("Removed \""..string.gsub(string.sub(string.sub(queue[tonumber(args[3])].name,string.find(queue[tonumber(args[3])].name,'^.*%.')),1,-2),"[%-_]"," ").."\" from the queue, there "..(#queue == 2 and "is" or "are").." now "..(#queue-1).." "..(#queue == 2 and "song" or "songs").." in the queue.")
		  table.remove(queue,tonumber(args[3]))
		end
	  elseif args[1] == "!nextsong" then
		client.voice:stopStreams()
		client:setGameName()
	  end
	end
	if args[1] == "!queue" and args[2] == "list" then
	  if #queue == 0 then
		message.channel:sendMessage("The queue is currently empty.")
	  else
		local queuelist = ""
		for i=1,#queue do
		  queuelist = queuelist..i..": "..string.gsub(string.sub(string.sub(queue[i].name,string.find(queue[i].name,'^.*%.')),1,-2),"[%-_]"," ").."\n"
		end
		message.channel:sendMessage(queuelist)
	  end
	elseif args[1] == "!queue" and args[2] == "add" then
	  for i=1,#musiclist do
		musicq = musiclist[i]
		if string.lower(string.gsub(string.sub(string.sub(musicq.name,string.find(musicq.name,'^.*%.')),1,-2),"[%-_]"," ")) == string.lower(string.gsub(tabtostr(args,3),"[%-_]"," ")) then
		  table.insert(queue,musicq)
		  message.channel:sendMessage("Added \""..string.gsub(string.sub(string.sub(musicq.name,string.find(musicq.name,'^.*%.')),1,-2),"[%-_]"," ").."\" to the queue, there "..(#queue == 1 and "is" or "are").." now "..#queue.." "..(#queue == 1 and "song" or "songs").." in the queue.")
		  break
		end
	  end
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
client.voice:loadOpus(config.libopus)
client.voice:loadSodium(config.libsodium)
client:run(token)
end