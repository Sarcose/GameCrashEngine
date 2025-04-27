local classic = require("lib.classic")
local tiny = require("lib.tiny")

local GameWorld = classic:extend()
--        --require("systems.debug")
--        --require("systems.movement"),
function GameWorld:new()    --#TODO: establish a *correct* paradigm of instantiation!
    local obj = {
        ecs =   tiny.world(
            
        require("systems.collision"),
        require("systems.render")

        ),
        root_space = require("assets.maps.test_map").load()
    }
    return setmetatable(obj, self)
end

function GameWorld:update(dt)
    self.ecs:update(dt)
end

function GameWorld:draw()
end

return GameWorld