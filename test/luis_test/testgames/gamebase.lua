-- gamebase.lua
-- Core game loop boilerplate for multi-genre support

local baton = require("lib.baton")
local bump = require("lib.bump")
local Class = require("lib.classic")
local tiny = require("lib.tiny")
local flux = require("lib.flux")
local batteries = require("lib.batteries"):export()

-- ECS systems
local world = tiny.world()

-- Collision world
local bumpWorld = bump.newWorld(64)

-- Input profile
local input = baton.new({
    controls = {
        left = {'key:left', 'key:a'},
        right = {'key:right', 'key:d'},
        up = {'key:up', 'key:w'},
        down = {'key:down', 'key:s'},
        jump = {'key:space'},
        shoot = {'key:x', 'key:ctrl'},
        action = {'key:z', 'key:return'},
        pause = {'key:escape'}
    },
    pairs = {
        moveX = {'left', 'right'},
        moveY = {'up', 'down'}
    }
})

-- Base Entity class
local Entity = Class:extend()

function Entity:new(x, y, w, h)
    self.x, self.y, self.w, self.h = x or 0, y or 0, w or 16, h or 16
    self.remove = false
end

function Entity:draw()
    -- Override in child
end

function Entity:update(dt)
    -- Override in child
end

-- Base System: Input movement (optional for ECS-based movement)
local MovementSystem = tiny.processingSystem()
MovementSystem.filter = tiny.requireAll("position", "velocity", "isPlayer")

function MovementSystem:process(e, dt)
    local mx = input:get("moveX")
    local my = input:get("moveY")

    e.velocity.x = mx * (e.speed or 100)
    e.velocity.y = my * (e.speed or 100)
end

-- Base System: Apply velocity to position
local PhysicsSystem = tiny.processingSystem()
PhysicsSystem.filter = tiny.requireAll("position", "velocity")

function PhysicsSystem:process(e, dt)
    e.position.x = e.position.x + e.velocity.x * dt
    e.position.y = e.position.y + e.velocity.y * dt
end

-- Base System: Bump collision system
local CollisionSystem = tiny.system()
CollisionSystem.filter = tiny.requireAll("collision")

function CollisionSystem:update(dt)
    for _, e in ipairs(self.entities) do
        local goalX = e.position.x + e.velocity.x * dt
        local goalY = e.position.y + e.velocity.y * dt

        local actualX, actualY, cols, len = bumpWorld:move(e, goalX, goalY)
        e.position.x, e.position.y = actualX, actualY
        e.collisions = cols
    end
end

-- Base System: Render system
local RenderSystem = tiny.processingSystem()
RenderSystem.filter = tiny.requireAll("position", "drawable")

function RenderSystem:process(e, dt)
    love.graphics.setColor(1, 1, 1)
    if e.draw then
        e:draw()
    else
        love.graphics.rectangle("line", e.position.x, e.position.y, e.w or 16, e.h or 16)
    end
end

-- HUD draw hook
local function drawHUD()
    -- Override or extend in your genre implementations
end

-- Game Setup
local game = {}

function game.load()
    -- Add systems to ECS world
    world:addSystem(MovementSystem)
    world:addSystem(PhysicsSystem)
    world:addSystem(CollisionSystem)
    world:addSystem(RenderSystem)

    -- Example player entity
    local player = {
        position = {x = 100, y = 100},
        velocity = {x = 0, y = 0},
        speed = 120,
        isPlayer = true,
        collision = true,
        drawable = true,
        w = 16, h = 16,
        draw = function(self)
            love.graphics.setColor(0, 1, 1)
            love.graphics.rectangle("fill", self.position.x, self.position.y, self.w, self.h)
        end
    }

    bumpWorld:add(player, player.position.x, player.position.y, player.w, player.h)
    world:addEntity(player)
end

function game.update(dt)
    input:update()
    flux.update(dt)
    world:update(dt)
end

function game.draw()
    world:draw()
    drawHUD()
end

function game.keypressed(key)
    if key == "escape" then love.event.quit() end
end

return game
