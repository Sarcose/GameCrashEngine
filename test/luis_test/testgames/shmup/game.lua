-- shmup.lua
local game = require("test.luis_test.testgames.gamebase")
local bump = require("lib.bump")
local flux = require("lib.flux")
local tiny = require("lib.tiny")
-- Locals from gamebase (assumes you've exposed these if needed)
local bumpWorld = game.bumpWorld or error("Expose bumpWorld from gamebase")
local world = game.world or error("Expose world from gamebase")

-- CONFIG
local OBSTACLE_SPAWN_TIME = 1.5
local ENEMY_SPAWN_TIME = 3.0
local SCREEN_WIDTH, SCREEN_HEIGHT = love.graphics.getDimensions()

-- Player hurt hook
local function hurt()
    print("[DEBUG] Player hurt!")
end

-- PLAYER BULLETS
local playerBulletCooldown = 0
local function firePlayerBullet(player)
    local bx = player.position.x + (player.w / 2)
    local by = player.position.y
    local bullet = {
        position = {x = bx, y = by},
        velocity = {x = 0, y = -400},
        w = 2, h = 8,
        drawable = true,
        playerBullet = true,
        draw = function(self)
            love.graphics.setColor(0, 1, 1)
            love.graphics.line(self.position.x, self.position.y, self.position.x, self.position.y + self.h)
        end
    }
    world:addEntity(bullet)
end

local BulletSystem = tiny.processingSystem()
BulletSystem.filter = tiny.requireAll("velocity", "position")

function BulletSystem:process(e, dt)
    e.position.x = e.position.x + e.velocity.x * dt
    e.position.y = e.position.y + e.velocity.y * dt

    -- Despawn if off-screen
    if e.position.x < -20 or e.position.x > SCREEN_WIDTH + 20
       or e.position.y < -20 or e.position.y > SCREEN_HEIGHT + 20 then
        world:removeEntity(e)
    end
end
local enemyFireTimer = 0
local function updateEnemyFiring(dt)
    enemyFireTimer = enemyFireTimer - dt
    if enemyFireTimer <= 0 then
        for _, e in ipairs(world.entities) do
            if e.enemy then
                fireEnemyBullet(e)
            end
        end
        enemyFireTimer = 2.0 -- seconds between volleys
    end
end


-- ENEMY BULLETS
local function fireEnemyBullet(enemy)
    local ex, ey = enemy.position.x, enemy.position.y + (enemy.h / 2)



-- Obstacle spawner timer
local obstacleTimer = 0
local enemyTimer = 0

-- Spawning
local function spawnObstacle()
    local h = love.math.random(20, 80)
    local y = love.math.random(0, SCREEN_HEIGHT - h)
    local e = {
        position = {x = SCREEN_WIDTH + 20, y = y},
        velocity = {x = -120, y = 0},
        w = 20, h = h,
        drawable = true,
        obstacle = true,
        draw = function(self)
            love.graphics.setColor(1, 0.5, 0)
            love.graphics.rectangle("fill", self.position.x, self.position.y, self.w, self.h)
        end
    }
    bumpWorld:add(e, e.position.x, e.position.y, e.w, e.h)
    world:addEntity(e)
end

local function spawnEnemy()
    local y = love.math.random(50, SCREEN_HEIGHT - 50)
    local e = {
        position = {x = SCREEN_WIDTH + 30, y = y},
        velocity = {x = -100, y = 0},
        w = 20, h = 20,
        drawable = true,
        collision = true,
        enemy = true,
        draw = function(self)
            love.graphics.setColor(1, 0, 0)
            local x, y = self.position.x, self.position.y
            love.graphics.polygon("fill", x, y + 10, x + 20, y, x + 20, y + 20)
        end
    }
    bumpWorld:add(e, e.position.x, e.position.y, e.w, e.h)
    world:addEntity(e)
end

-- System to destroy entities that go off-screen
local DespawnSystem = tiny.processingSystem()
DespawnSystem.filter = tiny.requireAll("position")

function DespawnSystem:process(e, dt)
    if e.position.x + (e.w or 0) < -100 then
        bumpWorld:remove(e)
        world:removeEntity(e)
    end
end

-- System to check collisions with player
local HurtSystem = tiny.system()
HurtSystem.filter = tiny.requireAll("enemy")

function HurtSystem:update(dt)
    for _, e in ipairs(self.entities) do
        local items, len = bumpWorld:queryRect(
            e.position.x, e.position.y, e.w, e.h,
            function(item)
                return item.isPlayer
            end
        )
        for _, hit in ipairs(items) do
            hurt()
        end
    end
end

-- Override update to include spawning
local oldUpdate = game.update
function game.update(dt)
    oldUpdate(dt)

    -- Update enemy firing
    updateEnemyFiring(dt)

    -- Player shooting
    playerBulletCooldown = playerBulletCooldown - dt
    local player = nil
    for _, e in ipairs(world.entities) do
        if e.isPlayer then
            player = e
            break
        end
    end
    if player and playerBulletCooldown <= 0 and input:down("shoot") then
        firePlayerBullet(player)
        playerBulletCooldown = 0.25
    end



    obstacleTimer = obstacleTimer - dt
    if obstacleTimer <= 0 then
        spawnObstacle()
        obstacleTimer = OBSTACLE_SPAWN_TIME
    end

    enemyTimer = enemyTimer - dt
    if enemyTimer <= 0 then
        spawnEnemy()
        enemyTimer = ENEMY_SPAWN_TIME
    end
end

-- Override HUD
local function drawHUD()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("SHMUP HUD — Use Arrow Keys or WASD", 10, 10)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("SHMUP HUD — WASD to move, X to shoot", 10, 10)
    local bCount = 0
    for _, e in ipairs(world.entities) do
        if e.playerBullet or e.enemyBullet then bCount = bCount + 1 end
    end
    love.graphics.print("Bullets: " .. bCount, 10, 30)
end

_G.drawHUD = drawHUD

-- Add genre-specific systems
function game.load()
    game.load = nil -- prevent double call
    require("gamebase").load()
    world:addSystem(DespawnSystem)
    world:addSystem(HurtSystem)
    world:addSystem(BulletSystem)

end

return game



--[[

function love.load()
    require("shmup").load()
end

function love.update(dt)
    require("shmup").update(dt)
end

function love.draw()
    require("shmup").draw()
end

function love.keypressed(key)
    require("shmup").keypressed(key)
end


]]