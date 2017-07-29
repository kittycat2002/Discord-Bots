local botlib = require('botlib')
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
	  client:getGuild(votelist[i].guild):getChannel(votelist[i].channel):sendMessage('"'..winner..'" won the vote of "'..votelist[i].vote..'"')
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
	local args = botlib.command(message.content)
	if args[1] == '!vote' and tonumber(args[2]) and tonumber(args[2]) >= 2 and tonumber(args[2]) <= 20 and #args >= tonumber(args[2]) + 4 then
	  canstart = nil
	  for role in message.guild:getMember(message.author.id).roles do
	    if role.permissions:has('manageMessages') then
	      canstart = true
		  break
	    end
	  end
	  if canstart then
	    local time,display = botlib.time(botlib.tabtostr(args,3,#args-tonumber(args[2])-1))
		if time > 0 then
	      local str = ''
		  local options = {}
	      for i = #args-tonumber(args[2])+1,#args do
	        str = str..(emojilist[#options+1])..': '..args[i]..' '
		    options[#options+1] = args[i]
	      end
	      local newmessage = message.channel:sendMessage('"'..args[#args-tonumber(args[2])]..'" with a time limit of "'..display..'" options are:\n'..str) or false
		  if newmessage then
	        for i = 1,#options do
	          newmessage:addReaction(emojilist[i])
	        end
		    local votelist = json.parse(fs.readFileSync("vote.config") or '[]') or {}
		    table.insert(votelist,{guild=newmessage.guild.id,channel=newmessage.channel.id,message=newmessage.id,duration=os.time()+time,options=options,vote=args[#args-tonumber(args[2])]})
		    fs.writeFileSync("vote.config",json.stringify(votelist))
		  else
		    message.channel:sendMessage('Warning, failed to create message.')
		  end
		end
	  end
	end
  end
end)

local token = fs.readFileSync('vote.token')
client:run(token)