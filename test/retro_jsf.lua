--[[Class, Controls, tiny (ecs) and core lib.]]
-- Since jsf was originally all programmer art, let's make a game solely using slick and have slick's debug drawing handle the graphics
-- once all the gameplay is figured out, let's replace the draw function

_G.Controls = require 'test.retro_jsf.controller'
_G.slick = require 'lib.slick.slick'

local w, h = 800, 600
local world = slick.newWorld(w,h)
local player ={type = "player"}
local level = {type = "level"}

world:add(player, w / 2, h / 2, slick.newRectangleShape(0, 0, 32, 32))
world:add(level, 0, 0, slick.newShapeGroup(
    -- Boxes surrounding the map
    slick.newRectangleShape(0, 0, w, 8), -- top
    slick.newRectangleShape(0, 0, 8, h), -- left
    slick.newRectangleShape(w - 8, 0, 8, h), -- right
    slick.newRectangleShape(0, h - 8, w, 8), -- bottom
    -- Triangles in corners
    slick.newPolygonShape({ 8, h - h / 8, w / 4, h - 8, 8, h - 8 }),
    slick.newPolygonShape({ w - w / 4, h, w - 8, h / 2, w - 8, h }),
    -- Convex shape
    slick.newPolygonMeshShape({ w / 2 + w / 4, h / 4, w / 2 + w / 4 + w / 8, h / 4 + h / 8, w / 2 + w / 4, h / 4 + h / 4, w / 2 + w / 4 + w / 16, h / 4 + h / 8 })
))


local jsf = {}


function jsf:load()

end

function jsf:update(dt)

end

function jsf:draw()
    slick.drawWorld(world)

end

return jsf