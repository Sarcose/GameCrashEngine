_G.tiny = require 'lib.tiny'

local systems, entities = {},{}
local world
local drawFilter = tiny.requireAll('isDrawSystem')
local updateFilter = tiny.rejectAny('isDrawSystem')
gamefont = love.graphics.newFont()
function love.load()
    systems.logic = require 'systems.logic.logicSystems'
    systems.render = require 'systems.render.renderSystems'
    entities = require 'entities.testingEntities'

    world = tiny.world(systems.logic.talkingSystem, systems.render.spriteSystem,systems.render.shapeSystem,systems.render.dialogueSystem)
    for _,e in ipairs(entities) do
        tiny.addEntity(world,e)
    end

end

local test = 0
_G.gDT = 0
function love.update(dt)
    world:update(dt,updateFilter)
end


function love.draw()
    world:update(0,drawFilter)
end