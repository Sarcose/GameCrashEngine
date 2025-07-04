-- camera.lua
local camera = {}

camera.x = 0
camera.y = 0
camera.scale = 1
camera.smooth = 0.1

-- Screen dimensions
local screenWidth, screenHeight = love.graphics.getDimensions()

-- Target to follow (e.g., player)
camera.target = nil

function camera.setTarget(target)
    camera.target = target
end

function camera.update(dt)
    if not camera.target or not camera.target.position then return end

    local tx, ty = camera.target.position.x, camera.target.position.y

    -- Center the camera on the target with smoothing
    local desiredX = tx - screenWidth / 2
    local desiredY = ty - screenHeight / 2

    camera.x = camera.x + (desiredX - camera.x) * math.min(camera.smooth * dt * 60, 1)
    camera.y = camera.y + (desiredY - camera.y) * math.min(camera.smooth * dt * 60, 1)
end

function camera.attach()
    love.graphics.push()
    love.graphics.scale(camera.scale)
    love.graphics.translate(-math.floor(camera.x), -math.floor(camera.y))
end

function camera.detach()
    love.graphics.pop()
end

function camera.getView()
    return {
        x = camera.x,
        y = camera.y,
        w = screenWidth / camera.scale,
        h = screenHeight / camera.scale
    }
end

return camera



--[[
implementing:

local camera = require("camera")
function game.load()
    -- After loading gamebase:
    local player = nil
    for _, e in ipairs(world.entities) do
        if e.isPlayer then
            player = e
            break
        end
    end
    if player then
        camera.setTarget(player)
    end
end

function game.draw()
    camera.attach()
    world:draw()         -- ECS render system
    camera.detach()

    drawHUD()            -- HUD stays screen-space
end

function game.update(dt)
    input:update()
    flux.update(dt)
    world:update(dt)

    camera.update(dt)
end
]]