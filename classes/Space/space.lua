-- Space.lua
local PhysicsWorld = require("physics.PhysicsWorld")
local TerrainLayer = require("classes.Space.TerrainLayer")

local Space = Class:extend()

function Space:new(parent, name, w, h)
    self.name = name or "Unnamed Space"
    self.parent = parent -- The Spaceplane this Space belongs to

    -- Simulation context for this space
    --self.ecs = ECS.world()  --do we need to frontload systems?    --we're going to skip this for now I think..
    self.physics = PhysicsWorld:new(w,h)
    self.terrain = TerrainLayer(self.physics)

    -- Entities within this space
    self.entities = {}

    -- Portal connections
    self.portals = {}

    -- Optional camera/transform
    self.camera = nil
    self.rotation = 0 -- Space-specific rotation

    -- Love2D canvas for rendering this space
    self.canvas = love.graphics.newCanvas()

    -- Hibernation state
    self.hibernating = false
end

function Space:addEntity(entity)
    table.insert(self.entities, entity)
    --self.ecs:add(entity)
    if entity.init then entity:init(self) end
end

function Space:removeEntity(entity)
    self.ecs:remove(entity)
    for i, e in ipairs(self.entities) do
        if e == entity then
            table.remove(self.entities, i)
            break
        end
    end
end

function Space:update(dt)
    if self.hibernating then return end

    self.ecs:update(dt)
    if self.camera and self.camera.update then
        self.camera:update(dt)
    end

    for _, portal in ipairs(self.portals) do
        portal:check(self)
    end

    self.ecs:update(dt)
end

function Space:draw()
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear()

    if self.camera and self.camera.attach then
        self.camera:attach()
    end

    self.terrain:draw()
    self.ecs:draw()

    if self.camera and self.camera.detach then
        self.camera:detach()
    end

    love.graphics.setCanvas()
end

-- Messaging Functions

function Space:getSiblingSpaces()
    if not self.spaceplane then return {} end
    return self.spaceplane:getSpaces()
end

function Space:getContainedSpaces()
    if not self.spaceplane then return {} end
    return self.spaceplane:getContainedSpacesOf(self)
end

function Space:getParentSpace()
    if not self.spaceplane then return nil end
    return self.spaceplane:getOwnerSpace()
end

return Space

