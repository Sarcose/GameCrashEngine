local classic = require 'lib.classic'
__test:start('testingEntities2')
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
    _c_debug(obj)
    return obj
end
setmetatable(entity, {
    __call = function(cls, prop)
        return cls:new(prop)
    end
})

local e = {
    humie = entity{name="humie"},
    mushkid = entity{name="mushkid"},
    rabball = entity{name="rabball"},
    speye = entity{name="speye"},
}


local entities = {}

__test:stop('testingEntities2')
print(e.humie.name)
_c_debug(e)
return entities
