local classic = require 'lib.classic'
local entity = classic:extend()
local entityDefaults = {
    name = "unnamed",
    pos = {x = 100, y = 100},
    dims = {w = 30, h = 30},
    texture = {

    }
}
entityDefaults.__copy = gcore.table.__deepcopy

local function randomPos()
    return {x = love.math.random(100,300), y = love.math.random(100,300)}
end
function entity:new(prop)
    if type(prop) ~= "table" then prop = entityDefaults:__copy() end
    local obj = entityDefaults:__copy()
    gcore.table.merge(obj, prop, true)
    return obj
end
setmetatable(entity, {
    __call = function(cls, prop)
        return cls:new(prop)
    end
})

local e = {
    humie = entity{name="humie",texture = {sheet = lg.newImage("assets/humie.png")},pos=randomPos()},
    mushkid = entity{name="mushkid",texture = {sheet = lg.newImage("assets/mushkid.png")},pos=randomPos()},
    rabball = entity{name="rabball",texture = {sheet = lg.newImage("assets/rabball.png")},pos=randomPos()},
    speye = entity{name="speye",texture = {sheet = lg.newImage("assets/speye.png")},pos=randomPos()},
}

return e
