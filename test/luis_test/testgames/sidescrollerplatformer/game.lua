--includes
local game = require("test.luis_test.testgames.gamebase")
local bump = require("lib.bump")
local flux = require("lib.flux")
local tiny = require("lib.tiny")

--establish globals

--establish locals
local bumpWorld = game.bumpWorld or error("Expose bumpWorld from gamebase")
local world = game.world or error("Expose world from gamebase")


local SCREEN_WIDTH, SCREEN_HEIGHT = love.graphics.getDimensions()
local GRAVITY = 400
local JUMP_VELOCITY = -200

--local functions
local function hurt()
    print("[DEBUG] Player hurt!")
end

local function isOnGround(player)
    local x, y, w, h = player.position.x, player.position.y, player.w, player.h
    local items = bumpWorld:queryRect(x, y + h + 1, w, 2, function(item)
        return item.platform
    end)
    return #items > 0
end

local function addNPC(x, y, w, h, name)
    local npc = {
        position = {x = x, y = y},
        w = w,
        h = h,
        name = name or "NPC",
        drawable = true,
        npc = true,
        draw = function(self)
            love.graphics.setColor(0, 1, 0)
            love.graphics.rectangle("fill", self.position.x, self.position.y, self.w, self.h)
            love.graphics.setColor(1,1,1)
            love.graphics.print(self.name, self.position.x, self.position.y - 16)
        end,
        interact = function(self)
            print("[DEBUG] Interacted with NPC: " .. self.name)
        end
    }
    bumpWorld:add(npc, x, y, w, h)
    world:addEntity(npc)
    return npc
end

--[[Entity factories]]
local function addPlatform(x, y, w, h)
    local plat = {
        position = {x = x, y = y},
        velocity = {x = 0, y = 0},
        w = w, h = h,
        platform = true,
        drawable = true,
        draw = function(self)
            love.graphics.setColor(0.3, 0.3, 0.3)
            love.graphics.rectangle("fill", self.position.x, self.position.y, self.w, self.h)
        end
    }
    bumpWorld:add(plat, x, y, w, h)
    world:addEntity(plat)
end

local function addSpike(x, y)
    local spike = {
        position = {x = x, y = y},
        w = 20, h = 20,
        drawable = true,
        spike = true,
        draw = function(self)
            love.graphics.setColor(1, 0, 0)
            love.graphics.polygon("fill", x, y + 20, x + 10, y, x + 20, y + 20)
        end
    }
    bumpWorld:add(spike, x, y, spike.w, spike.h)
    world:addEntity(spike)
end

local function addPickup(x, y, letter)
    local pickup = {
        position = {x = x, y = y},
        w = 16, h = 16,
        drawable = true,
        pickup = true,
        symbol = letter,
        draw = function(self)
            love.graphics.setColor(1, 1, 0)
            love.graphics.print(self.symbol, x, y)
        end
    }
    bumpWorld:add(pickup, x, y, pickup.w, pickup.h)
    world:addEntity(pickup)
end

local function addFoe(x, y)
    local foe = {
        position = {x = x, y = y},
        w = 16, h = 16,
        drawable = true,
        foe = true,
        draw = function(self)
            love.graphics.setColor(0.5, 0, 1)
            love.graphics.circle("fill", x + 8, y + 8, 8)
        end
    }
    bumpWorld:add(foe, x, y, foe.w, foe.h)
    world:addEntity(foe)
end



--Systems

--[[Gravity]]
local GravitySystem = tiny.processingSystem()
GravitySystem.filter = tiny.requireAll("isPlayer", "velocity", "position")

function GravitySystem:process(e, dt)
    if not isOnGround(e) then
        e.velocity.y = e.velocity.y + GRAVITY * dt
    else
        e.velocity.y = 0
    end
end


--[[Respawn system]]
local RespawnSystem = tiny.processingSystem()
RespawnSystem.filter = tiny.requireAll("isPlayer", "position")

function RespawnSystem:process(e, dt)
    if e.position.y > SCREEN_HEIGHT then
        e.velocity.y = 0
        e.canMove = false
        flux.to(e.position, 1, {x = 100, y = 10}):oncomplete(function()
            e.canMove = true
        end)
    end
end


--[[Pickup system]]
local PickupSystem = tiny.system()
PickupSystem.filter = tiny.requireAll("pickup", "position")

function PickupSystem:update(dt)
    for _, pickup in ipairs(self.entities) do
        local items = bumpWorld:queryRect(pickup.position.x, pickup.position.y, pickup.w, pickup.h, function(item)
            return item.isPlayer
        end)
        for _, _ in ipairs(items) do
            print("[DEBUG] Collected pickup: " .. (pickup.symbol or "?"))
            bumpWorld:remove(pickup)
            world:removeEntity(pickup)
        end
    end
end

--[[Hazard System]]
local HazardSystem = tiny.system()
HazardSystem.filter = tiny.requireAny("spike", "foe")

function HazardSystem:update(dt)
    for _, hazard in ipairs(self.entities) do
        local items = bumpWorld:queryRect(hazard.position.x, hazard.position.y, hazard.w, hazard.h, function(item)
            return item.isPlayer
        end)
        for _, _ in ipairs(items) do
            hurt()
        end
    end
end

--[[Interaction System]]
local InteractionSystem = tiny.system()
InteractionSystem.filter = tiny.requireAll("isPlayer", "position")

function InteractionSystem:update(dt)
    local player = self.entities[1]
    if not player then return end

    local keys = {"z", "e", "return"}

    for _, key in ipairs(keys) do
        if love.keyboard.wasPressed and love.keyboard.wasPressed(key) then
            local px, py, pw, ph = player.position.x, player.position.y, player.w, player.h

            -- Query for nearby NPCs (within 30 pixels)
            local nearbyNPCs = bumpWorld:queryRect(px - 30, py - 30, pw + 60, ph + 60, function(item)
                return item.npc
            end)

            for _, npc in ipairs(nearbyNPCs) do
                if npc.interact then
                    npc:interact()
                end
            end
        end
    end
end



--override tables/variables

--override functions


-- HUD override
local function drawHUD()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("SIDESCROLLER — Arrow keys/WASD to move, Space to jump", 10, 10)
end

_G.drawHUD = drawHUD

-------[[ Load Override ]]-------
function game.load()
    game.load = nil
    require("gamebase").load()  --run old load then run new load

    -- Player enhancement
    for _, e in ipairs(world.entities) do
        if e.isPlayer then
            e.canMove = true
        end
    end

    -- Add platforms
    addPlatform(0, SCREEN_HEIGHT - 40, SCREEN_WIDTH, 40)
    addPlatform(200, SCREEN_HEIGHT - 100, 100, 10)
    addPlatform(400, SCREEN_HEIGHT - 160, 120, 10)

    -- Add spikes
    addSpike(260, SCREEN_HEIGHT - 60)
    addSpike(420, SCREEN_HEIGHT - 180)

    -- Add pickups
    addPickup(210, SCREEN_HEIGHT - 120, "A")
    addPickup(430, SCREEN_HEIGHT - 200, "B")

    -- Add foes
    addFoe(300, SCREEN_HEIGHT - 50)
    addFoe(500, SCREEN_HEIGHT - 50)

    world:addSystem(GravitySystem)
    world:addSystem(RespawnSystem)
    world:addSystem(PickupSystem)
    world:addSystem(HazardSystem)
end

-------[[ Update Override ]]-------
--[[Platformer input with jump]]
local oldUpdate = game.update
local interactKeys = { "z", "e", "return" }
function game.update(dt)
    oldUpdate(dt)

    local player = nil
    for _, e in ipairs(world.entities) do
        if e.isPlayer then player = e break end
    end
    if player and player.canMove and isOnGround(player) and love.keyboard.isDown("space") then
        player.velocity.y = JUMP_VELOCITY
    end
    -- Call this inside your update(dt) function, after player movement updates



    for _, key in ipairs(interactKeys) do
        if love.keyboard.wasPressed and love.keyboard.wasPressed[key] then
            local player = nil
            for _, e in ipairs(world.entities) do
                if e.isPlayer then player = e; break end
            end
            if player then
                local px, py, pw, ph = player.position.x, player.position.y, player.w, player.h
                local nearbyNPCs = bumpWorld:queryRect(px - 30, py - 30, pw + 60, ph + 60, function(item)
                    return item.npc and item.interact
                end)
                for _, npc in ipairs(nearbyNPCs) do
                    npc:interact()
                end
            end
        end
    end
end

return game