-- topdownrpg.lua
local game = require("test.luis_test.testgames.gamebase")
local bump = require("lib.bump")
local tiny = require("lib.tiny")

local bumpWorld = game.bumpWorld or error("Expose bumpWorld from gamebase")
local world = game.world or error("Expose world from gamebase")

local TILE = 32
local SCREEN_WIDTH, SCREEN_HEIGHT = love.graphics.getDimensions()

-- Generic interaction hook
local function interact(npc)
    print("[DEBUG] Interacted with NPC: " .. (npc.name or "?"))
end

-- HUD override
local function drawHUD()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("TOPDOWN RPG — Arrow keys/WASD to move, Z/Enter to interact", 10, 10)
end

_G.drawHUD = drawHUD

-- Wall system (optional logic system; walls are static)
local function addWall(x, y, w, h)
    local wall = {
        position = {x = x, y = y},
        w = w, h = h,
        drawable = true,
        wall = true,
        draw = function(self)
            love.graphics.setColor(0.5, 0.5, 0.5)
            love.graphics.rectangle("fill", self.position.x, self.position.y, self.w, self.h)
        end
    }
    bumpWorld:add(wall, x, y, w, h)
    world:addEntity(wall)
end

-- NPC system
local function addNPC(x, y, symbol, name)
    local npc = {
        position = {x = x, y = y},
        w = TILE, h = TILE,
        drawable = true,
        npc = true,
        name = name,
        draw = function(self)
            love.graphics.setColor(1, 1, 0)
            love.graphics.print(symbol, x + 8, y + 4)
        end
    }
    bumpWorld:add(npc, x, y, npc.w, npc.h)
    world:addEntity(npc)
end

-- Interaction system
local InteractionSystem = tiny.system()
InteractionSystem.filter = tiny.requireAll("isPlayer", "position")

function InteractionSystem:update(dt)
    local player = self.entities[1]
    if not player then return end

    if love.keyboard.isDown("z") or love.keyboard.isDown("return") then
        local x, y, w, h = player.position.x, player.position.y, player.w, player.h
        local hits = bumpWorld:queryRect(x - 2, y - 2, w + 4, h + 4, function(item)
            return item.npc
        end)

        for _, npc in ipairs(hits) do
            interact(npc)
        end
    end
end

-- Override load
function game.load()
    game.load = nil
    require("gamebase").load()

    -- Modify player speed (optional)
    for _, e in ipairs(world.entities) do
        if e.isPlayer then
            e.speed = 100
        end
    end

    -- Add walls (top, bottom, left, right)
    addWall(0, 0, SCREEN_WIDTH, TILE) -- top
    addWall(0, SCREEN_HEIGHT - TILE, SCREEN_WIDTH, TILE) -- bottom
    addWall(0, 0, TILE, SCREEN_HEIGHT) -- left
    addWall(SCREEN_WIDTH - TILE, 0, TILE, SCREEN_HEIGHT) -- right

    -- Add some inner walls
    addWall(5 * TILE, 5 * TILE, 3 * TILE, TILE)
    addWall(8 * TILE, 3 * TILE, TILE, 3 * TILE)

    -- Add NPCs
    addNPC(6 * TILE, 3 * TILE, "A", "Alice")
    addNPC(9 * TILE, 6 * TILE, "B", "Bob")

    -- Add interaction system
    world:addSystem(InteractionSystem)
end

return game

--[[
function love.load()
    require("topdownrpg").load()
end

function love.update(dt)
    require("topdownrpg").update(dt)
end

function love.draw()
    require("topdownrpg").draw(dt)
end

function love.keypressed(key)
    require("topdownrpg").keypressed(key)
end

]]