local draws = require 'test.jsfproto.draws' 
local ents = require 'test.jsfproto.ents'
local map = require 'test.jsfproto.map'
local world = require 'test.jsfproto.world'

local jsf = {}

_c_todo{"05/10/2025","I think I'm not quite there with Mesh yet. I think we go back to lg.rect etc for now, conceptualize some dudes, and move on to modelling physics next.","Pull jsf_old and grab all the old data from it such as widths and stuff, and then replicate the visuality of it, as well as pulling the original map for basic generation logic and testing."}

function jsf:load()
    world:load(draws,ents,map)
end


function jsf:update(dt, t)
    if t == 'drawonly' then
        draws:update(dt)
    else
        world:update(dt)
    end
end


function jsf:draw(t)
    if t == 'drawonly' then
        draws:drawAllShapes()
    else
        world:draw()
    end
end

return jsf