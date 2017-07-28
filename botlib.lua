local botlib = {}

function botlib.tabtostr(tab,s,e)
  local str = ''
  for i = (s or 1),(e or #tab) do
	str = str..tab[i]..' '
  end
  return string.sub(str,1,-2)
end

function botlib.command(message)
  local args = {}
  local i = 0
  if message then
	while #message > 0 do
	  i = i + 1
	  if string.match(message,'^%s+') then
	    _,j = string.find(message,'^%s+')
	  elseif string.match(message,'^[\'"]') then
		if string.match(message, "^%b''") then
		  args[i] = string.sub(string.match(message, "^%b''"),2,-2)
		  _,j = string.find(message,"^%b''")
		elseif string.match(message, '^%b""') then
		  args[i] = string.sub(string.match(message, '^%b""'),2,-2)
		  _,j = string.find(message,'^%b""')
		else
		  i = math.max(i -1,1)
		  args[i] = (args[i] or '')..string.match(message, "[^%s]+")
		  _,j = string.find(message,"[^%s]+")
		end
	  else
		args[i] = string.match(message, "[^%s\"']+")
		_,j = string.find(message,"[^%s\"']+")
	  end
	  message = string.sub(message,j+1)
	  if not args[i] then
		i = i - 1
	  end
    end
  end
  return args
end

function botlib.time(str)
  local d = tonumber(string.sub(string.match(str,'%d+d') or '',1,-2))
  local h = tonumber(string.sub(string.match(str,'%d+h') or '',1,-2))
  local m = tonumber(string.sub(string.match(str,'%d+m') or '',1,-2))
  local s = tonumber(string.sub(string.match(str,'%d+s') or '',1,-2))
  local time = (s or 0) + (m or 0) * 60 + (h or 0) * 3600 + (d or 0) * 86400
  local d = math.floor(time/86400)
  local distime = time - d * 86400
  local h = math.floor(distime/3600)
  local distime = distime - h * 3600
  local m = math.floor(distime/60)
  local distime = distime - m * 60
  return time,string.sub((d > 0 and d..'d ' or '')..(h > 0 and h..'h ' or '')..(m > 0 and m..'m ' or '')..(distime > 0 and distime..'s ' or ''),1,-2)
end

return botlib