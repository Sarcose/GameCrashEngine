--includes
local game = require("test.luis_test.testgames.gamebase")
local bump = require("lib.bump")
local flux = require("lib.flux")
local tiny = require("lib.tiny")

--establish globals

--establish locals
-- Locals from gamebase (assumes you've exposed these if needed)
local bumpWorld = game.bumpWorld or error("Expose bumpWorld from gamebase")
local world = game.world or error("Expose world from gamebase")
-- CONFIG
local OBSTACLE_SPAWN_TIME = 1.5
local ENEMY_SPAWN_TIME = 3.0
local SCREEN_WIDTH, SCREEN_HEIGHT = love.graphics.getDimensions()
-- Obstacle spawner timer
local obstacleTimer = 0
local enemyTimer = 0


--local functions

--[[Spawning]]
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


-- Player hurt hook
local function hurt()
    print("[DEBUG] Player hurt!")
end
local playerBulletCooldown = 0
local function firePlayerBullet(player)
    local bx = player.position.x + (player.w / 2)
    local by = player.position.y
    local bullet = {
        position = {x = bx - 1, y = by},
        velocity = {x = 0, y = -400},
        w = 2, h = 8,
        drawable = true,
        collision = true,
        playerBullet = true,
        draw = function(self)
            love.graphics.setColor(0, 1, 1)
            love.graphics.line(self.position.x, self.position.y, self.position.x, self.position.y + self.h)
        end
    }
    world:addEntity(bullet)
end
-- ENEMY BULLETS
local function fireEnemyBullet(enemy)
    local ex = enemy.position.x
    local ey = enemy.position.y + (enemy.h / 2)

    local angle = math.rad(love.math.random(160, 200)) -- roughly forward cone
    local speed = 100

    local bullet = {
        position = {x = ex, y = ey},
        velocity = {
            x = math.cos(angle) * speed,
            y = math.sin(angle) * speed
        },
        w = 6, h = 6,
        drawable = true,
        enemyBullet = true,
        collision = true,
        draw = function(self)
            love.graphics.setColor(1, 0.3, 0.3)
            love.graphics.circle("fill", self.position.x, self.position.y, 3)
        end
    }

    world:addEntity(bullet)
end


--Systems
--[[BulletSystem]]
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
--[[CullingSystem]]
local DespawnSystem = tiny.processingSystem()
DespawnSystem.filter = tiny.requireAll("position")

function DespawnSystem:process(e, dt)
    if e.position.x + (e.w or 0) < -100 then
        bumpWorld:remove(e)
        world:removeEntity(e)
    end
end

--[[Hurt System]]
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

--[[Bullet Collision System]]
local BulletCollisionSystem = tiny.system()
BulletCollisionSystem.filter = tiny.requireAll("position")

function BulletCollisionSystem:update(dt)
    for _, bullet in ipairs(self.entities) do
        -- Only consider bullets (player or enemy)
        if bullet.playerBullet or bullet.enemyBullet then
            local items = bumpWorld:queryRect(bullet.position.x, bullet.position.y, bullet.w, bullet.h, function(item)
                -- Bullets should not collide with themselves, and only with relevant targets
                if bullet.playerBullet then
                    -- Player bullets collide with enemies and obstacles
                    return item.enemy or item.obstacle
                elseif bullet.enemyBullet then
                    -- Enemy bullets collide with player
                    return item.isPlayer
                end
                return false
            end)

            if #items > 0 then
                -- For now, just call hurt() for each collision (can be expanded)
                hurt()

                -- Remove the bullet from bumpWorld and ECS world
                bumpWorld:remove(bullet)
                world:removeEntity(bullet)
            end
        end
    end
end



--override tables/variables

--override functions

-- Override HUD
local function drawHUD()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("SHMUP — WASD or Arrows to move, X to shoot", 10, 10)

    local bCount = 0
    for _, e in ipairs(world.entities) do
        if e.playerBullet or e.enemyBullet then bCount = bCount + 1 end
    end
    love.graphics.print("Bullets: " .. bCount, 10, 30)
end

_G.drawHUD = drawHUD

-------[[ Load Override ]]-------
-- Add genre-specific systems
local baseLoad = require('test.luis_test.testgames.gamebase').load
function game.load()
    baseLoad()

    world:addSystem(DespawnSystem)
    world:addSystem(HurtSystem)
    world:addSystem(BulletSystem)
    world:addSystem(BulletCollisionSystem)

end
-------[[ Update Override ]]-------
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
return game
-------[[ Draw Override ]]-------