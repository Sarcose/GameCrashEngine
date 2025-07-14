--[[
This is the second refactor for gamebase.lua. The intent is for
    gamebase -> establish all basic concepts
        input
        physics_world
        ecsWorld
        flux
]]

local baton = require("lib.baton")
local bump = require("lib.bump")
local Class = require("lib.classic")
local tiny = require("lib.tiny")
local flux = require("lib.flux")
local batteries = require("lib.batteries"):export()


SCREEN_WIDTH, SCREEN_HEIGHT = love.graphics.getDimensions()



---Holding Container---
local totalEntities = {
    physicsQueue = {},
    ecsQueue = {},
    entitiesRef = {
        add = function(self,o)
            self[o._ref] = o
            self[#self+1] = o
            o.__index = #self
        end,
        remove = function(self,o)


        end,
    },
    queuedAmount = 0,
    update = function(self,dt)
        for _,v in ipairs(self.entitiesRef) do
            if v.update then v:update(dt) end
        end
    end,
    name = function(self,obj)
        local _name = obj._name or obj._type or "entity"
        if self.entitiesRef[_name] then _name = _name.."__"..tostring(#self.entitiesRef) end
        return _name
    end,
    set = function(self, physics_world, ecs_world)
        if physics_world then self.physics_world = physics_world end
        if ecs_world then self.ecs_world = ecs_world end
    end,
    add = function(self, obj, t)
        t = t or "physicsECS"
        obj._ref = self:name(obj)
        if t:find("physics") then
            table.insert(self.physicsQueue, obj)
        end
        if t:find("ECS") then
            table.insert(self.ecsQueue,obj)
        end
        self.queuedAmount = self.queuedAmount + 1
    end,
    process = function(self)
        for _,o in ipairs(self.physicsQueue) do
            self.physics_world:add(o, o.position.x, o.position.y, o.shape.w, o.shape.h)
            self.entitiesRef:add(o)
        end
        for _,o in ipairs(self.ecsQueue) do
            self.ecs_world:add(o)
            self.entitiesRef:add(o)
        end
        self.ecsQueue = {}
        self.physicsQueue = {}
        self.queuedAmount = 0
    end,
    remove = function(self, obj)
        local ref = obj._ref
        self.physics_world:remove(obj)
        tiny.removeEntity(self.ecs_world, obj)
    end,
    refresh = function(self, obj)
        if self.physics_world:hasItem(obj) then 
            self.physics_world:remove(obj)
            self.physics_world:add(obj, obj.position.x, obj.position.y, obj.shape.w, obj.shape.h)
        end
        self.ecs_world:remove(obj)
        self.ecs_world:add(obj)
    end
}
---


_G.input = baton.new({
        controls = {
            left = {'key:left', 'key:a'},
            right = {'key:right', 'key:d'},
            up = {'key:up', 'key:w'},
            down = {'key:down', 'key:s'},
            jump = {'key:space'},
            shoot = {'key:x', 'key:lctrl','key:rctrl'},
            action = {'key:z', 'key:return'},
            pause = {'key:escape'}
        },
        pairs = {
            move = {'left', 'right', 'up', 'down',}
        }
    })
--[[ Base Entity class  ]]
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



--Systems

-- Base System: Input movement (optional for ECS-based movement)
local MovementSystem = tiny.processingSystem()
MovementSystem.filter = tiny.requireAll("position", "velocity", "isPlayer", "floating")

function MovementSystem:process(e, dt)
    local mx, my = input:get("move")

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
local CollisionSystem = tiny.processingSystem()
CollisionSystem.filter = tiny.requireAll("collision")

function CollisionSystem:process(e, dt)
    local physics_world = self.world.physics_world
    for _, e in ipairs(self.entities) do
        local goalX = e.position.x + e.velocity.x * dt
        local goalY = e.position.y + e.velocity.y * dt

        local actualX, actualY, cols, len = physics_world:move(e, goalX, goalY, e.filter)
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
        local w, h = e.w, e.h
        if e.shape then w,h = e.shape.w, e.shape.h end
        love.graphics.rectangle("line", e.position.x, e.position.y, w or 16, h or 16)
    end
end

local game = {
    ecs_world = tiny.world(),
    physics_world = bump.newWorld(64),
    flux = flux,
    formula = {
        load = function() end,
        update = function() end,
        draw = function() end,
    },
    drawHUD = function(self) end,
}
game.ecs_world.physics_world = game.physics_world
totalEntities:set(game.physics_world, game.ecs_world)

game.totalEntities = totalEntities
function game:load(formula)
    if formula then
        if type(formula) == "table" then
            self.formula.load = formula.load or self.formula.load
            self.formula.update = formula.update or self.formula.update
            self.formula.draw = formula.draw or self.formula.draw
            self.drawHUD = formula.drawHUD or self.drawHUD
        end
    end

    local ecs_world = self.ecs_world
    local physics_world = self.physics_world
    -- Add systems to ECS world
    ecs_world:addSystem(MovementSystem)
    ecs_world:addSystem(PhysicsSystem)
    ecs_world:addSystem(CollisionSystem)
    ecs_world:addSystem(RenderSystem)

    -- Example player entity
    local player = {
        _name = "player",
        position = {x = 100, y = 100},
        velocity = {x = 0, y = 0},
        shape = {w = 16, h = 16},   --later: add a shape type with its own draw.
        speed = 120,
        collisionType = "entity",
        isPlayer = true,
        isCreature = true,
        collision = true,
        floating = true,
        drawable = true,
        iframes = 0,
        update = function(self,dt)
            if self.iframes > 0 then self.iframes = self.iframes - dt end
        end,
        draw = function(self)
            local t = 1
            if self.iframes > 0 then
                local visible = (GAMETIME % FLASHINTERVALS.iframes) < (FLASHINTERVALS.iframes / 2)
                if not visible then t = 0 end
            end

            love.graphics.setColor(0, 1, 1, t)
            love.graphics.rectangle("fill", self.position.x, self.position.y, self.shape.w, self.shape.h)
        end,
        filter = function(item, other)
            if     other.collisionType == "entity"  then return 'cross'
            elseif other.collisionType == "solid"   then return 'slide'
            end
        end,
        pain = function(self)
            if self.iframes <= 0 then
                self.iframes = 1
                print("[DEBUG] Player hurt!")
            end
        end,
        damage = function(self)


        end,
    }
    totalEntities:add(player)
    if self.formula and self.formula.load then self.formula:load(self) end
    local players = 0
    totalEntities:process()

end

-------[[ Update ]]-------
function game:update(dt)
    input:update()
    self.flux.update(dt)
    if self.formula and self.formula.update then self.formula:update(self,dt) end
    totalEntities:update(dt)
end

-------[[ Draw ]]-------

function game:draw()
    local dt = love.timer.getDelta()    --tiny handles its draw code in update
    self.ecs_world:update(dt)    --(world is a tiny-ecs world)
    self:drawHUD()
    if self.formula and self.formula.draw then self.formula:draw(self) end
    --if totalEntities.queuedAmount > 0 then totalEntities:process() end
end

return game