-- TerrainLayer.lua

local TerrainLayer = Class:extend()

function TerrainLayer:new(physics)
    self.physics = physics -- Reference to the physics world this terrain belongs to
    self.shapes = {}       -- List of terrain shapes
    self.visuals = {}      -- List of visual representations, e.g. quads or draw calls
end

-- Add a terrain shape to the physics world
function TerrainLayer:addShape(shape)
    table.insert(self.shapes, shape)
    if self.physics and self.physics.add then
        self.physics:add(shape)
    end
end

-- Remove a terrain shape from the physics world
function TerrainLayer:removeShape(shape)
    for i, s in ipairs(self.shapes) do
        if s == shape then
            table.remove(self.shapes, i)
            break
        end
    end
    if self.physics and self.physics.remove then
        self.physics:remove(shape)
    end
end

-- Add a visual terrain element
function TerrainLayer:addVisual(drawFunc)
    table.insert(self.visuals, drawFunc)
end

-- Draw terrain visuals
function TerrainLayer:draw()
    for _, drawFunc in ipairs(self.visuals) do
        drawFunc()
    end
end

-- Optional: query shapes at a point
function TerrainLayer:queryPoint(x, y)
    local results = {}
    for _, shape in ipairs(self.shapes) do
        if shape:containsPoint and shape:containsPoint(x, y) then
            table.insert(results, shape)
        end
    end
    return results
end

return TerrainLayer
