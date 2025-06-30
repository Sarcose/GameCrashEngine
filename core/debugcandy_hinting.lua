-- debugcandy_hinting.lua
---@diagnostic disable: lowercase-global

---@alias ANSIColor
---| '"\\x1b[30m"'  # Black foreground
---| '"\\x1b[31m"'  # Red foreground
---| '"\\x1b[32m"'  # Green foreground
---| '"\\x1b[33m"'  # Yellow foreground
---| '"\\x1b[34m"'  # Blue foreground
---| '"\\x1b[35m"'  # Magenta foreground
---| '"\\x1b[36m"'  # Cyan foreground
---| '"\\x1b[37m"'  # White foreground
---| '"\\x1b[0m"'   # Reset all
---| '"\x1b[47m"'	# White background			
---| '"\x1b[41m"'	# Red background				   		
---| '"\x1b[42m"'	# Green background			
---| '"\x1b[45m"'	# Magenta background
---| '"\x1b[40m"'   # Black background
---| '"\x1b[43m"'   # Yellow background
---| '"\x1b[44m"'   # Blue background
---| '"\x1b[46m"'	# Cyan background
--- ANSI escape codes for console colors.
---@alias CReminderType table|string|function Will call indiced functions in tables
---@alias CMessageType table|string Will call indiced functions in tables
---@alias CAssertResponseType boolean|function
---@alias CDebugExtraType integer|boolean|string

---@alias candycolor
---| '"yellow"'
---| '"red"'
---| '"blue"'
---| '"cyan"'
---| '"cyan"'
---| '"yellow"'
---| '"green"'

---@param color candycolor
--- noop to get colors for candy
_c_color = function(color) return color end

---@type fun(props: table)
---@param props table int Debug_Level, bool Colors, bool GUI, int Start, int Trace_Level, bool Override, bool Keys, int Table_Depth_Limit, int toDoExpiration, str reminderheader, str reminderfooter, int tabSize, bool backgrounds
--- also turn off library features with (debug, todo, remind, warn, error, stop, assert, success, message) with a bool=true or false
---; to change colors use table colors={debug="blue"} or bgcolors={warn="ANSICODE"}
_c_setCandyProp = function(props) end

---@type fun(...: any)
---@param ... any t,title,depth or {table t, int depth, string title}
--- formatted table diving, avoids recursion
_c_debugL = function(...) end

---@type fun(_: table, name: string, level?: integer, parseStart?: integer)
---@param _ table
---@param name string
---@param level? CDebugExtraType
---@param parseStart? CDebugExtraType
--- calls _c_debug() with a name attached. In the future all debugs should be rolled into one.
_c_debugN = function(_, name, level, parseStart) end

---@type fun(skip_global: boolean)
---@param skip_global? boolean if true, will skip the global namespace
--- prints the entire available namespace (globals, upvalues, locals) to the console for simplistic inspection. Does not capture variables pruned at runtime i.e. if an upvalue isn't used in the function that calls _c_printscope, then it won't be reported by this function.
_c_printscope = function(skip_global) end

---@type fun(_: table, level?: integer, parseStart?: integer)
---@param _ any
---@param level? CDebugExtraType
---@param parseStart? CDebugExtraType
--- does not dive into subtables. This should just be rolled into the same function as debugL tbh.
_c_debug = function(_,level,parseStart) end

---@type fun(todolist: table)
---@param todolist table (strings) {"mm/dd/yyyy" optional date, "TODO Item 1", "XCrossed off Todo Item"}
--- use _c_setCandyProp{Debug_Level = 1} or lower to turn off Todo expiration warnings. 
_c_todo = function(todolist) end

---@type fun(setdate: string, reminderdate: string, reminders: CReminderType) reminders can be a function in which case it will run that function after reminderdate
--- set a reminder. Will not do anything until after reminderdate has passed, then will use _c_warn() to display the reminder
_c_remind = function(setdate,reminderdate,reminders) end


---@type fun(...: any)
---@param ... any (message, level?, color?, bgcolor?) message can be any type and it will print or iterate if a table.
--- send a custom message, level defaults to 0 unless it's included. a string after the first message will always eval as color and then bgcolor
--- pass if arg 1 is a table you can also use direct key references level,color,bgcolor,calltag (calltag changes "MESSAGE:")
_c_message = function(...) end
---@type fun(_: CMessageType, level?: integer )
---@param _ CMessageType
---@param level? integer How many files in the stacktrace to display
--- Print green success message(s)
_c_success = function(_,level) end
---@type fun(_: CMessageType, level?: integer )
---@param _ CMessageType
---@param level? integer How many files in the stacktrace to display
--- Print yellow warning message(s)
_c_warn = function(_,level) end
---@type fun(_: CMessageType, level?: integer )
---@param _ CMessageType
---@param level? integer How many files in the stacktrace to display
--- Print red success message(s)
_c_error = function(_,level) end
---@type fun(eval: boolean, msg?: CMessageType, response?: CAssertResponseType)
---@param eval boolean
---@param msg? CMessageType
---@param response? CAssertResponseType  Pass a simple "true" for Response to stop the program; A function to run (passes msg) if assertion fails, or nil to continue going (still displays an error message)
---More robust assertion method allowing you to pass a table to print. 
_c_assert = function(eval, msg, response) end
---@type fun(_: CMessageType, level?: integer )
---@param _ CMessageType
---@param level? integer How many files in the stacktrace to display
---stop program with message, as error(). Like other debugcandy features, takes a CMessageType which will run functions.
_c_stop = function(_, level) end
