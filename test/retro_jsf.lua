--[[Class, Controls, tiny (ecs) and core lib.]]
-- Since jsf was originally all programmer art, let's make a game solely using slick and have slick's debug drawing handle the graphics
-- once all the gameplay is figured out, let's replace the draw function

--_G.Controls = require 'test.retro_jsf.controller'
_G.slick = require 'lib.slick.slick'
local designer = require 'design.designer'

local w, h = 800, 600
local world = slick.newWorld(w,h)
local player ={type = "player"}
local level = {type = "whatever"}

world:add(player, w / 2, h / 2, slick.newRectangleShape(0, 0, 32, 32))

local testlevel = {
    {"newRectangleShape",{0,0,w,8}},{"newRectangleShape",{0,0,8,h}},{"newRectangleShape",{w-8,0,8,h}},{"newRectangleShape",{0,h-8,w,8}},
    {"newPolygonShape",{{ 8, h - h / 8, w / 4, h - 8, 8, h - 8 }}},
    {"newPolygonShape",{{ w - w / 4, h, w - 8, h / 2, w - 8, h }}},
    {"newPolygonMeshShape",{{ w / 2 + w / 4, h / 4, w / 2 + w / 4 + w / 8, h / 4 + h / 8, w / 2 + w / 4, h / 4 + h / 4, w / 2 + w / 4 + w / 16, h / 4 + h / 8 }}}
}
local function interpretshape(s)
    local shape = s[1]
    return slick[shape](unpack(s[2]))
end

for i=1, #testlevel do
    testlevel[i] = interpretshape(testlevel[i])

end

world:add(level, 0, 0, slick.newShapeGroup(unpack(testlevel)))




local jsf = {}


function jsf:load()
    designer:configure{world = world}

end

function jsf:update(dt)

end

function jsf:draw()
    slick.drawWorld(world)

end

return jsf