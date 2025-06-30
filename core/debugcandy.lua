---@diagnostic disable: redundant-parameter
-- Customization options

--[[
Refactor TODO:
	Functionality:
	--[X] Nested properties
		--[ ] Re-Address, test all methods
		--[ ] Implement new properties:
			--[X] Level and Switch checks
			--[ ] controls
			--[ ] tweaks
			--[ ] displayProperties
			--[ ] Remove deprecated
	--[ ] Put things like boolswitch and LoremIpsum into an optional helper subcategory
	--[X] Continue tweaking debugL
	--[X] Distinction of public and private methods, organization of document.
	--[ ] Better arg implementation of debug, allowing for a name that doesn't touch the table
		--[ ] Merge debug, debugN, debugL into one
	--[ ] Make a design decision re: export vs library, regarding update and draw
	--[ ] As of now, Debug_Level 3 is the same as 4. Recursion needs to be turned off for 3.
	--[ ] Better separation of debug vs. safety features. Maybe safety methods should be removed because of scope.
	--[ ] Rewrite or change generic methods for usability: printC/printCBG/blank/message
	
	Visual: full ANSI cheatsheet: https://gist.github.com/ConnerWill/d4b6c776b509add763e17f9f113fd25b
	--[ ] Get debugL lined up like debug is, in order to combine them.
	--[ ] Style options. Dim/Italic/Bold/Underline/Blinking/Strikethrough
	--[ ] Color is still not fully standardized in implementation; review all methods' practices.
	--[ ] Full implement of GUI
	--[ ] Change "reminderHeader/reminderFooter" into a generic wrapper that can put a header/footer over anything.
	--[ ] Could potentially set up tabs with an int and implement ccandy.load()
	--[ ] TBH, printC may be unnecessary. getANSI handles a lot of the logic of adding color escapes.
	
	Upload:
	--[ ] Properly work from a repo instead of right inside one of my projects >_<
	--[ ] Test every feature again
	--[ ] New screenshots
	--[ ] Documentation for all the new features

	
	
]]



--[[
Debug levels:	(ccandy.controls.Debug_Level)
	0: Set to 0 to turn the whole library OFF.
	1: Errors and Warnings only
	2: Messages, Todo lists, Reminders, high level debug information. Tables are not recursed.
	3: Recurse through tables, filtering constructor methods and allowing for "exclude" in ccandy.debugL()
	4: No filters, all information shown. Debugging still applies.

Keys:
	-- Arrows: Move gui output
	-- Shift: Speed up
	-- Ctrl: Slow down
	-- +/-: Zoom
	-- D+Number keys (1, 2, 3, 4) set Debug_Level

]]

local ccandy = {	--All properties in this initial table are open to be tweaked by the user
	controls = {			--Major functionality properties. Use the format Capital_Letter_Underscores to signiy their importance.
		Debug_Level = 2,
		Colors = true,		
		GUI = false,		--Toggle on GUI output for all methods. Multi-colored output not yet implemented (debugL)
		Start = 4,			--How many levels of stack trace to ignore (to avoid outputting the debug lib for instance)
		Trace_Level = 5,		--Level of stack trace all methods report by default. Level starts after |Start| is applied
		Override = false,	--Panic button. If true, all debug methods report |TraceLevel| stack trace, ignoring arguments.
		Keys = false,		--Set to true and use ccandy:update(dt) (or _c_debugUpdate(dt)) to have Debug Candy enable arrow keys for moving the GUI output
		Table_Depth_Limit = 9,	--hard limit on table depth parsing
	},
	switches = {			--Turn off the output of specific methods.
		debug 	= true,	
		todo 	= true,
		remind 	= true,
		warn 	= true,
		error 	= true,
		stop 	= true,
		assert 	= true,
		success = true,
		message = true,
	},
	tweaks = {				--Usage preferences
		toDoExpiration = 5,		--how long before a todo throws a warning that it's been ignored, only works if you pass a date.
		reminderheader = "==========!!!=======REMINDER=======!!!========",
		reminderfooter = "=========!!!=======================!!!========",
		tabSize = 3,
		backgrounds = false,
	},
	dev = {					--If you REALLY want to...
		debugTheDebugger = false,
	},
	displayProperties = {	-- TODO: add controls for offsetting.
		font = love.graphics.newFont(28),
		background = false,
		color = true,
		x = 0,
		y = 0,
		sx = 1,
		sy = 1,
		linespace = 0.5,
	},
	colors = {
		warn = "yellow",
		error = "red",
		debug = "blue",
		todo = "cyan",
		message = "cyan",
		remind = "yellow",
		success = "green"
	},
	bgcolors = {
		warn = "red",
		error = "white",
		debug = "yellow",
		todo = "magenta",
		message = "black",
		remind = "blue",
		success = "black"
	},
	--[[	Deprecated Properties	]]
	pathDepth = 1,			--now I don't remember what this is used for.
	reminderheader = "==========!!!=======REMINDER=======!!!========",
	reminderfooter = "=========!!!=======================!!!========",
	toDoTab = "   ",
--[[	End of Deprecation	]]
}
--[[ ANSI sequences ]]
local resetANSI = "\x1B[m"
local consolecolors = {
	black = "\x1b[30m",			white = "\x1b[37m",
	red = "\x1B[31m", 			green = "\x1B[32m", 	
	yellow = "\x1b[33m", 		blue = "\x1b[94m",
	magenta = "\x1b[35m",		cyan = "\x1b[36m"	}		
local bgcolors = {
	white = "\x1b[47m",				black = "\x1b[40m",
	red = "\x1b[41m",				yellow = "\x1b[43m",	   		
	green = "\x1b[42m",				blue = "\x1b[44m",
	magenta = "\x1b[45m",			cyan = 	"\x1b[46m"	}
local index_colors = {	--cyclical coloration of debugL
		"\27[96m", -- Bright Cyan
		"\27[94m", -- Bright Blue
		"\27[92m", -- Bright Green
		"\27[93m", -- Bright Yellow
		"\27[31m", -- Red
		"\27[36m", -- Cyan
		"\27[35m", -- Magenta
		"\27[34m", -- Blue
		"\27[32m", -- Green
		"\27[33m", -- Yellow
		"\27[90m", -- Gray (Muted)
		"\27[30m\27[47m", -- White on Black
	}
--[[ Local Variables ]]
local defaultExclude = {prefixes = {"_","__","_c_",}, keys = {}}

--[[ Local Helpers	]]

local function extractCallerInfo(level, parseStart)
    local stack = debug.traceback("", 2)
    local lines = {}
    for line in stack:gmatch("[^\n]+") do
        table.insert(lines, line)
    end
    local ret = ""
    parseStart = parseStart or 4
    local lastFile = nil
    local currentRange = {}
	local depth = ccandy.pathDepth
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
local function getCallLine(n,level,parseStart)
	level = ccandy:_getLevel(level)
	local line = extractCallerInfo(level,parseStart)
	return n.." "..line..": "
end
local function getDeepest(t, refs, depth)
    depth = depth or 1
    refs = refs or {}
    refs[t] = true -- Use the table itself as the key
    local deepest = depth
    local limit = ccandy.controls.Table_Depth_Limit

    if depth >= limit then return limit end

    for k, v in pairs(t) do
        if type(v) == "table" and not refs[v] then
            refs[v] = true
            local d = getDeepest(v, refs, depth + 1) -- Increment depth for recursion
            deepest = math.max(deepest, d)
            if deepest >= limit then return limit end
        end
    end

    return deepest
end
local function getSpacing(space, name, div)
	space = space or 9 --the size of a type label
	div = div or 1
	name = tostring(name)
	local spaces = ""
	local diff = space - #name
	diff = diff / div
	for i = 1, diff do
		spaces = spaces.." "
	end
	return spaces
end
local fileTypes = {".lua",".md",".love"}
local function formatFilePath(s)
	local str = s
	for i,v in ipairs(fileTypes) do
		str = string.gsub(str,v,"")
	end
	str = string.gsub(str,"/",".")
	return str
end
local function inspectFunc(func)	--#INSPECTFUNC
    local info = debug.getinfo(func)
    if not info then return "< addr:(invalid) > Invalid function" end

    -- Extract memory address from tostring
    local addr = tostring(func):match("function: (0x%x+)") or "(unknown)"

    -- Extract other details
    local name = info.name or ""
	if name and string.len(name) > 0 then name = "("..name..")" end
    local src = info.short_src or "unknown source"
	src = formatFilePath(src)
    local line = info.linedefined >= 0 and tostring(info.linedefined) or "(C function)"
    local nparams = info.nparams or 0
    local isvararg = info.isvararg and "vararg" or "fixed"

    -- Format as a one-line string
    return string.format(" addr:%s%s [%s:%s] Args: %d (%s)", 
        addr, name, src, line, nparams, isvararg)
end
local function inspect(i, refs)				--#INSPECT
    refs = refs or {}
    local t = type(i)
    local ret = ""
    local symbol = "= "
    local limit = ccandy.controls.Table_Depth_Limit

    if t == "table" then
        symbol = ""
        local addr = string.gsub(tostring(i), "table: ", "")
        ret = ret .. "[ addr:" .. tostring(addr)

        if refs[i] then
            ret = ret .. "   <already visited> ]"
            return ret
        end
        refs[i] = true -- Mark table as visited

        local n = 0
        local deep = 1
        for k, v in pairs(i) do
            if type(v) == "table" and refs ~= "flat" then
                local d = deep-- getDeepest(v, refs)
                deep = math.max(deep, d)
            end
            if not tonumber(k) then n = n + 1 end
        end

        local keys = n > 0 and "   keys:" .. n or ""
        if #i > 0 or keys ~= "" then
            ret = ret .. "   #len:" .. #i .. keys
            if deep >= limit then
                ret = ret .. "   depth: > LIMIT (" .. tostring(limit) .. ")"
            elseif deep > 1 then
                ret = ret .. "   depth:" .. tostring(deep)
            end
        else
            ret = ret .. "   <empty>"
        end
        ret = ret .. " ]"
    elseif t == "function" then
		ret = ret.. inspectFunc(i)
        symbol = ""
    elseif t == "string" then
        ret = '"' .. i .. '"'
    else
        ret = tostring(i)
    end
	t = tostring(t)
    local space = getSpacing(nil, "(" .. t .. ")")
    if refs == "flat" then space = "" end
    return "(" .. t .. ")" .. space .. symbol .. ret
end
local function checkChecked(s)
    if string.sub(s, 1, 1) == "X" then
        -- Return the string without the "X" and true (indicating it started with "X")
        return string.gsub(s,"X",""), true
    else
        -- Return the original string and false (indicating no leading "X")
        return s, false
    end
end
local function compareDate(inputString)
    local currentDate = os.date("*t")
    local currentYear = currentDate.year
    local month, day, year = inputString:match("^(%d%d)/(%d%d)/(%d%d%d%d)$")
    if month and day and year then
        month, day, year = tonumber(month), tonumber(day), tonumber(year)
    else
        month, day = inputString:match("^(%d%d)/(%d%d)$")
        if month and day then
            month, day = tonumber(month), tonumber(day)
            year = currentYear
        else
            return false, nil -- Not a valid date format
        end
    end
    if not (month >= 1 and month <= 12 and day >= 1 and day <= 31) then
        return false, nil -- Invalid date
    end
    local inputTime = os.time({year = year, month = month, day = day})
    local currentTime = os.time()
    local secondsPassed = currentTime - inputTime
    local daysPassed = math.floor(secondsPassed / (24 * 60 * 60)) -- Convert seconds to days
    return true, daysPassed
end
local function getANSI(name,bgcolor)		--#GETANSI
	if not ccandy.controls.Colors then return "" end
	local e = consolecolors[ccandy.colors[name]]
	local bg 
	if not e then 
		e = consolecolors[name]
	end
	if not e then e = "" end
	
	if bgcolor then 
		bg = bgcolors[ccandy.bgcolors[name]]
		if not bg then
			bg = bgcolors[bgcolor]
		end
		if not bg then bg = "" end
	end
	
	
	if ccandy.tweaks.backgrounds then
		if not bg or (type(bg) == "string" and string.len(bg) <= 0) then
			bg = bgcolors[ccandy.bgcolors[bg]]
		end		
	end
	if not bg then bg = "" end
	e = e ..bg
	return e
end
local function boolswitch(v) return not v end
local function isEmpty(t)	--where was I using this? it appears to be unused. 
	local empty = true
	if #t>0 then empty = false
	else
		for k,v in pairs(t) do
			empty = false
			break
		end
	end
	return empty
end
--[[ TODO:	--needs to be updated as of 01/27/25
	- [ ] brackets don't appear behind their table values, this should be rectified
	- [ ] perhaps class instances should not be dug into, based on something set in classic:extend
	- [X] instead of relying on printC for color, roll our own color. Use multicolored printouts to link tables, with all variety of color combos.
	- [ ] colors look good, however some tables still appear empty but have newlines between the brackets {/n}. This creates some color overlap into the next table
	- [ ] Additionally, some tables appear to have another color as their "empty space" on the open bracket line
	- [ ] Removing more background colors because they don't all look good in this context.
]]
local function getWrapped(tbl, index)
    -- Ensure the input is a table
    assert(type(tbl) == "table", "First argument must be a table")
    
    -- Ensure the table is not empty
    local length = #tbl
    if length == 0 then
        error("Table is empty")
    end

    -- Calculate the wrapped index
    local wrappedIndex = ((index - 1) % length) + 1

    return tbl[wrappedIndex]
end
local function checkExclusion(key, exclude)
    ccandy.assert(type(exclude) == "table", "Exclude must be a table")
    if type(exclude.prefixes)=="table" then
		for _, prefix in ipairs(exclude.prefixes) do
			if type(key) == "string" and key:sub(1, #prefix) == prefix then
				return true
			end
		end
	end
	if type(exclude.keys)=="table" and exclude.keys[key] then
        return true
    end
    return false
end
local function dname(_,name)
	if type(_)=="table" then _._tableName = name
	else _ = {value=_,_tableName=name}
	end
	return _
end
local function getTab(t)
	t = t or ccandy.tweaks.tabSize
	if type(t) == "string" then return t end	--just return the tab if it's already a string
	local tab = ""
	for i=1,t do
		tab = tab .. " "
	end
	return tab
end
local function debugLayers(args, visited)		--#LAYERS --#DEBUGLAYERS
    visited = visited or {} -- Tracks already visited tables
    local t = args._t or args.t or args._table or args.table or args[1]
    if type(t) ~= "table" then
        return inspect(t) -- If not a table, return the inspected value
    end

	local level = ccandy:_getLevel(args.level or 0)
	local parseStart = args.parseStart or ccandy.controls.Start
    local depth = args.depth or math.floor(ccandy.controls.Table_Depth_Limit / 2)
    local colorDepth = args.colorDepth or 1
    local color = resetANSI .. getWrapped(index_colors,colorDepth)
	local formerColor = resetANSI..getWrapped(index_colors,colorDepth-1)
    local title = args.title or ""
    local exclude = args.exclude or defaultExclude --TODO: needs to be able to exclude classic's __methods

	--Prepare Tabs
	local tab, halftab
	if type(args.tab)=="number" then
		halftab = getTab(args.tab - ccandy.tweaks.tabSize)
		tab = getTab(args.tab)
	elseif type(args.tab)=="string" then
		halftab = getTab(string.len(args.tab)- ccandy.tweaks.tabSize)
		tab = args.tab
	else
		halftab = getTab(ccandy.tweaks.tabSize/2)
		tab = getTab()
	end
	--tab = tab .. "++"
	--halftab = halftab .."\\"
    -- Track visited tables
    local addr = tostring(t)
    if visited[addr] then
        return formerColor .. halftab .. title .. color.. " = <already visited>" .. inspect(t) .. " \r\n"
    end
    visited[addr] = true

    -- Prepare output
	
	local output = ""
	if not visited.___initialized then 	--exclusively for the title of the whole printout.
		output = output..getCallLine("DEBUG",level,parseStart) 
		halftab = ""
		formerColor = color
		visited.___initialized = true
	end
    output = output .. formerColor .. halftab .. title .. " = {"..getTab(ccandy.tweaks.tabSize)..inspect(t).."\r\n"

	if depth <= 0 then
        output = output .. color .. tab .. "  <depth limit reached>\r\n" .. color .. tab .. "}\r\n"
        return output
    end

    -- Process elements
    for k, v in pairs(t) do
        if checkExclusion(k, exclude) then
            goto skip -- Skip excluded keys
        end

        local valueType = type(v)
        if valueType == "table" then
			local keyCount = 0
			local nested = false
			for _,k in pairs(v) do keyCount = keyCount + 1 if type(v)=="table" then nested = true end end
			if keyCount == 0 then
				output = output .. color .. tab .. "[" .. tostring(k) .. "] = { } \r\n"
			elseif nested==false and keyCount <= 5 then -- Inline formatting for small tables
				local inline = "{ "
				for subKey, subValue in pairs(v) do
					inline = inline .. tostring(subKey) .. " = " .. inspect(subValue) .. ", "
				end
				inline = inline:sub(1, -3) .. " }" -- Remove trailing comma
				output = output .. color .. tab .. "[" .. tostring(k) .. "] = " .. formerColor .. inline .. "\r\n"
			else
				output = output .. debugLayers({
					table = v,
					tab = string.len(tab) + ccandy.tweaks.tabSize,
					exclude = exclude[k],
					depth = depth - 1,
					title = "[" .. tostring(k) .. "]",
					colorDepth = colorDepth + 1
				}, visited)
			end
        elseif valueType == "function" then
            output = output .. color .. tab .. "[" .. tostring(k) .. "] = (function)"..inspectFunc(v).."\r\n"
        else
            output = output .. color .. tab .. "[" .. tostring(k) .. "] = " .. inspect(v) .. "\r\n"
        end

        ::skip::
    end

    output = output .. formerColor .. tab .. "}\r\n"
    return output
end
local function key(s)	return "["..s.."] = " end
local function locals()	--source: https://stackoverflow.com/questions/2834579/print-all-local-variables-accessible-to-the-current-scope-in-lua
  local variables = {}
  local idx = 1
  while true do
    local ln, lv = debug.getlocal(2, idx)
    if ln ~= nil then
      variables[ln] = lv
    else
      break
    end
    idx = 1 + idx
  end
  return variables
end


--[[ Private Methods ]]
--used for internal debugging only.

function ccandy:_getLevel(l)
	if self.controls.Override then return self.controls.Trace_Level else return l end
end
function ccandy._display(color, disp)	--#DISPLAY
	if ccandy.gui then
		if type(disp)=="string" then
			table.insert(ccandy._drawTable,ccandy._drawObject("string",color,disp))
		end
	else	--		ccandy._display("warn",{heading,since})
		if type(color) == "table" or type(disp)=="table" then
			ccandy.printCTable(color,disp)
		elseif color == "none" then
			ccandy.printC("",disp)
		else
			ccandy.printC(color,disp)
		end
	end
end
function ccandy._debug(...)	--#_DEBUG	--used for internal debugging
	local args = {...}
	local colors = {["debug"] = "\x1B[31m", ["string"] = "\x1B[32m", ["boolean"] = "\x1b[33m", ["table"] = "\x1b[94m", ["function"] = "\x1b[35m", ["number"] = "\x1b[36m"	}
	local output = colors.debug.." Internal Debug in "
	output = output.. getCallLine("INTERNAL",10,1)..resetANSI
	for i,v in ipairs(args) do
		local color = colors[type(v)]
		output = output..color..tostring(v)..", "
	end
	print(output..resetANSI)
end

--[[ Public Methods   ]]
----[[	Manage the Library 	]]
function ccandy.setCandyProp(props) 
	assert(type(props) == "table")
	local c, s, t, d = ccandy.controls, ccandy.switches, ccandy.tweaks, ccandy.dev
	local setProp = function(p,v)
		if c[p] then c[p] = v return true end
		if s[p] then s[p] = v return true end
		if t[p] then t[p] = v return true end
		if d[p] then d[p] = v return true end

	end
	for k,v in pairs(props) do
		if type(v) ~= "function" and type(v) ~= "table" then
			--check various ccandy tables
			if setProp(k,v) then ccandy.message(k .. " set to "..tostring(v))
			else ccandy.error{"setCandyProp called with invalid value: ("..tostring(k).." = "..tostring(v)..")"} 
			end
		elseif k == "colors" and type(v) == "table" then


		elseif k == "bgcolors" and type(v) == "table" then


		end
	end
end
function ccandy.setGUI(set)
	if set then ccandy.gui = set else ccandy.gui = boolswitch(ccandy.gui) end
end


----[[  Library Features   ]]
function ccandy.printscope(skip_global) --g = "skip global scope" or not. Always prints local scope & upvalues. This function prints the whole accessible scope from where it was called.
	--useful for determining what is exposed to the current scope and managing your scoping
	--intentionally flat. Should be no need for diving.
	local p = getCallLine("SCOPE",10)
	local tab = "\r\n              "
	local branch = "    ---"
	local function header(s) return "=="..s.."==" end
	if not skip_global then
		p = p .. tab..header("Global Scope")
		for k,v in pairs(_G) do
			if k ~= "_G" and k ~= "love" then
				p = p ..tab..branch..key(k)..inspect(v)
			end
		end
		p = p .. tab .. branch .. key("love") .. type(love)
		p = p .. tab .. branch .. key("_G") .. type(_G)
	end
	p = p .. tab .. header("Upvalue Scope")
	local upvalues = {}
	local idx = 1
	local func_info = debug.getinfo(2, "f")
	if func_info and func_info.func then
		local func = func_info.func
		while true do
			local ln, lv = debug.getupvalue(func, idx)
			if ln ~= nil then
				upvalues[ln] = lv
			else
				break
			end
			idx = 1 + idx
		end
	end
	for k,v in pairs(upvalues) do
		p = p..tab..branch..key(k)..inspect(v)
	end
	p = p .. tab .. header("Local Scope")
	local locals = {}
	idx = 1
	while true do
		local ln, lv = debug.getlocal(2, idx)
		if ln ~= nil then
		locals[ln] = lv
		else
		break
		end
		idx = 1 + idx
	end
	
	for k,v in pairs(locals) do
		p = p..tab..branch..key(k)..inspect(v)
	end
	ccandy._display("debug",p)
end

function ccandy.debugL(...)	--t,title,depth or args = {table table, int depth, string title} #DEBUGL
	if ccandy.controls.Debug_Level < 2 or not ccandy.switches.debug then return end
	local args = {...}
	local t, title, depth = args[1], args[2], args[3]
	if type(t) == "table" then
		if title then
			local a = {t = args[1], title = args[2], depth = args[3]}
			ccandy._display("none",debugLayers(a))

		else
			if t._t or t._table or t.table or t.t then	--it is an arg table. Also, #deprecating #deprecate I'm deprecating the use of "table" and "t" because it's too prone to error
				ccandy._display("none",debugLayers(t))					--use _t or _table instead.
			else	--it is a table, to be inspected directly
				ccandy._display("none",debugLayers{t=t})
			end
		end
	else
		local a = {t=t, title=title, depth=depth}
		ccandy._display("none",debugLayers(a))
	end
end
function ccandy.debugN(_,name,level,parseStart)
	ccandy.debug(dname(_,name),level,parseStart)
end
function ccandy.debug(_,level,parseStart)			--#DEBUG
	if ccandy.controls.Debug_Level < 2 or not ccandy.switches.debug then return end
	local name = "DEBUG"
	if type(level)=="string" then name = level; level = ccandy.controls.Trace_Level end
	local p = getCallLine(name,level,parseStart)
	if type(_) ~= "table" then 
		if type(_) == "string" then
			p = p .. _		--if it's a string we don't bother with the inspection, just print it as a message
		else
			p = p ..inspect(_)
		end
	else
		local cap = "\r\n  "
		if _.horizontal then 
			cap = "|" _.horizontal = nil 
		end
		p = p..tostring(_)
		local longestname = 0
		local refs = {}
		refs[tostring(_)] = true
		for k,v in pairs(_) do
			if type(k) == "string" then
				if #k > longestname then longestname = #k end
			end
		end
		if _._tableName then
			p = p..cap
			p = p..getSpacing(longestname,i,1.5).."Table Name: "..tostring(_._tableName)
		end
		for i=1, #_ do
			p = p..cap
			p = p..getSpacing(longestname,i)..tostring(i).." : "..inspect(_[i], refs)
		end
		for k,v in pairs(_) do
			if k ~= "_tableName" then
				if not tonumber(k) then
					p = p..cap
					p = p..getSpacing(longestname,k)..k.." : "..inspect(v, refs)
				end
			end
		end
		p = p:match("^(.-)[,\r\n]?$")
	end
	ccandy._display("debug",p)
end
function ccandy.todo(_) --#TODO
	if ccandy.controls.Debug_Level < 2 or not ccandy.switches.todo then return end
	local level = ccandy:_getLevel(1)
	local todotab = ccandy.toDoTab
	if type(_) ~= "table" then _ = {tostring(_)} end
	local p1 = getCallLine("TODO",level)
	local p2 = nil
	local p3 = ""
	local checked = "[X] "
	local unchecked = "[ ] "
	local checkbox = ""
	local exTimePassed
	local datefound,date,timePassed
	for i=1, #_ do
		local item = _[i]
		if not datefound then date, timePassed = compareDate(item) end
		if date then
			exTimePassed = timePassed
			if timePassed >= ccandy.tweaks.toDoExpiration then
				p2 = todotab.."WARNING: "..tostring(timePassed).." days since this Todo list was updated!"
			end
			datefound = true
			date = false
		else
			local s, isChecked = checkChecked(tostring(_[i]))
			if isChecked then
				checkbox = checked
			else
				checkbox = unchecked
			end

			local _s, count = string.gsub(s,"*","")
			local tab = ""
			for i=1, count do
				tab = tab..todotab
			end
			p3 = p3.."  "..tab..checkbox.._s
			if i < #_ then
				p3 = p3.."\r\n"
			end
		end
	end
	local warncolor = nil
	if exTimePassed then
		if exTimePassed >= (ccandy.tweaks.toDoExpiration * 3) then
			warncolor = getANSI("error")
		elseif exTimePassed >= ccandy.tweaks.toDoExpiration then
			warncolor = getANSI("error")
		end
	end
	ccandy._display({"todo","warn","todo"},{p1,p2,p3})
end
function ccandy.remind(setdate,reminderdate,_)			--#REMIND
	if ccandy.controls.Debug_Level < 2 or not ccandy.switches.remind then return end
	local date, timePassedSinceSet = compareDate(setdate)
	assert(date,"ccandy.reminder called without setdate!")
	date, timePassedSinceReminder = compareDate(reminderdate)
	assert(date,"ccandy.reminder called without reminderdate!")
	if timePassedSinceReminder >= 0 then
		local heading = ccandy.reminderheader
		local since = "A reminder was set on "..setdate.." "..timePassedSinceSet.." days ago!"
		local reminder = ""
		local post = ccandy.reminderfooter
		ccandy._display("warn",{heading,since})
		--ccandy.printCTable(ccandy.colors.warn,{heading, since})
		if type(_) == "table" then
			for i,v in ipairs(_) do
				if type(v)=="string" then
					reminder = reminder..v
					if i < #_ then
						reminder = reminder.."\r\n"
					end
				elseif type(v)=="function" then
					v()
				end
			end
		elseif type(_) == "function" then
			_()
		else
			reminder = reminder.._
		end
		if type(_) == "table" then
			for k,v in pairs(_) do
				if type(k) ~= "number" then
					if type(v) == "function" then
						_[k]()
					end
				end
			end
		end
		ccandy._display("warn",reminder)
		ccandy._display("remind",post)
		--ccandy.printC(ccandy.colors.warn,reminder)
		--ccandy.printC(getANSI("remind"),post)
	end
end
function ccandy.message(...) --#MESSAGE
	if ccandy.controls.Debug_Level < 1 or not ccandy.switches.message then return end
	local args = {...}
	local _, level, color, bgcolor, calltag,newline
	if type(args[1]) ~= "table" then 
		_ = {args[1]} 
	else 
		_ = args[1] 
		level = _.level
		color = _.color
		bgcolor = _.bgcolor
		calltag = _.calltag
		newline = _.newline
	end
	if type(args[2]) == "string" then color = args[2] bgcolor = args[3] level = nil end
	if type(args[2]) == "number" then level = args[2] color = args[3] bgcolor = args[4] end
	if type(args[2])=="boolean" or type(args[3])=="boolean" or type(args[4])=="boolean" then newline = true end
	calltag = calltag or "Message"
	color = color or "cyan"
	level = ccandy:_getLevel(level) or 0
	if type(bgcolor) == "number" then bgcolor = nil end --parseStart dummied out from old implements for now.
	local p = getCallLine(calltag,level)
	local item
	for i=1, #_ do
		item = _[i]
		if type(item)=="table" then
			local tab = "     "
			for i,v in ipairs(item) do
				if newline and i > 1 then
					p = p .. "\r\n"..tab
				end
				p = p .. tostring(v)
				if i < #item and not newline then
					p = p..", " 
				end
			end
		else
			if type(item)=="function" then
				item()
			else
				p = p..tostring(item)
			end
			if i < #_ then
				if newline then p = p.."\n"
				else p = p..", " 
				end
			end
		end
		
    end
	if bgcolor then color = color.."|"..bgcolor end
	ccandy._display(color,p)
end
function ccandy.success(...)
	if ccandy.controls.Debug_Level < 2 or not ccandy.switches.success then return end
	local args = {...}
	local m = {[1] = args[1], level = args[2] or 1, color = "success", calltag = "Success"}
	ccandy.message(m)	--only _ and level are passed
end
function ccandy.warn(...)
	if ccandy.controls.Debug_Level < 1 or not ccandy.switches.warn then return end
	local args = {...}
	local m = {[1] = args[1], level = args[2] or 3, color = "warn", calltag = "WARNING"}
	ccandy.message(m)	--only _ and level are passed
end
function ccandy.error(...)
	if ccandy.controls.Debug_Level < 1 or not ccandy.switches.warn then return end
	local args = {...}
	local m = {[1] = args[1], level = args[2] or 4, color = "error", calltag = "ERROR"}
	ccandy.message(m)
end


function ccandy.stop(_,level) --print red to console then stop the program
	_ = _ or "_"
	if ccandy.controls.Debug_Level < 1 or not ccandy.switches.stop then return end
	ccandy.error(_,level)
	if type(_) == "table" then _ = _[1] end
	error("Stopped by ccandy.stop(): ".._.." (console may have more info)")
end
function ccandy.assert(eval,msg,response) 	--#ASSERT
	if ccandy.controls.Debug_Level < 1 or not ccandy.switches.remind then return end
	local level = ccandy:_getLevel(10)
	if not eval then
		local p = getCallLine("Assertion Fail",level, parseStart)
		p = p .. msg
		if response then
			if type(response)=="function" then 
				p = "\r\n"..p
				response(p) 
			else 
				ccandy.stop(p)
			end
		else
			ccandy.error(p)
		end
		return false
	end
	return true
end
----[[  Extra Visual Methods   ]]
function ccandy.blank(msg,n)
	if type(msg) == "number" then n = msg; msg = nil end
	n = n or 10
	local p = ""
	for i=1,n do
		p = p .. "\r\n"
	end
	if msg then ccandy._display("green",tostring(msg)) end
	ccandy._display("none",p)
end
function ccandy.printCBG(_, color, bg, reset)	
	local s = ""
	if consolecolors[color] then s = s .. consolecolors[color] end
	if bgcolors[bg] then s = s..bgcolors[bg] end
	if type(_) == "table" then
		for i=1,#_ do
			s = s .. _[i].."    "	--/t seems to break bg color
		end
	else
		s = s .. tostring(_)
	end
	s = s .. "\r\n"
	ccandy._display("none",s)
	if reset then ccandy._display("reset")io.write(resetANSI) end
end
function ccandy.printC(ANSI, _)		--#PRINTC
	if ccandy.controls.Colors then
		local c, fg, bg
		if string.find(ANSI,"|") then
			fg, bg = ANSI:match("([^|]+)|([^|]+)")	--match if color is sent as a string of "Blue|Yellow"
			c = getANSI(fg, bg)
		elseif ccandy.colors[ANSI] or consolecolors[ANSI] then
			c = getANSI(ANSI)
		else
			c = ANSI
		end
		io.write(c)
	end
	_ = _ .. resetANSI
	io.write(_)
	io.write("\r\n")
end
function ccandy.printCTable(cTable, sTable)	--#PRINTCTABLE
	local onlyColor
	if type(cTable) == "string" then onlyColor = cTable end
	if type(sTable) == "string" then sTable = {sTable} end
	for i=1, #sTable do
		local s = sTable[i]
		if s then
			local c = onlyColor or getWrapped(cTable,i)
			c = c or "reset"
			ccandy.printC(c,s)
		end
	end
end
function ccandy._drawObject(t,color,item,x,y,sx,sy,font)
	local object = {}
	x = x or ccandy._displayProperties.x
	y = y or ccandy._displayProperties.y
	sx = sx or ccandy._displayProperties.sx
	sy = sy or ccandy._displayProperties.sy
	font = font or ccandy._displayProperties.font
	local oldfont = love.graphics.getFont()
	if type(t)=="string" then
		function object.draw()
			lg.setFont(font)
			love.graphics.print(item,x,y,0,sx,sy)
		end
	elseif type(t) =="table" then


	end
	--maybe others
	return object

end


----[[  load, update, draw, export, test ]]

local dlist = {
	{"success"," Success messages will not display"},
	{"debug","   No debug info will be displayed."},
	{"todo","    You will not see your todo lists."},
	{"message"," Standard messages after this message are turned OFF."},
	{"remind","  Reminders will be hidden."},
	{"warn","    You will not see warnings!"},
	{"assert","  Assertions will not run."},
	{"error","   Ignoring all errors!"},
	{"stop","    Program stops will be ignored."},
}
local loremWords = {
    "Lorem", "ipsum", "dolor", "sit", "amet", "consectetur", "adipiscing", "elit", 
    "sed", "do", "eiusmod", "tempor", "incididunt", "ut", "labore", "et", 
    "dolore", "magna", "aliqua", "Ut", "enim", "ad", "minim", "veniam", "quis", 
    "nostrud", "exercitation", "ullamco", "laboris", "nisi", "aliquip", "ex", 
    "ea", "commodo", "consequat", "Duis", "aute", "irure", "dolor", "in", 
    "reprehenderit", "voluptate", "velit", "esse", "cillum", "dolore", "eu", 
    "fugiat", "nulla", "pariatur", "Excepteur", "sint", "occaecat", "cupidatat", 
    "non", "proident", "sunt", "in", "culpa", "qui", "officia", "deserunt", 
    "mollit", "anim", "id", "est", "laborum"
}
local function randomWord()
    return loremWords[math.random(#loremWords)]
end
local function LoremIpsum(n,div)
	div = div or " "
	n = n or 20
    local result = ""
    for i=1, n do
		result = result .. randomWord()..div
	end
    return result
end

local function generateRandomKey(n)
	n = n or 0
	local i = math.random(1,2)
	if i == 1 then
		return tostring(n+1)
	else
		return LoremIpsum(2,"")
	end
end
--string, number, big, function, bool
local function generateRandomVar()
	local t = math.random
	if t == 1 then
		return LoremIpsum(math.random(1,10))
	elseif t == 2 then
		return math.random(1,100) * (math.random(0, 1) * 2) - 1
	elseif t == 3 then
		return math.big
	elseif t == 4 then
		return function(...) end
	elseif t == 5 then
		return "bool"
	else
		return "nothing"
	end

end

local function generateRandomFlatTable(keys)
	local t = {}
	local n = 0
	keys = keys or 10
	for i=1,keys do
		local k = generateRandomKey(n)
		local var = generateRandomVar()
		if var == "bool" then
			t[k] = true
		elseif var == "nothing" then
			t[k] = nil
		else
			t[k]=var
		end
	end
	return t
end

function ccandy.test()		--#TEST

	ccandy.selfReference = ccandy	--create a recursive reference for debugging
	--[]
	local externFunction = function(...) end
	local testObject = {
		str = "this is a string",
		longstring = LoremIpsum(),
		int = 12345,
		bignumber = math.huge,
		float = 54321.12345,
		awesomeFunction = function(arg1, arg2, arg3) end,
		trueBoolean = true,
		falseBoolean = false,
		nothing = nil,
		varFunction = function(...) end,
		refFunction = externFunction,
		flatTable = generateRandomFlatTable(10),
		nestedTable = {
			level2 = {
				LoremIpsum(),
				level3 = {
					LoremIpsum(),LoremIpsum(),LoremIpsum(),
					str = "blah",
					level4 = generateRandomFlatTable(3),
				}
			}
		},
		selfReferencingTable = generateRandomFlatTable(10),
		shortTable = generateRandomFlatTable(3)
	}
	testObject.selfReference = testObject
	testObject.selfReferencingTable.selfReference = testObject.selfReferencingTable
	testObject.selfReferencingTable.selfselfReference = testObject.selfReferencingTable.selfReference
	
	local debugLayerTest = {t = testObject, title = "Test Table"}
	local debugTest = testObject
	local todoTest = {"11/01/2024","Make a new TODO!","XCross off an item!"}
	local successTest = "Success test!"
	local messageTest = "message test!"
	local warnTest = {"warning!","this is your warning message!"}
	local errorTest = {"error! You did an erroneous thing!"}
	local assertTest = (1==2)
	local assertmsgTest = "1==2 assertion failed you silly!"
	local stopTest = "Stopping the program for test"
	ccandy.debugL(debugLayerTest)
	ccandy.debug(debugTest)
	ccandy.remind("01/09/2025","01/09/2025","Make a new reminder!!")
	ccandy.todo(todoTest)
	ccandy.success(successTest)
	ccandy.message(messageTest)
	ccandy.warn(warnTest)
	ccandy.error(errorTest)
	ccandy.assert(assertTest,assertmsgTest)
	

	ccandy.selfReference = nil	--clean up recursive test reference

	ccandy.stop(stopTest)
end

function ccandy.load()
	ccandy.toDoTab = getTab(ccandy.tweaks.tabSize)
	ccandy._drawTable = {}
	if ccandy.controls.Debug_Level >= 1 then
		local lev = ccandy.controls.Debug_Level
		ccandy.controls.Debug_Level = 3
		local msg = "Debug Candy initialized at Debug Level "..tostring(lev).."\r\n"
		local optionsOn = true
		for i,v in ipairs(dlist) do
			local method = v[1]
			if not ccandy.switches[method] then
				msg = msg.."      "..getANSI(method)..method.." OFF. "..v[2].."\r\n"
				optionsOn = false
			end
		end
		if optionsOn then msg = msg.."      All options ON." end
		local m = ccandy.switches.message
		ccandy.switches.message = true
		ccandy.message(msg,0)
		ccandy.switches.message = m
		ccandy.controls.Debug_Level = lev
	end	

	if ccandy.dev.debugTheDebugger then
		ccandy.test()
	end
end
function ccandy.update(dt)
	local self = ccandy



end
function ccandy.draw()
	local self = ccandy
	for i=1, #self._drawTable do
		self._drawTable[i].draw()
	end
	self.drawTable = {}
end
function ccandy:export(n)
	ccandy.load()
	n = n or "_c_"
	local ignore = {export=true, _getLevel=true, _dname=true,update=true,draw=true}
	n = n or ""
	for k,v in pairs(self) do
		local p = "checking to export: "..tostring(k)
		if not ignore[k] and k:sub(1, 1) ~= "_" and type(v) == "function" then
			local f = n..k
			_G[f] = v
			p = p.."->exported as "..f.."."
		end
		if self.dev.debugTheDebugger then print(p) end
	end
end



return ccandy