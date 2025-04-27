local classic = require("lib.classic") --#TODO: classic

local Player = classic:extend()

function Player:new(space, x, y)
    self.entity = {
        x = x, y = y, w = 32, h = 32,
        velocity = {x = 0, y = 0},
        sprite = love.graphics.newImage("assets/sprites/player.png"),
        space = space,
        isPlayer = true
    }
    space:addEntity(self.entity)
end

return Player