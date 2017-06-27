local discordia = require('discordia')
local fs = require('fs')
local json = require('json')
local client = discordia.Client()
local timer = require('timer')
local config = json.parse(fs.readFileSync("greg.config"))

for i in pairs(config.pools) do
	config.pools[i].num = 0
	for j=1,#config.pools[i]-1 do
		config.pools[i].num = config.pools[i].num + config.pools[i][j].weight
		config.pools[i][j].max = config.pools[i].num
	end
end

for i=1,#config.triggers.random do
	config.triggers.random[i].nexttime = os.time() + math.random(config.triggers.random[i].time[1],config.triggers.random[i].time[2])
end

local function randomtext(tab)
	rand = math.random(1,tab.num)
	for i=1,#tab-1 do
		if rand <= tab[i].max then
			return tab[i].text
		end
	end
end

local function sendMessage(sendmessage,channel)
	channel:broadcastTyping()
	timer.sleep(#sendmessage*50)
	channel:sendMessage(sendmessage)
end

local function pool(pool)
	pool = string.sub(pool,7,-1)
	if pool then
		for i=1,#pools[pool] do
			str = (str or "")..'"'..pools[pool][i].text..'": '..(pools[pool][i].weight/pools[pool].num*100).."%\n"
		end
	else
		str = "The pool "..pool.." does not exist."
	end
	return str
end
client:on('ready', function()
	print("bot connected to discord with id "..client.user.id)
end)

client:on('heartbeat', function()
	for i=1,#config.triggers.random do
		if config.triggers.random[i].nexttime <= os.time() then
			local channel = client:getGuild(config.triggers.random[i].guild):getChannel('name',config.triggers.random[i].channelname)
			local pool = config.pools[config.triggers.random[i].pools]
			sendMessage(randomtext(pool),channel)
			config.triggers.random[i].nexttime = os.time() + math.random(config.triggers.random[i].time[1],config.triggers.random[i].time[2])
		end
	end
end)

client:on('messageCreate', function(message)
	if not message.author.bot then
		mentions = nil
		if message.mentionedUsers() then
		for i=1,#config.triggers.mentions do
			mention = false
			for j=1,#config.triggers.mentions[i].mentioned do
				if string.lower(config.triggers.mentions[i].mentioned[j]) == "self" and message:mentionsObject(client.user) then
					mention = true
					break
				elseif string.lower(config.triggers.mentions[i].mentioned[j]) ~= "self" then
					local function getuser(member)
						local user = config.triggers.mentions[i].mentioned[j]
						return member.username == string.sub(user,1,-6) and member.discriminator == string.sub(user,-4)
					end
					getuser(message.member)
					if message.guild:findMember(getuser) and message:mentionsObject(message.guild:findMember(getuser)) then
						mention = true
						break
					end
				end
			end
			local channel = nil
			if mention then
				for k=1,#config.triggers.mentions[i].channelnames do
					if message.channel.name == config.triggers.mentions[i].channelnames[k] then
						channel = true
						break
					end
				end
			end
			if channel then
				mentions = true
				local pool = config.pools[config.triggers.mentions[i].pools]
				sendMessage(randomtext(pool),message.channel)
			end
		end
		end
		if not mentions then
		for i=1,#config.triggers.newMessage do
			trigger = true
			if config.triggers.newMessage[i].guilds then
				local guild = false
				for j=1,#config.triggers.newMessage[i].guilds do
					if message.guild.id == config.triggers.newMessage[i].guilds[j] then
						guild = true
						break
					end
				end
				if not guild then
					trigger = false
				end
			end
			if config.triggers.newMessage[i].channelnames and trigger then
				local channel = false
				for j=1,#config.triggers.newMessage[i].channelnames do
					if message.channel.name == config.triggers.newMessage[i].channelnames[j] then
						channel = true
						break
					end
				end
				if not channel then
					trigger = false
				end
			end
			if config.triggers.newMessage[i].messages and trigger then
				local messagetest = false
				for j=1,#config.triggers.newMessage[i].messages do
					if string.find(message.content,config.triggers.newMessage[i].messages[j]) then
						messagetest = true
						break
					end
				end
				if not messagetest then
					trigger = false
				end
			end
			if trigger then
				if config.triggers.newMessage[i].pools then
					pool = config.pools[config.triggers.newMessage[i].pools]
					sendMessage(randomtext(pool),message.channel)
				end
				break
			end
		end
	end
	end
end)

local token = fs.readFileSync('greg.token')
client:run(token)