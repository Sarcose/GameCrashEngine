
--[[=========================================================================]]
--[[=========================================================================]]
--[[===========___=========================___==============_================]]
--[[========  / _ \__ _ _ __ ___   ___    / __\ __ __ _ ___| |__=============]]
--[[======== / /_\/ _` | '_ ` _ \ / _ \  / / | '__/ _` / __| '_ \ ===========]]
--[[========/ /_\\ (_| | | | | | |  __/ / /__| | | (_| \__ \ | | |===========]]
--[[========\____/\__,_|_| |_| |_|\___| \____/_|  \__,_|___/_| |_|===========]]
--[[=========================================================================]]
--[[=========================================================================]]
-- core utilities lib for Game Crash
-- last update: 01/07/2025
-- requires debugcandy.lua
-- all versions used in Game Crash games export 
--		debugcandy into the _c_ global pseudonamespace

--[[-------------------------------------------------------------------------]]
--[[      Table of Contents---#CONTENTS--------------------------------------]]
--[[      #DEBUG-------------------------------------------------------------]]
--[[      #SAFE--------------------------------------------------------------]]
--[[      #ACTOR-------------------------------------------------------------]]
--[[      #COMPARISON--------------------------------------------------------]]
--[[      #TYPES-------------------------------------------------------------]]
--[[	  #CONTAINER---------------------------------------------------------]]
--[[      #STATE-------------------------------------------------------------]]
--[[      #MATHS-------------------------------------------------------------]]
--[[      #COLOR-------------------------------------------------------------]]
--[[      #VARIABLE----------------------------------------------------------]]
--[[	  #TABLE-------------------------------------------------------------]]
--[[      #GRAPHICS----------------------------------------------------------]]
--[[      #FILE--------------------------------------------------------------]]
--[[      #EXPANSIONS--------------------------------------------------------]]
--[[      #RUNCODE-----------------------------------------------------------]]
--[[      #OVERLOADS---------------------------------------------------------]]
--[[-------------------------------------------------------------------------]]




require 'core.debugcandy_hinting'
require ('core.debugcandy'):export()

--Intended use: local rsign = gcore.var.rsign
--Or just call gcore.var.rsign directly
--This way we can call all our utility functions with intellisense if possible

--also local var = gcore.var | var.rsign()

_G._CANDEBUG = false
_G._ALLOBJECTS = {}


local g = {
	config = {
		deepcopylimit = 3,
	}

}
--[[Debug     #DEBUG]]
g.debug = {dims = {x=0,y=0,r=0, sx=1,sy=1}, container = {strings = {}}}
function g.debug.toggle()
	_G._Debugging = gcore.var.boolSwitch(_G._Debugging)
	_c_message("gcore debug mode "..tostring(_G._Debugging),"warn")
end

local debugfgcolors = {
	black = "\x1b[30m",			white = "\x1b[37m",
	red = "\x1B[31m", 			green = "\x1B[32m", 	
	yellow = "\x1b[33m", 		blue = "\x1b[94m",
	magenta = "\x1b[35m",		cyan = "\x1b[36m",	
	reset = "\x1B[m"}		
local debugbgcolors = {
	white = "\x1b[47m",				black = "\x1b[40m",
	red = "\x1b[41m",				yellow = "\x1b[43m",	   		
	green = "\x1b[42m",				blue = "\x1b[44m",
	magenta = "\x1b[45m",			cyan = 	"\x1b[46m"	}

--- black, red, yellow, magenta, white, green , blue, cyan or "reset". Blank also resets.
function g.debug.getColor(fg,bg)
	fg = debugfgcolors[fg] or debugfgcolors.reset
	bg = debugbgcolors[bg] or ""
	return fg..bg
end


function g.debug:createCanvas()
	self.canvas = lg.newCanvas(lg.getWidth(),lg.getHeight())
end
local locationTypeDefaults = {0,0,0,0,0}
function g.debug.locationType(loc)
	if type(loc) ~= "table" then loc = {} end
	for i=1, #locationTypeDefaults do
		loc[i] = loc[i] or locationTypeDefaults[i]
	end
	return loc
end
function g.debug:strPair(str,loc)
	return {tostring(str),self.locationType(loc)}
end
function g.debug:push()
	self.formerCanvas = lg.getCanvas()
	lg.setCanvas(self.canvas)
	lg.clear()
end
function g.debug:pop()
	lg.setCanvas(self.formerCanvas)
end
function g.debug:drawContainer(x,y,r,sx,sy)
	x,y,r,sx,sy = x or 0, y or 0, r or 0, sx or 1, sy or 1
	local strings = self.container.strings
	local strpair, str, loc, f
	for k,v in pairs(strings) do
		self:setFont()
		strpair = v
		if type(strpair) == "string" then
			strpair = {v, {0,0}}
		end
		str, loc, f = strpair[1], self.locationType(strpair[2]), strpair[3]
		if f then
			self:setFont(f)
		end
		lg.print(str, x+loc[1],y+loc[2],r+loc[3],sx+loc[4],sy+loc[5])
	end
	self:releaseFont()
end
function g.debug:setFont(f)
	local font_to_set
	if f then
		if type(f) ~= "number" or f < 1 or f > #self.fonts then
			_c_warn("Warning: gcore.debug.setFont() called with improper font size of "..tostring(f).." where max is "..tostring(#self.fonts).."! Font will not be changed.")
			return
		end
		font_to_set = self.fonts[f]
	else
		self.formerFont = lg.getFont()
		font_to_set = self.fonts[self.fontsize]
	end
	if self.formerFont ~= font_to_set or lg.getFont() ~= font_to_set then lg.setFont(font_to_set) end
end
function g.debug:releaseFont()
	if self.formerfont then lg.setFont(self.formerfont) end
	self.formerfont = nil
end
function g.debug:loadFonts(startsize)
	local startsize, sizes, increment = startsize or 10,10,2
	local fonts = {}
	for i=1, sizes do
		fonts[#fonts+1] = lg.newFont(startsize+i*increment)
	end
	self.fonts = fonts
	self.fontsize = 1
	self.fontmax = sizes
	self.changeFontSize = function(self, inc)
		if type(inc) == "number" then
			if inc > 1 and inc < self.fontmax then
				self.fontsize = inc
			else
				_c_warn("gcore.debug.changeFontSize called with improper fontsize "..tostring(inc).." where min is 1 and max is "..tostring(self.debug.fontmax).."!")
			end

		elseif inc then
			self.fontsize = self.fontsize + 1
			if self.fontsize > self.fontmax then self.fontsize = self.fontmax end
		else	--
			self.fontsize = self.fontsize - 1
			if self.fontsize < 1 then self.fontsize = 1 end
		end
	end

end
function g.debug.guitableprint(t, name, x, y, font, color, tab, offset,depth)
	setparams = false
	if tab == nil then setparams = true tab = "" end
	name = name or "table"
	x = x or 100
	y = y or 100
	font = font or TestFont
	color = color or {1,1,1,1}
	tab = tab or ""
	offset = offset or 0
	depth = depth or 3
	if setparams then
		lg.setColor(color)
		lg.setFont(font)
	end
	lg.print(tostring(tab)..tostring(name).." = {",x,y+offset)
	if depth > 0 then
		for i,v in pairs(t) do
			offset = offset + font:getHeight("W")
			if type(v) == "table" then
				g.debug.guitableprint(t[i], i, x, y, font, color, tostring(tab).."  ",offset,depth-1)
			else
				lg.print(tostring(tab).."    "..tostring(i).."= "..tostring(v),x+100,y+offset)
			end
		end
	end
	lg.print(tostring(tab).."		   ".."}")
end
function g.debug.guitableprint_shallow(t, name, x, y, font, color, offset)
	if type(t) ~= 'table' then return end
	name = name or "table"
	x = x or 100
	y = y or 100
	font = font or 'defaultfont'
	color = color or {1,1,1,1}
	offset = offset or 0
	lg.print(tostring(name).." = {",x,y+offset)
	for i,v in pairs(t) do
		offset = offset + _G.fonts[font]:getHeight("W")+4
		lg.print("    "..tostring(i).."= "..tostring(v),x,y+offset)
	end
	lg.print("		   }",x,y+offset + _G.fonts[font]:getHeight("W")+4)
end
function g.debug.guitableprint_vectors(t,name,x,y,font,color,offset)
	assert(type(t) == 'table','ERROR! type passed to guitableprint_vectors is not a table, item is: '..tostring(t))
	assert(type(t[1]) == 'table','ERROR! Type of table passed to guitabelprint_vectors is not a nested table, first index is '..tostring(t[1]))
	assert(#t[1] >= 2 or (t[1].x and t[1].y), 'ERROR! Nested table passed to guitabelprint_vectors is not a complete vector table. First index of first entry is '
		..tostring(t[1][1])..
		'and x/y keys are: '..
		tostring(t[1].x)..', '..tostring(t[1].y))

	name = name or "table"
	x = x or 100
	y = y or 100
	font = font or 'defaultfont_s'
	color = color or {1,1,1,1}
	lg.setColor(color)
	lg.setFont(_G.fonts[font])
	offset = offset or 0
	local step = _G.fonts[font]:getHeight("W")+4
	lg.print(tostring(name).." = {",x,y+offset)
	offset = offset + step
	if t[1].x then --display as a key/value vector
		for i=1,#t do
			lg.print('(x: '..tostring(roundFloat(t[i].x, 3))..', y: '..tostring(roundFloat(t[i].y,3))..')',x,y+offset)
			offset = offset + step
		end
	else	--display as an indiced vector, adding x/y labels
		for i=1,#t do
			lg.print('(x: '..tostring(roundFloat(t[i][1], 3))..', y: '..tostring(roundFloat(t[i][2],3))..')',x,y+offset)
			offset = offset + step
		end
	end

end
function g.debug.guiprint(p,x,y,font,color)
	p=p or 'nil'
	x=x or 0
	y=y or 0
	font = font or 'defaultfont_s'
	color = color or {1,1,1,1}
	lg.setColor(color)
	lg.setFont(_G.fonts[font])
	lg.print(p,x,y)
end
function g.debug.horizontaltableprint(t,x,y,font,color,limit)
	local setparams = false
	if font == nil then setparams = true end    
    x = x or 40
	y = y or 100
	font = font or 'defaultfont_s'
	color = color or {1,1,1,1}
    limit = limit or 10
    local printstring = " "
	for i,v in pairs(t) do
        if limit < 0 then break end
        printstring = printstring..tostring(i).."="..tostring(v)..", "
        limit = limit - 1
    end
	printstring = printstring.."}"
    lg.print(printstring,x,y)
    if setparams then
		lg.setColor(color)
		lg.setFont(_G.fonts[font])
	end
end
function g.debug.displayInputs(t, name, x, y, font, color, offset)
	local setparams = false
	name = name or "table"
	x = x or 40
	y = y or 100
	font = font or 'defaultfont_s'
	color = color or {1,1,1,1}
	tab = tab or ""
	offset = offset or 0
	depth = depth or 3
	if setparams then
		lg.setColor(color)
		lg.setFont(_G.fonts[font])
	end
	lg.print("inputs = {",x,y+offset)
	for i,v in pairs(t) do
		offset = offset + _G.fonts[font]:getHeight("W")
		if type(v) == "table" then
			lg.print(tostring(tab).."  "..tostring(i).."= {",x+20,y+offset)
			local width = _G.fonts[font]:getWidth(tostring(tab).."  "..tostring(i).."= ")
			horizontaltableprint(t[i], x+10+width, y+offset,font,color)
		else
			lg.print(tostring(tab).."    "..tostring(i).."= "..tostring(v),x+20,y+offset)
		end
	end
	lg.print("}",x,y+offset)
end
function g.debug.tablePrint_asString(t, name, tbls)
	local s = name or ""
	local tbls = tbls or {}
	for i = 1, #t do
		if type(t[i]) == "table" and not tbls[tostring(t[i])] then
			tbls[tostring(t[i])] = true
			s = s .."["..tostring(i).."]={"..g.debug.tablePrint_asString(t[i],nil,tbls).."}"
		elseif type(t[i]) == "table" then
			s = s.." "..tostring(t[i])
		else
			s = s .."["..tostring(i).."]="..tostring(t[i])
		end
	end
	for k,v in pairs(t) do
		if type(k) == "string" then
			if type(t[k]) ~= "function" and k[1]~= "_" and k ~="super" then
				if type(t[k]) == "table" and not tbls[tostring(t[k])] then
					tbls[tostring(t[k])] = true
					s = s .."["..tostring(k).."]={"..g.debug.tablePrint_asString(t[k],nil,tbls).."}"
				elseif type(t[k]) == "table" then
					s = s.." "..tostring(t[k])
				else
					s = s .."["..tostring(k).."]="..tostring(t[k])
				end
			end
		end
	end
	return s
end
function g.debug.tablePrint_stringWithBreaks(t,name,tbls,xo)
	local f = lg.getFont()
	local w = f:getWidth("W")
	local s = name.."\r\n" or "Table\r\n"
	xo= xo or 0
	local tab = ""
	for i=1,xo do tab = tab.." " end
	tbls = tbls or {}
	for i=1, #t do
		s = s .. tab
		if type(t[i]) == "table" and not tbls[tostring(t[i])] then
			tbls[tostring(t[i])] = true
			s = s .."["..tostring(i).."]={"..g.debug.tablePrint_stringWithBreaks(t[i],nil,tbls,xo+w).."}"
		elseif type(t[i]) == "table" then
			s = s.." "..tostring(t[i])
		else
			s = s .."["..tostring(i).."]="..tostring(t[i])
		end
		s = s.."\r\n"
	end
	for k,v in pairs(t) do
		if type(k)=="string" then
			if type(t[k]) ~="function" and k[1] ~= "_" and k ~="super" then
				s = s .. tab
				if type(t[k]) == "table" and not tbls[tostring(t[k])] then
					tbls[tostring(t[k])] = true
					s = s .."["..tostring(k).."]={"..g.debug.tablePrint_asString(t[k],nil,tbls,xo+w).."}"
				elseif type(t[k])=="table" then
					s = s.." "..tostring(t[k])
				else
					s=s.."["..tostring(k).."]="..tostring(t[k])
				end
				s = s.."\r\n"
			end
		end
		
	end
	return s
end
_c_todo{"04/22/2025","Write a universal argparser using the logic of local parseThoughtArgs","Write thought() so that it parses line number like debugcandy, instead of os.time()"}
local function parseThoughtArgs(item, argparse)
	argparse = argparse or {}
	if type(item,"table") then
		if #item > 0 then	--if thought{"first","second","third"}
			for i,v in ipairs(item) do
				argparse = parseThoughtArgs(v,argparse)
			end
		else	--if thought{index=0, message = "message", fn = func}
			argparse = item
		end
	else
		if type(item,"number") then
			argparse.index = item
		elseif type(item,"string") then
			if argparse.message then 
				argparse.comment = item
			else
				argparse.message = item
			end
		elseif type(item,"function") then
			argparse.fn = item
		elseif type(item,"boolean") then
			argparse.history = item
		end
	end
	return argparse
end
local index_colors = {	--cyclical coloration... more than five thoughts at once is excessive
		"\x1b[37m\x1b[44m", --White on Blue
		"\x1b[35m\x1b[42m", --Magenta on Green
		"\x1b[35m\x1b[43m", --Magenta on Yellow
		"\x1b[37m\x1b[41m", --White on Red
		"\x1b[37m\x1b[45m", --White on Magenta		
	}
local function newThought(fn,color,index,comment)
	return {
		prepend = index_colors[color],
		index = index,
		comment = comment or "no comment",
		fn = fn,
		history = {},
		display = function(self,message)
			local str = self.prepend..message
			local thoughtdisplay = tostring(#self.history+1).." at "..tostring(os.time())..": "..message
			table.insert(self.history,thoughtdisplay)
			self.fn(str)
		end,
		showHistory = function(self)
			local str = ""..self.prepend.."Displaying history of Thought: "..tostring(self.index).." Comment: "..tostring(self.comment)
			for i,v in ipairs(self.history) do
				str = str.."\r\n"..v
			end
			self.fn(str)
		end,
	}
end

local thoughts = {}

---@type fun(...: any)
---@param ... any Can be passed with thought{indices} or thought{int index, str message, function fn} or thought(index, message, fn) or any combination thereof
--- Creates a "thought" for debugging with -- a visually connected string of console prints for tracking a single issue through multiple iterations
--- If index is passed, calls that same thought, instead
--- returns the thought index. Also returns a function wrapper that can be called with fn(message) by itself to continually add to said thought.
--- at this time functions other than _c_message are technically not supported by the code, but it's left open for future improvements.
function g.debug.thought(...)
	--BUG: return callback doesn't work
	local args = {...}
	local parsed = parseThoughtArgs(args)
	local index, message, fn, comment, history = parsed.index, parsed.message, parsed.fn, parsed.comment,parsed.history
	index = index or #thoughts + 1
	message = message or "NO MESSAGE THOUGHT"
	
	local callback
	if not thoughts[index] then 
		fn = fn or _c_message	--fn is only used if thought is new. The point is distinction
		thoughts[index] = newThought(fn, g.var.getWrapped(index_colors, index),index,comment)
		callback = function(msg,history)
			local history = history or false
			if type(msg) == "boolean" then history = msg msg = nil end
			g.debug.thought{index=index, message=msg,history=history}
		end
	end

	local thought = thoughts[index]
	if history then
		thought:showHistory()
	else
		thought:display(message)
	end
	return index, callback
end

function g.debug.printHeader(text,line,color,bg)
	print(line)
	color = color or "yellow"
	line = line or "============================================================"
	local title_width = #line
	local third = title_width/3
	local char = string.sub(line,1,1)
	text = text or "Title"
	text = string.upper(text)
	text = string.gsub(text, "(.)", "%1 ")
	local len = #line
	local title_len = #text
	local total_padding = len - title_len
	if total_padding < 0 then total_padding = 0 end
	local left_padding = math.floor(total_padding / 2)
    local right_padding = total_padding - left_padding
    local titlestring = string.rep("=", left_padding) .. "  " .. text .. "  " .. string.rep("=", right_padding)
	if #titlestring > len then titlestring = string.sub(titlestring,#titlestring-len+1) end
	_c_printCBG(line,color,bg)
	_c_printCBG(line,color,bg)
	_c_printCBG(titlestring,color,bg)
	_c_printCBG(line,color,bg)
	_c_printCBG(line,color,bg)
	
end
function g.debug.printBreak(text)
	text = text or "============================================================"
	_c_printC("yellow",text)
end
function g.debug.loadingBar(value, start, goal, text)	--TODO: for now only use start/goal that divides evenly by 100
	text = text or "[.]"
	local open, tick, close = text.char(1), text.char(2),text.char(3)
	if value == start then
		io.write(open)
	elseif value == goal then
		io.write(close)
		return true
	else
		local period = (goal-start)/100
		if value % period == 0 then
			io.write(tick)
		end
	end
end

---@type fun(level?: integer, depth?: integer, parseStart?: integer)
---@return string
function g.debug.extractCallerInfo(level, depth, parseStart)
		if not _G._Debugging then return "UNKNOWN (debugging off)" end
		local stack = debug.traceback("", 2)
		local lines = {}
		for line in stack:gmatch("[^\n]+") do
			table.insert(lines, line)
		end
		local ret = ""
		level = level or 5
		depth = depth or 3		
		parseStart = parseStart or 4
		local lastFile = nil
		local currentRange = {}
		if level then
			for i = 1, level do
				local n = (i - 1) + parseStart
				local callerInfo = lines[n]
				if callerInfo then
					local file, line = callerInfo:match("([^:]+):(%d+)")
					if file and line then
						-- Handle the file path depth
						local pathParts = {}
						for part in file:gmatch("[^/\\]+") do
							table.insert(pathParts, part)
						end
						-- Adjust the file path based on the depth
						if depth > 0 then
							local startIdx = math.max(#pathParts - depth, 1)
							file = table.concat({unpack(pathParts, startIdx)}, "/")
						else
							file = pathParts[#pathParts]  -- Only the filename
						end
						file = string.gsub(file, "%s", "")  -- Remove spaces	--TODO: this might interfere with filenames that have spaces. Solution: don't use spaces imo
						file = string.gsub(file, "/", ".")  -- Replace '/' with '.'
						local num = tonumber(line)
						if lastFile == file then
							-- Add the line number to the current range
							table.insert(currentRange, num)
						else
							-- If there is a previous range, collapse it
							if #currentRange > 0 then
								if #currentRange > 1 then
									ret = ret .. "[" .. lastFile .. ":" .. table.concat(currentRange, ":") .. "]"
								else
									ret = ret .. "[" .. lastFile .. ":" .. currentRange[1] .. "]"
								end
							end
							-- Start a new range for the new file
							lastFile = file
							currentRange = {num}
						end
					end
				end
			end
	
			-- Handle the last range (if any)
			if #currentRange > 0 then
				if #currentRange > 1 then
					ret = ret .. "[" .. lastFile .. ":" .. table.concat(currentRange, ":") .. "]"
				else
					ret = ret .. "[" .. lastFile .. ":" .. currentRange[1] .. "]"
				end
			end
		end
		return ret
	end


_c_todo{"gcore safe todolist: ","get: use parseRef to grab an multiple indices"}
g.safe = {}
--[[Safety Functions #SAFE]]
function g.safe.call(f, ...)	
	if type(f)=="function" then
		return f(...)
	end
end
function g.safe.get(table, key, default)
	return type(table)=="table" and table[key] or default
end
function g.safe.release(object)
	if type(object,"table") then
		if object.unload then object:unload()
		elseif object.remove then object:remove()
		elseif object.release then object:release()
		end
	end
end
function g.safe.profile(func, ...)	--consider putting this into a more robust display
    local start = love.timer.getTime()
    local result = {func(...)}
    local duration = love.timer.getTime() - start
    _c_message(("Execution time: %.3f ms"):format(duration * 1000))
    return gcore.var.unpack(result)
end

g.actor = {}
--[[Actor Functions #ACTOR]]

function g.actor.distanceHorizontal(a,b)
	if a.x < b.x then
		return math.abs(a.x+(a.w/2) - b.x-(b.w/2))
	else
		return math.abs(a.x-(a.w/2) - b.x+(b.w/2))
	end
end

function g.actor.distanceVertical(a,b)
	if a.y < b.y then
		return math.abs(a.y+(a.h/2) - b.y-(b.h/2))
	else
		return math.abs(a.y-(a.h/2) - b.y+(b.h/2))
	end
end

g.comparison = {}

--[[Comparison      #COMPARISON]]   --check batteries for a lot of these
function g.comparison.bigger(a,b)
	return (a > b) and a or b or 0
end
function g.comparison.smaller(a,b)
	return (a < b) and a or b or 0
end
function g.comparison.compareFloat(a,b)
	--print('comparing '..tostring(a)..' to '..tostring(b))
	return (tostring(a)==tostring(b))
end
function g.comparison.getClosestNumber(n,t) --a table of numbers arranged in numeric order
	for i=1,#t-1 do
		if n <= t[i] then return t[i]
		elseif n <= (t[i+1]-t[i])/2 then return t[i]
		elseif n >= (t[i+1]-t[i])/2 and n <= t[i+1] then return t[i+1]
		end
		if i == #t-1 then return t[#t] end
	end
end
function g.comparison.shuffle(t)
	local tbl = {}
	for i = 1, #t do
	  tbl[i] = t[i]
	end
	for i = #tbl, 2, -1 do
	  local j = math.random(i)
	  tbl[i], tbl[j] = tbl[j], tbl[i]
	end
	return tbl
end
function g.comparison.clamp(n,clampmin,clampmax)
	if n > clampmax then return clampmax elseif n < clampmin then return clampmin else return n end
end
function g.comparison.getSign(x)
	if x >= 0 then return 1 else return -1 end
end
function g.comparison.notZero(x,y)
	if math.abs(x)>=y then return x else return y end
end
function g.comparison.orZero(n)
	if n<0 then return 0 else return n end
end


--[[types	  #TYPES]]
--only for extension enums. add any new entries to gcoreTypeList down below under #REGISTERLIST using local t
---@alias gcoreType
---| '"Global"'       # Global namespaces only, not related to global primitives.
---| '"System"'       # A System from data.systems.
---| '"GameState"'    # GameStates which include title screen and such.
---| '"Overlay"'      # All UI systems are this type.
---| '"Controller"'   # A controller, to be attached to an entity and menu before it works.
---| '"Space"'        # Relational containers for entities. Where the game takes place.
---| '"Entity"'		  # Basic class for Terrain, Item, Actor
---| '"Template"'	  # Basic class for Terrain, Item, Actor
---| '"MemContainer"' # Containerized instance for instantiating objects. All loaded scopes should start here
--- #REGISTERLIST
local gcoreTypeList = {"Global","System","GameState","Overlay","Controller","Space","Entity","Template","MemContainer"}

--I THINK this is it. I MIGHT also use a new alias for gcoreSubType -- the purpose being,
								--the types above are prototypes, and i don't want the subtypes to be in the same alias.


g.container = {__registry = {}}
--[[container		#CONTAINER]]
_c_todo{"DebugCandy needs to be able to look for my custom __type system and respond accordingly, as it still often uses type() normally and expects a string, it will error when it fails to get this."}


function g.container.registerType(t) --TODO: more typing functions as needed?
	g.container.__registry[t] = true
end

function g.container.registerTypes(t)
	for i=1,#t do g.container.registerType(t[i]) end
end
g.container.registerTypes(gcoreTypeList)


---@type fun(cls: table, t: gcoreType)
---@param cls table
---@param t gcoreType
---@param name? string
function g.container.assignType(cls,t,name)
    assert(type(cls,"table"),"\r\n|gcore message| assignType called without table! Only assign types in this way to tables, primitive types don't need this. cls: "..tostring(cls))
	assert(g.container.__registry[t], "\r\n|gcore message| assignType called to assign invalid type of "..tostring(t).." which is not in gcore.container.__registry. type string passed MUST be a gcoreType extension!")
	local _t = {}
	_t.__primitive = "table"
	_t.__type = t
	_t.__address = string.format("%p",cls)
	_t.__name = name or cls.name or "Unnamed".."_"..tostring(_t.__address)
	_t.__assigned = "assigned at "..tostring(g.debug.extractCallerInfo()) 
		--eventually we will want to be parsing the exact moment when a type is assigned, using a debug flag (parsing this will eat up CPU),
		--in order to track down assignments that are somehow messed up, in the files themselves.
	cls.__type = _t
end
local anonymous_counter = 0

---@type fun(cls: table)
---@param cls table
---Used for anonymous referencing between backend functions, such as referencing one's own canvas within Push
function g.container.assignAnonymousType(cls)
    assert(type(cls,"table"),"\r\n|gcore message| assignType called without table! Only assign types in this way to tables, primitive types don't need this. cls: "..tostring(cls))
	anonymous_counter = anonymous_counter + 1
	local _t = {}
	_t.__primitive = "table"
	_t.__type = "ANONYMOUS"
	_t.__address = string.format("%p",cls)
	_t.__name = "ANON_"..tostring(_t.__address).."_"..tostring(anonymous_counter)
	_t.__assigned = "assigned at "..tostring(g.debug.extractCallerInfo()) 
		--eventually we will want to be parsing the exact moment when a type is assigned, using a debug flag (parsing this will eat up CPU),
		--in order to track down assignments that are somehow messed up, in the files themselves.
	cls.__type = _t
end
g.state = {}
--[[state           #STATE]]
local function addMethods(a)
	function a.load () end
	function a.update(dt) end
	function a.draw() end


end

-- TODO	--I don't seem to be using this state library interestingly...
function g.state.new_engine(...)  
    local args = {...}
    local c = {}
    local prefix = "_Engine"
    for i, v in ipairs(args) do
        if type(v) == "table" then
            c = v
        elseif type(v) == "string" then
            prefix = v
        end
    end



end








g.math = {}
--[[Maths           #MATHS]]        --check batteries for a lot of these
function g.math.ccw(A,B,C)
    return (C.y-A.y) * (B.x-A.x) > (B.y-A.y) * (C.x-A.x)
end
function g.math.lineIntersect(Ax,Ay,Bx,By,Cx,Cy,Dx,Dy)
	return intersect2{
						A = {x = Ax, y = Ay},
						B = {x = Bx, y = By},
						C = {x = Cx, y = Cy},
						D = {x = Dx, y = Dy},}
end
function g.math.intersect2(A,B,C,D)
    return ccw(A,C,D) ~= ccw(B,C,D) and ccw(A,B,C) ~= ccw(A,B,D)
end


function g.math.dist(x1,y1,x2,y2)
	return math.sqrt((x1-x2)^2+(y1-y2)^2)
end

function g.math.distanceBetweenObjects(a,b)    --assuming the objects have w,h,x,y values
	return dist(a.x+a.w/2,a.y+a.h/2,b.x+b.w/2,b.y+b.h/2)
end

function g.math.speedByVector(x1,y1,x2,y2)
	local xspeed = (x1-x2)
	local yspeed = (y1-y2)
	
	return xspeed, yspeed
end
function g.math.randomRadian(r1, r2)   -- TODO: what is this function for?
	r1 = r1 or 0
	r2 = r2 or 315
	return rand(r1,r2)
end
function g.math.roundFloat(n,dec)
	return roundfloat(n,dec)
end
function g.math.roundfloat(n,dec)
	return math.floor(n*10^dec)/10^dec

end
function g.math.round(n, mult)
    mult = mult or 1
    return math.floor((n + mult/2)/mult) * mult
end
function g.math.timeToRads(hour)	--decimal hour
	return math.rad((hour-18)*15)	-- hour-18 *should* put 0 at 6AM~ish
end
function g.math.decimalToTime(decTime)
	local hr = math.floor(decTime)
	local min = (decTime - hr)*60
	return hr,min
end
function g.math.decimalToTimeString(decTime)	--we'll do seconds another time
	local hr,min = decimalToTime(decTime)
	if min < 9 then min = '0'..tostring(math.floor(min))
	else min = tostring(math.floor(min)) end
	return tostring(hr)..':'..min
end
function g.math.convertToTimeNotation(sec) --a number in seconds
	sec = round(sec, 2) --round to a number of seconds + .00
	local m = math.floor(sec / 60) --we have the total minutes
	local h = math.floor(m / 60) --we have the final hours
	local s = sec - (m * 60) --we have the final seconds.milli
	m = m - (h * 60) --we have the final minutes
	
	local sh, sm, ss
	
	if h < 10 then
		sh = "0"..tostring(h)
	else
		sh = tostring(h)
	end
	
	if m < 10 then
		sm = "0"..tostring(m)
	else
		sm = tostring(m)
	end
	
	if s < 10 then
		ss = "0"..tostring(s)
	else
		ss = tostring(s)
	end
	
	local s = sh..":"..sm..":"..ss
	
	return s
end
function g.math.stepToTarget(x1,y1,x2,y2,speed,dt)
	dt = dt or 1
	local dx,dy = x2-x1,y2-y1
	local dist = math.sqrt(dx*dx + dy*dy)
	local step = speed*dt
	if dist <= step then
		return x2,y2
	else
		local nx = dx/dist
		local ny = dy/dist
		return x1+nx*step,y1+ny*step
	end
end
function g.math.moveByVector(x,y,xv,yv,dist)
	return stepToTarget(x,y,x+xv*dist,y+yv*dist,dist)
end
function g.math.angleByPoints(x1,y1,x2,y2)
	return math.atan2(y2-y1, x2-x1)
end
function g.math.invertAngle(angle) 
	return (angle + math.pi) % (2 * math.pi)
end
function g.math.angleRadians(x1,y1,x2,y2)
	return math.atan2(y2 - y1, x2 - x1) * math.pi/180
end
function g.math.degToRad(deg)
	return deg*(math.pi/180)
end
function g.math.angleFromVector(x,y)
	return math.atan2(y,x)
end
function g.math.vectorFromAngle(a)
	return math.cos(a),math.sin(a)
end
local _angleDirections = {
	[-1] = {
		[-1] =225,
		[0] =180,
		[1] =135,
	},
	[0] = {
		[-1] =270,
		[0] =0,
		[1] =90,
	},
	[1] = {
		[-1] = 315,
		[0] =0,
		[1] =45,
	}

}
function g.math.angleByDirections(dir,vert,facingdir)
	assert(dir,'dir passed is '..tostring(dir))
	assert(vert,'vert passed is '..tostring(vert))
	if facingdir ~= 0 then facingdir = getsign(facingdir) end
	if dir == 0 and vert == 0 then
		assert(_angleDirections[facingdir],'facingdir == '..tostring(facingdir))
		assert(_angleDirections[facingdir][vert],'vert == '..tostring(vert))
		return _angleDirections[facingdir][vert]
	else	return _angleDirections[dir][vert]	
	end
end

function g.math.third(value,max)	--
	local first,second = max/3,max/3*2
	if value <= first then return 1
	elseif value <= second then return 2
	else return 3 end
end
function g.math.getPercent(value,max)
	return value/max*100
end
local sin,cos = math.sin,math.cos
local pi = math.pi
function g.math.sineMove(time, angle, amplitude, waveLen)
    return
		cos(angle) * time * waveLen + ((amplitude / 2) * sin(time) * sin(angle)), 
    	sin(angle) * time * waveLen - ((amplitude / 2) * sin(time) * cos(angle))
end
function g.math.sineVector(x,y,oX,oY,offset,time,angle,amplitude,wavelen)
	local vectorX,vectorY = vectorFromAngle(angle)
    local sinX,sinY = sineMove(time,angle,amplitude,wavelen)
    local goalX,goalY = oX+sinX-(offset*vectorX),oY+sinY-(offset*vectorY)
	return goalX-x,goalY-y
end
g.color = {}

--[[Colors          #COLOR]]    -- this *probably* can be achieved by batteries
function g.color.darkenColor(o,ratio)
	local r = {}
	ratio = ratio or 0.5
	r[1] = o[1]*ratio
	r[2] = o[1]*ratio
	r[3] = o[1]*ratio
	return r
end
function g.color.reverseColor(o)
	local r = {}
	r[1] = 0.5 + (0.5 - o[1])
	r[2] = 0.5 + (0.5 - o[2])
	r[3] = 0.5 + (0.5 - o[3])
	return r
end

function g.color.rgbMult(color,mult)
	return {color[1]*mult,color[2]*mult,color[3]*mult}
end

function g.color.lumenMultiply(color,mult,clamp)
    local c = {}
    local ret = {}
    c[1],c[2],c[3] = colour.rgb_to_hsl(color[1],color[2],color[3])

    c[3] = c[3] * mult
	if clamp then
		if clamp.min and c[3] < clamp.min then
			c[3] = clamp.min
		elseif clamp.max and c[3] > clamp.max then
			c[3] = clamp.max
		end
	end
    ret[1],ret[2],ret[3] = colour.hsl_to_rgb(c[1],c[2],c[3])
    return ret
end
function g.color.raw2color(r, g, b, a)
	if type(r) == 'table' then
		r, g, b, a = unpack(r)
	end
	return r / 255, g / 255, b / 255, a and a / 255
end
function g.color.lumenSet(color,amount,clamp)
	local c = {}
    local ret = {}
    c[1],c[2],c[3] = colour.rgb_to_hsl(color[1],color[2],color[3])

    c[3] = amount
	if clamp then
		if clamp.min and c[3] < clamp.min then
			c[3] = clamp.min
		elseif clamp.max and c[3] > clamp.max then
			c[3] = clamp.max
		end
	end
    ret[1],ret[2],ret[3] = colour.hsl_to_rgb(c[1],c[2],c[3])
    return ret
end


function g.color.hsvToRgb(h, s, v)
    local r, g, b

    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)

    i = i % 6
    if i == 0 then r, g, b = v, t, p
    elseif i == 1 then r, g, b = q, v, p
    elseif i == 2 then r, g, b = p, v, t
    elseif i == 3 then r, g, b = p, q, v
    elseif i == 4 then r, g, b = t, p, v
    elseif i == 5 then r, g, b = v, p, q
    end

    return r, g, b
end
function g.color.rgbToHsv(r, g, b)
    local max = math.max(r, g, b)
    local min = math.min(r, g, b)
    local delta = max - min

    -- Calculate Hue
    local h
    if delta == 0 then
        h = 0
    elseif max == r then
        h = (g - b) / delta % 6
    elseif max == g then
        h = (b - r) / delta + 2
    elseif max == b then
        h = (r - g) / delta + 4
    end
    h = h / 6

    -- Calculate Saturation
    local s = (max == 0) and 0 or (delta / max)

    -- Value (Brightness)
    local v = max

    return h, s, v
end
function g.color.hsvGlow(h, s, minV, maxV, speed, time)
    local v = minV + (maxV - minV) * (0.5 * (1 + math.sin(time * speed)))
    return hsvToRgb(h, s, v)
end
--local r, g, b = glow(h, s, minV, maxV, speed, love.timer.getTime())
function g.color.hsvGlowByGlobalTimer(color,minV,maxV,speed)
	local r,g,b = color[1],color[2],color[3]
	local h,s,v = rgbToHsv(r,g,b)
	return hsvGlow(h,s,minV,maxV,speed,love.timer.getTime())
end

function g.color.rgbHSLmod(r,g,b,nh,ns,nl)
	local h,s,l = rgbToHsl(r,g,b)
	return hslToRgb(h+nh,s+ns,l+nl)
end

--[[Variables          #VARIABLE]]    -- to deal with variable manipulation. Because so many variables are tables, it includes tables.

g.var = {}

function g.var.rsign()
	return math.random(0,1)*2-1
end
function g.var.boolSwitch(v)
	if v then return false else return true end
end
function g.var.getsign(v)
	if v >= 0 then return 1 else return -1 end
end
function g.var.getsignzero(v)
	if v > 0 then return 1 elseif v == 0 then return 0 else return -1 end
end
function g.var.randomPick(t)	--random{1,2,3,4,5}
	return t[math.random(1,#t)]
end
--parses a reference table to an object. A reference table is something like {"objects","subobjects","rectangles"} 
--which will return object[objects][subobjects][rectangles]
function g.var.parseRef(object, address)	
	_c_assert(type(object)=="table")
	local ref = object
	local addy
	local success = true
	for i=1, #address do	--{TestSub, TestTestSub}
		addy = address[i]
		if type(ref)=="table" then
			ref = ref[addy]
		else
			success = addy.." (failed at depth: "..tostring(i)..", total depth passed was: "..tostring(#address)..")"
			break
		end
	end
	if type(success)=="string" then 
		_c_warn("parseRef passed with object "..tostring(object).." depth less than address depth! "..success,5)
		success = false
	end
	return ref, success
end
function g.var.weightedRandom (pool)
    local poolsize = 0
    for k,v in ipairs(pool) do
      poolsize = poolsize + v[1]
    end
    local selection = math.random(1,poolsize)
    for k,v in pairs(pool) do
       selection = selection - v[1] 
       if (selection <= 0) then
          return v[2]
       end
    end
end
function g.var.getCentered(w,h)
	w = w or 1
	h = h or 1
	return (GAME_W - w)/2, (GAME_H - h)/2
end


g.table = {}
--[[Table #TABLE]]	--table related functions SPECIFICALLY
function g.table.addWrapped(value,max)
	if value <= max then return value
	else return value-max end
end
function g.table.getWrapped(list,ind)	
	if ind <= #list then return ind
	elseif (ind - #list) > #list then return getWrapped(list,ind-#list)
	else return ind-#list
	end
end
function g.table.unpack(t,start,total)
	_c_assert(type(t)=="table","unpack called on non-table! Type is: "..tostring(type(t)))
	start = start or 1
	total = total or #t
	if start > total then
		return
	end
	return t[start], gcore.table.unpack(t, start + 1, total)
end
function g.table.shallowcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end
g.var.shallowcopy = g.table.shallowcopy --alias
function g.table.deepcopy(orig, deep)
    deep = deep or 0
    if deep > g.config.deepcopylimit then return {} end
    --[[	--what exactly was I doing here?
	if type(orig) == 'table' and _G._ALLOBJECTS[orig] then
        return _G._ALLOBJECTS[orig] -- Return the reference to the shared object
    end
	--]]
    local copy
    if type(orig) == 'table' then
        copy = {}
        _G._ALLOBJECTS[orig] = copy
        for key, value in pairs(orig) do
            if type(value) == "table" then
                copy[key] = g.var.deepcopy(value, deep + 1)
            else
                copy[key] = value
            end
        end
        setmetatable(copy, getmetatable(orig))
    else
        copy = orig
    end
    return copy
end
g.var.deepcopy = g.table.deepcopy --alias
--- DOES NOT PRESERVE EXEMPTED FIELDS
--- Use this in situations where we need to exempt one or two fields from the copying to and creation of a NEW item
function g.table.overlay(o, new, exempt)
	if type(o) ~= "table" or type(new) ~= "table" then return {} end
	o = tablex.overlay(o,new)
	if exempt and type(exempt) == "table" then
		for k,v in pairs(exempt) do
			o[k] = nil
		end
	end
	return o
end
function g.table.merge(orig, new, override)
	-- If override is false, only add unique keys from new to orig
	-- If override is true, overwrite existing keys in orig with values from new
	for k, v in pairs(new) do
		if override or orig[k] == nil then
			orig[k] = v
		end
	end
end
--wrappers for adding (self) e.g. function someTable.copy = gcore.table.__shallowcopy allows us to use someTable:copy() for a shallowcopy of self.
function g.table.__shallowcopy(self)
	return g.table.shallowcopy(self)
end
function g.table.__deepcopy(self)
	return g.table.deepcopy(self)
end



g.graphics = {}
--[[Graphics #GRAPHICS]]
function g.graphics.getMousePosition()	--for now, assume the push library.
	local rx,ry = love.mouse.getPosition()
	return push:toGame(rx, ry)
end
function g.graphics.loadImageDataFromPath( filePath )
    local f = io.open( filePath, "rb" )
    if f then
        local data = f:read( "*all" )
        f:close()
        if data then
            data = love.filesystem.newFileData( data, "tempname" )
            data = love.image.newImageData( data )
            local image = love.graphics.newImageData( data )
            return image
        end
    else
		error('loadImageDataFromPath error: no file loaded!')
	end
end
function newFont_Sizes(fontname,tf,n)
	name = n or fontname or 'default'
	name = string.lower(name)
	tf = tf or 0	--tinyfont - you can pass the smallest font increment and it'll scale it up from there
	local sizetable = {t = 8+tf, s = 10+tf, m = 12+tf, l = 16+tf, xl = 18+tf, xxl = 20+tf, xxxl = 24+tf, xxxxl = 42+tf}
	for i,v in pairs(sizetable) do
		if fontname then
			local f = lg.newFont('fonts/'..fontname..'.ttf',v)
			_G.fonts[(name..'_'..string.lower(tostring(i)))] = f
		else
			local f = lg.newFont(v)
			_G.fonts[('default'..'_'..string.lower(tostring(i)))] = f
		end
	end
end

g.file = {}
--[[File ops #FILE]]

function g.file.evaluate(cmd,v) -- this uses recursion to solve math equations
    --[[ We break it into pieces and solve tiny pieces at a time then put them back together
        Example of whats going on
        Lets say we have "5+5+5+5+5"
        First we get this:
        5+5+5+5 +   5
        5+5+5   +   5
        5+5 +   5
        5   +   5
        Take all the single 5's and do their opperation which is addition in this case and get 25 as our answer
        if you want to visually see this with a custom expression, uncomment the code below that says '--print(l,o,r)'
    ]]
    v=v or 0
    local count=0
    local function helper(o,v,r)-- a local helper function to speed things up and keep the code smaller
        if type(v)=="string" then
            if v:find("%D") then
                v=tonumber(math[v]) or tonumber(_G[v]) -- This section allows global variables and variables from math to be used feel free to add your own enviroments
            end
        end
        if type(r)=="string" then
            if r:find("%D") then
                r=tonumber(math[r]) or tonumber(_G[r]) -- A mirror from above but this affects the other side of the equation
                -- Think about it as '5+a' and 'a+5' This mirror allows me to tackle both sides of the expression
            end
        end
        local r=tonumber(r) or 0
        if o=="+" then -- where we handle different math opperators
            return r+v
        elseif o=="-" then
            return r-v
        elseif o=="/" then
            return r/v
        elseif o=="*" then
            return r*v
        elseif o=="^" then
            return r^v
        end
    end
    for i,v in pairs(math) do
        cmd=cmd:gsub(i.."(%b())",function(a)
            a=a:sub(2,-2)
            if a:sub(1,1)=="-" then
                a="0"..a
            end
            return v(evaluate(a))
        end)
    end
    cmd=cmd:gsub("%b()",function(a)
        return evaluate(a:sub(2,-2))
    end)
    for l,o,r in cmd:gmatch("(.*)([%+%^%-%*/])(.*)") do -- iteration this breaks the expression into managable parts, when adding pieces into
        --print(":",l,o,r) -- uncomment this to see how it does its thing
        count=count+1 -- keep track for certain conditions
        if l:find("[%+%^%-%*/]") then -- if I find that  the lefthand side of the expression contains lets keep breaking it apart
            v=helper(o,r,evaluate(l,v))-- evaluate again and do the helper function
        else
            if count==1 then
                v=helper(o,r,l) -- Case where an expression contains one mathematical opperator
            end
        end
    end
    if count==0 then return (tonumber(cmd) or tonumber(math[cmd]) or tonumber(_G[cmd])) end
    -- you can add your own enviroments as well... I use math and _G
    return v
end

--[[Expansions #EXPANSIONS]]
--For now, just one. In addition to requiring debugcandy I want to make this core lib work with external libs
--However, it shouldn't directly depend on any external libs that aren't GC-made, so instead it can be expanded
--With a table that wraps them.
g.ex = {_self = g, core = g}

function g.ex:add(filepath, prefix)
	self = self._self	--upreference self
	filepath = filepath or 'core._g^crash_batteries'
	prefix = prefix or 'ex'	--overlapping expansions will not respect previously written functions however.
	if not self[prefix] then 
		self[prefix] = {} 
	end
	local expansion = require(filepath)
	for k,v in pairs(expansion) do
		self[prefix][k] = v
	end
end
g.ex:add() --now, call the function. _g^crash_batteries is online.

--[[Overloads #OVERLOADS]]
_G.lm = love.math
_G.lg = love.graphics
_G.lk = love.keyboard
_G.la = love.audio
_G.ld = love.data
_G.lf = love.font



_G._oldType = type
_G._oldAssert = assert

function _G.assert(v,message)	--#ASSERT overload replaces assert with debugcandy's assert calling _c_stop
	_c_assert(v,message,_c_stop)
end


--this is predicated on using methods.__addtype, or perhaps adding a __addtype into my core lib.
--this adds a new __type field to all tables. This will be used to store "primitive type" "address" "name" in its own field
--eventually __addType should ALSO validate that a type is not ALREADY added, and that the new type is not identical, preventing
--new tables being made evry time. although... that may be unnecessary if I do my primitives correctly.

---@type fun(v: any, comp?: any)
---@param v any
---@param comp? any type to compare to
--- overload replaces type with a flexible typing comparison/fetch function
function _G.type(v,comp)	--#TYPE 
	if comp then	--pass two arguments baby and it becomes a comparison
		if _G._oldType(v) == "table" then
			if v.__type then
				local t = v.__type
				return t.__type == comp or t.__primitive == comp or t.__address == comp or t.__name == comp	--in other words we can now use type(object,test) to compare primitive, address, or name
			else
				return _G._oldType(v) == comp
			end
		else
			return _G._oldType(v) == comp
		end
	else	--pass one argument and it returns a value
		if _G._oldType(v) == "table" then
			if v.__type then	--TODO: need a way to check against passing the whole __type vs. __type.__primitive
				return v.__type.__primitive
			else
				return _G._oldType(v)
			end
		else
			return _G._oldType(v)
		end	
	end
end

---@type fun(obj: table, t?: string, name?: string)
---Do not use? I think I need to use gcore.container.assignType instead
function _G.addType(obj,t,name)
	if _G._oldType(obj) ~= "table" then
		_c_warn("addType used on a non-table!")
	end
	obj.__type = t or "table"
	obj.__primitive = "table"
	obj.__address = tostring(obj)
	obj.__name = name or "unnamed"

end

--- @param v any
--- @param expand? boolean displays extra __type info, false by default
--- print the old type or the attributes of the __type table
function _G.type_print(v, expand, printable)
	local p
	if _G._oldType(v)=="table" then
		if v.__type then
			local t = v.__type
			p = {t.__primitive, t.__type, t.__name, t.__address, t.__assigned}
			if expand then
				p[1] = "primitive: "..p[1]
				p[2] = "type: "		..p[2]
				p[3] = "name: "		..p[3]
				p[4] = "address: "	..p[4]
				p[5] = "assigned: "	..p[5]
			end
			
		else
			p = _G._oldType(v)
		end
	else
		p = _G._oldType(v)
	end
	if not printable then _c_message(p) else
		if _G._oldType(p) == "table" then
		 	return "["..tostring(p[1]).."|"..tostring(p[2]).."|"..tostring(p[3]).."|"..tostring(p[4]).."|"..tostring(p[5]) .."]"
		else
			return p
		end

	end
end

--[[Replace print() with debugcandy, throw soft warnings w/trace if print() is used directly]]

--[[
function _G.print(...)
    local printResult = "print():"
    local args = {...}
    for i,v in ipairs(args) do
        printResult = printResult ..tostring(v)..","
    end
   -- printResult = printResult .."\n"
    _c_message(printResult,0)
end
--]]



--[[ Run Code #RUNCODE]]
local inputTable = {
	controls = {
		buttons = "all"
	},
	serialized = false,
	wheels = true,
	debug = true,
	Name = "GCoreController"
}


function g:load()
	if _G._CANDEBUG then
		_c_warn("_CANDEBUG set to ON. Game may perform slower!")
		self.debug:loadFonts(26)
		self.debug:createCanvas()
		--self.debug.toggle()			--for now the library is debugging.
		self._input = Classes.Input:new(inputTable)
		self._input:createParentRefs(self)
		
	end
	--Prototypes.Systems.ObjectSystem:attach(self)	-- don't use this anymore
	
end

function g:update(dt)
	if self._Debugging ~= _G._Debugging then
		self._Debugging = _G._Debugging

	end
	if self._Debugging then
		self._input:clear()
		self._input:update(dt)
		self.debug.container.strings.inputTable = g.debug:strPair(g.debug.tablePrint_stringWithBreaks(self._input.queues,"inputs"))
	end
	--clickable debug elements from debugcandy
end

function g:draw()
	--draw debug info if in debug mode.
	if self._Debugging then
		self.debug:push()
		self.debug:drawContainer()	--can add offsets later.
		self.debug:pop()
		lg.draw(self.debug.canvas)
	end
end


--[[ Reference g into global gcore ]]
_G.gcore = g
--Export the safety library into the global namespace.
_G._safe = g.safe