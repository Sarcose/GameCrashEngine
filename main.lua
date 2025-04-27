_G.tiny = require 'lib.tiny'

local systems, entities = {},{}
local world
local font = love.graphics.newFont()
function love.load()
    systems.logic = require 'systems.logic.logicSystems'
    systems.render = require 'systems.render.renderSystems'
    entities = require 'entities.testingEntities'

    world = tiny.world(systems.logic.talkingSystem, systems.render.spriteSystem,systems.render.shapeSystem,systems.render.dialogueSystem)

end

function love.update(dt)
    world:update(dt)
end


function love.draw()
    world:update(0)
end