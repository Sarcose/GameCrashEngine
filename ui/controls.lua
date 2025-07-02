-- controls.lua
local baton = require "lib.baton"

local Controls = {}
Controls.__index = Controls
local testing = {}
function Controls.new()
    local allKeys = love.keyboard.getScancodeFromKey("z") -- dummy call to force love.keyboard to init keymap
    local keyMap = {}

    -- Loop over all keys from love.keypressed (a-z, 0-9, etc.)
    for i = 1, 255 do
        local k = string.char(i)
        if #k > 0 and pcall(love.keyboard.isDown, k) then
            table.insert(keyMap, k)
        end

    end

    -- Also manually add common keys not caught above
    local extraKeys = {
        "space", "return", "escape", "tab", "backspace",
        "up", "down", "left", "right",
        "lshift", "rshift", "lctrl", "rctrl", "lalt", "ralt",
        "f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9", "f10", "f11", "f12"
    }

    for _, k in ipairs(extraKeys) do
        table.insert(keyMap, k)
    end
    --_c_debug(keyMap)
    local inputBindings = {}
    for _, key in ipairs(keyMap) do
        inputBindings[key] = { "key:"..key }
    end

    local mouse = {        
            mb_left = {'mouse:1'},
            mb_middle = {'mouse:3'},
            mb_right = {'mouse:2'},
            mb_backward = {'mouse:4'},
            mb_forward = {'mouse:5'},
    }
    for k,v in pairs(mouse) do keyMap[k] = v end

    local self = setmetatable({}, Controls)
    self.input = baton.new{
        controls = inputBindings,
        pairs = {},
    }
    testing = keyMap
    self.wheel = {x=0,y=0}
    return self
end


function Controls:update(dt)
    self.input:update(dt)
end

function Controls:down(key)
    return self.input:down(key)
end

function Controls:pressed(key)
    return self.input:pressed(key)
end

function Controls:released(key)
    return self.input:released(key)
end



function Controls:test()
    for i,v in ipairs(testing) do
        if self.input:pressed(v) then print(v.." is pressed!") end
    end
end

return Controls
