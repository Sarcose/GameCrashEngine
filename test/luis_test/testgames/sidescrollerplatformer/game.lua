local bump = require("lib.bump")
local flux = require("lib.flux")
local tiny = require("lib.tiny")

GRAVITY = 400
JUMP_VELOCITY = -200 

---

--local functions
local function hurt(e,src)
    if e.pain then e:pain() end
    if src.damage then src:damage() end
end

local function isOnGround(physics_world, e)
    local checkX, checkY = e.position.x, e.position.y+1
    local actualX, actualY, cols, len = physics_world:check(e, checkX,checkY, e.filter)
    for _,v in ipairs(cols) do
        if v.type == "slide" then return true end
    end
end

local function NPC(x, y, w, h, name)
    return {
        position = {x = x, y = y},
        shape = {w = w, h = h,},
        name = name or "NPC",
        drawable = true,
        npc = true,
        collisionType = "solid",
        draw = function(self)
            love.graphics.setColor(0, 1, 0)
            love.graphics.rectangle("fill", self.position.x, self.position.y, self.shape.w, self.shape.h)
            love.graphics.setColor(1,1,1)
            love.graphics.print(self.name, self.position.x, self.position.y - 16)
        end,
        interact = function(self)
            print("[DEBUG] Interacted with NPC: " .. self.name)
        end
    }
end

--[[Entity factories]]
local function platform(x, y, w, h)
    return {
        position = {x = x, y = y},
        velocity = {x = 0, y = 0},
        shape = {w = w, h = h},
        platform = true,
        drawable = true,
        collisionType = "solid",
        draw = function(self)
            love.graphics.setColor(0.3, 0.3, 0.3)
            love.graphics.rectangle("fill", self.position.x, self.position.y, self.shape.w, self.shape.h)
        end
    }
end

local hurtBoxInc = 3
local function addSpike(x, y)
    return {
        position = {x = x, y = y},
        shape = {w = 20, h = 20},
        hurtbox = {
            position = {x = x + hurtBoxInc, y = y - hurtBoxInc},
            shape = {w = 20 - hurtBoxInc*2, h = 20 - hurtBoxInc*2},
        },
        drawable = true,
        spike = true,
        collisionType = "solid",
        draw = function(self)
            love.graphics.setColor(0.7, 0.3, 0.2)
            love.graphics.polygon("fill", x, y + 20, x + 10, y, x + 20, y + 20)
            if DRAWHURTBOXES then
                local x,y,w,h = self.hurtbox.position.x,self.hurtbox.position.y,self.hurtbox.shape.w,self.hurtbox.shape.h
                love.graphics.setColor(1, 0, 0)
                love.graphics.rectangle("line", x,y,w,h)
            end
        end
    }
end

local function pickup(x, y, letter)
    return {
        position = {x = x, y = y},
        shape = {w = 16, h = 16},
        drawable = true,
        pickup = true,
        symbol = letter,
        collisionType = "entity",
        draw = function(self)
            love.graphics.setColor(1, 1, 0)
            love.graphics.print(self.symbol, self.position.x, self.position.y)
        end
    }
end

local function foe(x, y)
    return {
        position = {x = x, y = y},
        shape = {w = 16, h = 16,},
        hurtbox = {
            position = {x = x + hurtBoxInc, y = y + hurtBoxInc},
            shape = {w = 18 - hurtBoxInc*2, h = 18 - hurtBoxInc*2}
        },
        drawable = true,
        foe = true,
        isCreature = true,
        collisionType = "entity",
        draw = function(self)
            love.graphics.setColor(0.5, 0, 1)
            love.graphics.circle("fill", x + 8, y + 8, 8)
            
            if DRAWHURTBOXES then
                local x,y,w,h = self.hurtbox.position.x,self.hurtbox.position.y,self.hurtbox.shape.w,self.hurtbox.shape.h
                love.graphics.setColor(1, 0, 0)
                love.graphics.rectangle("line", x,y,w,h)
            end
        end
    }
end



--Systems

--[[Gravity]]
local GravitySystem = tiny.processingSystem()
GravitySystem.filter = tiny.requireAll("isCreature", "velocity", "position")

function GravitySystem:process(e, dt)   --for isOnGround to register correctly we actually need to be looking for the bump slide resolution to take place.
    if not isOnGround(self.world.physics_world,e) then
        e.velocity.y = e.velocity.y + GRAVITY * dt
        return
    end
    e.velocity.y = 0
end

--[[Jump]]
local JumpSystem = tiny.processingSystem()
JumpSystem.filter = tiny.requireAll("isPlayer", "velocity", "position")

function JumpSystem:process(e, dt)
    if e.canMove and isOnGround(self.world.physics_world,e) and love.keyboard.isDown("space") then
        e.velocity.y = JUMP_VELOCITY
    end
end

-- Base System: Input movement (optional for ECS-based movement)
local HorizontalMoveSystem = tiny.processingSystem()
HorizontalMoveSystem.filter = tiny.requireAll("position", "velocity", "isPlayer")

function HorizontalMoveSystem:process(e, dt)

    local mx = input:get("move")

    e.velocity.x = mx * (e.speed or 100)
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
local PickupSystem = tiny.processingSystem()
PickupSystem.filter = tiny.requireAll("pickup", "position")

function PickupSystem:process(e, dt)
    local physics_world, ecs_world = self.world.physics_world, self.world
    local items = physics_world:queryRect(e.position.x, e.position.y, e.shape.w, e.shape.h, function(item)
        return item.isPlayer
    end)
    for _, _ in ipairs(items) do
        print("[DEBUG] Collected pickup: " .. (e.symbol or "?"))
        physics_world:remove(e)
        ecs_world:removeEntity(e)
    end
end

--[[Hazard System]]
local HazardSystem = tiny.processingSystem()
HazardSystem.filter = tiny.requireAny("spike", "foe")

function HazardSystem:process(e, dt)
    local physics_world, ecs_world = self.world.physics_world, self.world
    local hurtbox = e.hurtbox or e
    local items = physics_world:queryRect(hurtbox.position.x, hurtbox.position.y, hurtbox.shape.w, hurtbox.shape.h, function(item)
            return item.isPlayer
        end)
    for _, o in ipairs(items) do
        hurt(o,e)
    end
end

--[[Interaction System]]
local InteractionSystem = tiny.processingSystem()
InteractionSystem.filter = tiny.requireAll("isPlayer", "position")

function InteractionSystem:process(e, dt)
    local physics_world, ecs_world = self.world.physics_world, self.world
    local player = self.entities[1]
    if input:pressed("action") then
        local px, py, pw, ph = player.position.x, player.position.y, player.shape.w, player.shape.h

        -- Query for nearby NPCs (within 30 pixels)
        local nearbyNPCs = physics_world:queryRect(px - 30, py - 30, pw + 60, ph + 60, function(item)
            return item.npc
        end)

        for _, npc in ipairs(nearbyNPCs) do
            if npc.interact then
                npc:interact()
            end
        end
    end
end


local game = require("test.luis_test.testgames.gamebase")


local formula = {}
function formula:drawHUD()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("SIDESCROLLER — Arrow keys/WASD to move, Space to jump", 10, 10)
end
local function rpos()
    return math.random(30,SCREEN_WIDTH-30), math.random(SCREEN_HEIGHT-40,(SCREEN_HEIGHT-40)/2)
end
local alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
local function rletter()
    local i = math.random(1,#alphabet)
    return alphabet:sub(i,i)
end
local function rpickup(TE,letter)
    local x,y = rpos()
    TE:add(pickup(x,y,letter or rletter()))
end
function formula:load(base)
    local physics_world, ecs_world = base.physics_world, base.ecs_world
    local TE = game.totalEntities
    -- Add platforms
    TE:add(platform(0, SCREEN_HEIGHT - 40, SCREEN_WIDTH, 40))
    TE:add(platform(200, SCREEN_HEIGHT - 100, 100, 10))
    TE:add(platform(400, SCREEN_HEIGHT - 160, 120, 10))

    -- Add spikes
    TE:add(addSpike(260, SCREEN_HEIGHT - 60))
    TE:add(addSpike(420, SCREEN_HEIGHT - 180))

    -- Add pickups
    rpickup(TE)
    rpickup(TE)
    rpickup(TE)
    rpickup(TE)
    rpickup(TE)
    rpickup(TE)
    rpickup(TE)
    rpickup(TE)

    -- Add foes
    TE:add(foe(300, SCREEN_HEIGHT - 50))
    TE:add(foe(500, SCREEN_HEIGHT - 50))

    ecs_world:addSystem(HorizontalMoveSystem)
    ecs_world:addSystem(GravitySystem)
    ecs_world:addSystem(RespawnSystem)
    ecs_world:addSystem(PickupSystem)
    ecs_world:addSystem(HazardSystem)
    ecs_world:addSystem(JumpSystem)

    -- Player enhancement
    for _, e in ipairs(TE.ecsQueue) do
        if e.isPlayer then
            e.canMove = true
            e.floating = nil
        end
    end
end

game:load(formula)

return game