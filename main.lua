_G.__test = require 'core.quicktimer'
__test:start('main')
local tester = require 'testing.tester'

require 'modules'

local systems, entities = {},{}
local world
local drawFilter = tiny.requireAll('isDrawSystem')
local updateFilter = tiny.rejectAny('isDrawSystem')

function love.load()
    systems.logic = require 'systems.logic.logicSystems'
    systems.render = require 'systems.render.renderSystems'
    entities = require 'entities.testingEntities2'

    world = tiny.world(systems.logic.talkingSystem, systems.render.spriteSystem,systems.render.shapeSystem,systems.render.dialogueSystem)
    for _,e in pairs(entities) do
        tiny.addEntity(world,e)
    end
    --tester:run('fonts')
end


function love.update(dt)
    tester:update(dt)
    world:update(dt,updateFilter)
end


function love.draw()
    tester:draw()
    world:update(0,drawFilter)
end

__test:stop('main', 'first cycle complete')