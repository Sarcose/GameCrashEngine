--[[Class, Controls, tiny (ecs) and core lib.]]
-- Since jsf was originally all programmer art, let's make a game solely using slick and have slick's debug drawing handle the graphics
-- once all the gameplay is figured out, let's replace the draw function

_G.Controls = require 'test.retro_jsf.controller'
_G.Slick = require 'lib.slick.slick'


--[[
    So the structure of the game space is going to be:
        Worlds -> Levels -> "Boards" or Layers and we're using the terrainlayer data struct?
        So before we port in the generated and worked on Obsidian terrainlayer, we need to sort of visualize it here.

        We need a world, then it needs to be a world of worlds, then a world fof worlds with worlds. Then a universe of worlds of worlds of worlds, lol.
        
        Then we need an object type. We first start it out as a simplistic object.

        We need a terrain type. We can move from a table of largest squares to a table of polygons;
        with the recent developments in slick we have navmeshes too. Eventually we'll be able to use those.




]]

local ctx = {   --i like this structure tbh, passing a context throughout the formula...
    object = require 'test.retro_jsf.object',   -- I need to formalize what formulae are even exposed to.
    controller = require 'test.retro_jsf.controller',
    maps = require 'test.retro_jsf.maps'
}


local jsf = {}


function jsf:load()

end

function jsf:update(dt)

end

function jsf:draw()


end

return jsf