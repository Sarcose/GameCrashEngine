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
    local obj = gcore.table.deepcopy(entityDefaults)
    gcore.table.merge(obj, prop, true)
end
--[[

local e = {
    humie = entity(),
    mushkid = entity(),
    rabball = entity(),
    speye = entity(),
}
--]]

local entities = {}

__test:stop('testingEntities2')
return entities
