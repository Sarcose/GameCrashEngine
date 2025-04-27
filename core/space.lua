local classic = require("lib.classic")
local bump = require("lib.bump")

local Space = classic:extend()

function Space:new(parent, x, y, width, height, zIndex)
    -- Hierarchy
    self.parent = parent or nil  -- Root space if nil
    self.children = {}           -- Nested subspaces
    
    -- Spatial properties
    self.x = x or 0              -- Local position in parent space
    self.y = y or 0
    self.width = width or 800
    self.height = height or 600
    self.zIndex = zIndex or 0    -- Depth sorting
    
    -- Collision
    self.bumpWorld = bump.newWorld(64)  -- Local collision world
    self.entities = {}           -- Entities in THIS space
    
    -- Portals (cross-space transitions)
    self.portals = {}            -- Format: {x,y,w,h, targetSpace, targetX, targetY}
end

--- Entity Management ---

-- Add entity to this space
function Space:addEntity(entity)
    entity.space = self  -- Reference to container space
    table.insert(self.entities, entity)
    self.bumpWorld:add(entity, entity.x, entity.y, entity.w, entity.h)
end

-- Remove entity
function Space:removeEntity(entity)
    for i, e in ipairs(self.entities) do
        if e == entity then
            table.remove(self.entities, i)
            self.bumpWorld:remove(entity)
            break
        end
    end
end

--- Coordinate Systems ---

-- Convert local to global coordinates (recursive)
function Space:toGlobal(localX, localY)
    local globalX, globalY = localX + self.x, localY + self.y
    if self.parent then
        globalX, globalY = self.parent:toGlobal(globalX, globalY)
    end
    return globalX, globalY
end

-- Convert global to local coordinates (recursive)
function Space:toLocal(globalX, globalY)
    local localX, localY = globalX - self.x, globalY - self.y
    if self.parent then
        localX, localY = self.parent:toLocal(localX, localY)
    end
    return localX, localY
end

--- Portal System ---

-- Check if point (x,y) hits a portal in this space
function Space:getPortalAt(x, y)
    for _, portal in ipairs(self.portals) do
        if x >= portal.x and x <= portal.x + portal.w and
           y >= portal.y and y <= portal.y + portal.h then
            return portal
        end
    end
    return nil
end

-- Teleport entity through portal
function Space:transferEntity(entity, portal)
    self:removeEntity(entity)
    portal.targetSpace:addEntity(entity)
    entity.x, entity.y = portal.targetX, portal.targetY
end

--- Recursive Space Management ---

-- Add a child space
function Space:addChild(child)
    table.insert(self.children, child)
    child.parent = self
end

-- Update all entities in this space and children (depth-first)
function Space:update(dt)
    -- Update child spaces first (lower zIndex = "further back")
    table.sort(self.children, function(a,b) return a.zIndex < b.zIndex end)
    for _, child in ipairs(self.children) do
        child:update(dt)
    end
    
    -- Local entity updates would happen via ECS systems
end

-- Draw debug boundaries
function Space:drawDebug()
    local gx, gy = self:toGlobal(0, 0)
    love.graphics.setColor(0.2, 0.8, 0.2, 0.3)
    love.graphics.rectangle("line", gx, gy, self.width, self.height)
    
    -- Draw portals
    love.graphics.setColor(1, 0, 1, 0.5)
    for _, portal in ipairs(self.portals) do
        local px, py = self:toGlobal(portal.x, portal.y)
        love.graphics.rectangle("fill", px, py, portal.w, portal.h)
    end
    
    -- Recursively draw children
    for _, child in ipairs(self.children) do
        child:drawDebug()
    end
end

return Space