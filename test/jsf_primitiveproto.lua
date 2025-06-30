--local draws = require 'test.jsfproto.draws' 
local protodraws = require 'test.jsfproto.protodraws'
local ents = require 'test.jsfproto.ents'
local map = require 'test.jsfproto.map'
local world = require 'test.jsfproto.world'

local jsf = {}

_c_todo{"06/22/2025","The testing area is based out of jsfprototype.lua","protodraws is the messy function","see notes in jsfprototype for more"}

function jsf:load()
  --  world:load(draws,ents,map)
end


function jsf:update(dt, t)
    if t == 'drawonly' then
        --protodraws:update(dt)
    else
    --    world:update(dt)
    end
end


function jsf:draw(t)
    if t == 'drawonly' then
    --    protodraws:drawAllShapes()
    else
    --    world:draw()
    end
end

return jsf

--[[ 06/22/2025
    Some notes;

        The GCE (GameCrash Engine) is meant to provide a universal system for the easy definition and design of 2D platformers with numerous options for featuresets.
        The GCE is being first modeled for the needs that the planned games provide, but I think we run into a problem:
            - One of the planned games, JumpySpaceFight, is planned as a "pseudo3D wireframe" type game. Yet we are not 3D modelling
                Given the premise of the game's art design previously - the use of love.graphics.draw primitives (like rectangle) to build characters,
                we engaged in a foray into the primitive draw system briefly. The goal in mind: remake the draw primitive system so it uses less resources
                To this end, a system of cached meshes was devised, meant to be called upon exactly as lg.rectangle, for instance, is called upon.
                But then we get into: what is a wireframe? What is a character? How are triangles handled best? Should it be able to do nonstandard lines? e.g. spirals.
                The answers to this were nonconclusive, and so the mesh system is something of a dead end. At least for now. Specifically, the "meshes for primitives"
                -- the act of building an entity out of greebles is functionally similar to modelling it in 3D with tris. Building an entity from vertices same.
                So we return to the question of what does this game actually needed?
            A "Wireframe game" evokes the look and concept of early 3D games. Yet I think "Wireframe" is inadequate to describe these games.
            Stellar 7, Space Harrier, Tron, Rez, et. all were "untextured simple model" games. This brings us back to: this is a 3D concept.
            So then we can use a "Shape game" but is that what we want? Why did JSF have shapes as its style? The answer is simple: it was programmer art.
            NOw we've examined it a bit more and determined a kind of existential design philosophy behind this system. This game takes place in a 2D plane
            threatened by "unflattening" and fragmentation. Some of the story beats will be inspired by Flatland. a lot of that is simplistic enough, and it also
            allows for a kind of "model-slice" look to characters. Like everything in the 3rd dimension is a theoretical slice of a 4th dimensional entity, so too
            are most 2D entities wrt the 3rd dimension.
        SO we return to the need of Jumpy Space Fight as regards the 2D engine. I could easily design entities that are simple boxes and designate them in code.
        I could also easily design entities that look like simple shapes but draw them as sprites.
        I think we need something more abstract yet systematic. The whole goal of this project started as a way to test out the new collision system which is like
        bump but allowing for compound and arbitrary shapes.

        So other than a sprite need as most of the games, and rather than attempting to imagine all possible 3-4 line polygons like with mesh, and rather than 
        attempting to write a whole 3D system, we want something for the drawing that is altogether unusual.

]] 