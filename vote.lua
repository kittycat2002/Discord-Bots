local discordia = require('discordia')
local fs = require('fs')
local json = require('json')
local client = discordia.Client()

local emojilist = {'🇦','🇧','🇨','🇩','🇪','🇫','🇬','🇭','🇮','🇯','🇰','🇱','🇲','🇳','🇴','🇵','🇶','🇷','🇸','🇹'}

function voteend()
  local votelist = json.parse(fs.readFileSync("vote.config") or '[]') or {}
  local mod = 0
  for i=1,#votelist do
    i = i-mod
    if votelist[i].duration < os.time() then
	  votes = {}
	  for j=1,#votelist[i].options do
	    local k = 0
	    for user in client:getGuild(votelist[i].guild):getChannel(votelist[i].channel):getMessage(votelist[i].message):getReactionUsers(emojilist[j]) do
		  k = k + 1
		end
		votes[j] = k
	  end
	  winner = {{count = 0}}
	  for i = 1,#votes do
	    if votes[i] > winner[1].count then
		  winner = {{id = i,count = votes[i]}}
		elseif votes[i] == winner[1].count then
		  table.insert(winner,{id = i,count = votes[i]})
		end
	  end
	  winner = votelist[i].options[winner[math.random(#winner)].id]
	  client:getGuild(votelist[i].guild):getChannel(votelist[i].channel):sendMessage('"'..winner..'" won the vote.')
      table.remove(votelist,i)
	  mod = mod+1
	end
  end
  fs.writeFileSync("vote.config",json.stringify(votelist))
end

client:on('ready', function()
  print("bot connected to discord with id "..client.user.id)
end)
 
 client:on('heartbeat', function()
  voteend()
end)
 
client:on('messageCreate', function(message)
  if not message.author.bot then
    voteend()
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
	if args[1] == '!vote' and tonumber(args[2]) and tonumber(args[2]) > 0 and #args >= 5 and #args <= 23 then
	  canstart = nil
	  for role in message.guild:getMember(message.author.id).roles do
	    if role.permissions:has('manageMessages') then
	      canstart = true
		  break
	    end
	  end
	  if canstart then
	    local str = ''
		local options = {}
	    for i = 4,#args do
	      str = str..(emojilist[i-3])..': '..args[i]..' '
		  options[i-3] = args[i]
	    end
	    message = message.channel:sendMessage('"'..args[3]..'" options are:\n'..str)
	    for i = 1,#args-3 do
	      message:addReaction(emojilist[i])
	    end
		local votelist = json.parse(fs.readFileSync("vote.config") or '[]') or {}
		table.insert(votelist,{guild=message.guild.id,channel=message.channel.id,message=message.id,duration=os.time()+args[2],options=options})
		fs.writeFileSync("vote.config",json.stringify(votelist))
	  end
	end
  end
end)

local token = fs.readFileSync('vote.token')
client:run(token)