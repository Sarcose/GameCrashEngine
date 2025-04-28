--[[
Usage:
local quicktimer = require 'quicktimer'

quicktimer:start(name)  --starts a new timer of `name` -- will overwrite a timer of same name!
--run some code
quicktimer:stop(name,comment)
>>prints start time and end time of a test to console, with time elapsed and your optional comment

quicktimer:kick(name,comment)
"kicks" the last-created timer off and replaces it with name new. Can be used to start timers and replace same-name timers without overwriting

other options:
quicktimer.name = "QUICKTIMER"; change the name of the module as printed to the console. Set nil to not print any name.
quicktimer.color = <ansicode> e.g. "\x1b[44m\x1b[37m" prints white on blue, the default. NAME is not printed to console.
]]


local warncolor = '\x1b[44m\x1B[31m'
local resetANSI = "\x1B[m"

local q = {
    name = "QUICKTIMER",
    tests = {},
    color = '\x1b[44m\x1b[37m',
    current = "",
}

function q:print(s,comment)
    local colon = ""
    if self.name then colon = ": " end
    local name = self.name or ""
    if comment then
        print(name..colon..self.color..s.." Comment: "..tostring(comment)..resetANSI)
    else
        print(name..colon..self.color..s..resetANSI)
    end
end

function q:start(n)
    n = n or 'anon'
    local t = {
        start = os.clock(),
        finished = 0,
        timepassed = 0
    }
    if self.tests[n] then
        print(warncolor..'['..n..'] timer overwritten!')

    end
    self.tests[n] = t
    self:print('starting runtime test ['..n..'] at '..tostring(t.start)..' seconds')
    self.current = n
end


function q:stop(n,comment)
    n = n or 'anon'
    self.tests[n].finished = os.clock()
    self.tests[n].timepassed = self.tests[n].finished - self.tests[n].start
    self:print('runtime test ['..n..'] finished at '..self.tests[n].finished..' with time passed: '..tostring(self.tests[n].timepassed)..' seconds',comment)
    self.tests[n] = nil
    self.current = nil
end

function q:kick(n,comment)
    if self.tests[self.current] then self:stop(self.current,comment) end
    self:start(n)
end

return q