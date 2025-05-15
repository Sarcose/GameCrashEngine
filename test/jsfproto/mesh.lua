-- WireMesh.lua
local WireMesh = {}
WireMesh.__index = WireMesh

-- Utility: Apply 2D rotation
local function rotate(x, y, angle)
    local cos, sin = math.cos(angle), math.sin(angle)
    return x * cos - y * sin, x * sin + y * cos
end

-- Create a new WireMesh system
function WireMesh.new(maxVerts, usage)
    local self = setmetatable({}, WireMesh)
    self.parts = {}
    self.mesh = love.graphics.newMesh({
        {"VertexPosition", "float", 2}
    }, maxVerts or 4096, usage or "dynamic", "line")
    self.dirty = true
    return self
end

-- Create a new part
function WireMesh:addPart(name)
    self.parts[name] = {
        verts = {},
        visible = true,
        transform = {x = 0, y = 0, rot = 0, sx = 1, sy = 1}
    }
end

-- Set visibility
function WireMesh:setVisible(name, visible)
    if self.parts[name] then
        self.parts[name].visible = visible
        self.dirty = true
    end
end

-- Set part transform
function WireMesh:setTransform(name, x, y, rot, sx, sy)
    local t = self.parts[name].transform
    t.x, t.y = x or t.x, y or t.y
    t.rot = rot or t.rot
    t.sx, t.sy = sx or t.sx, sy or t.sy
    self.dirty = true
end

-- Clear part's geometry
function WireMesh:clearPart(name)
    if self.parts[name] then
        self.parts[name].verts = {}
        self.dirty = true
    end
end

-- Add a line to a part
function WireMesh:addLine(name, x1, y1, x2, y2)
    local part = self.parts[name]
    if part then
        table.insert(part.verts, {x1, y1})
        table.insert(part.verts, {x2, y2})
        self.dirty = true
    end
end

-- Add rectangle to a part
function WireMesh:addRect(name, x, y, w, h)
    self:addLine(name, x, y, x + w, y)
    self:addLine(name, x + w, y, x + w, y + h)
    self:addLine(name, x + w, y + h, x, y + h)
    self:addLine(name, x, y + h, x, y)
end

-- Add circle to a part
function WireMesh:addCircle(name, cx, cy, r, steps)
    local step = (2 * math.pi) / (steps or 32)
    for i = 0, (steps or 32) - 1 do
        local a1 = i * step
        local a2 = (i + 1) * step
        self:addLine(name,
            cx + math.cos(a1) * r, cy + math.sin(a1) * r,
            cx + math.cos(a2) * r, cy + math.sin(a2) * r)
    end
end

function WireMesh:addTriangle(name, x, y, size, opts)
    opts = opts or {}
    local t = opts.type or "equilateral"
    local flip = opts.flip and -1 or 1
    local angle = opts.angle or 0
    local sx, sy = 1, flip
    if opts.scale then sx, sy = opts.scale[1], opts.scale[2] * flip end

    local x1, y1, x2, y2, x3, y3

    if t == "equilateral" then
        local h = size * math.sqrt(3) / 2
        x1, y1 = 0, -2 * h / 3
        x2, y2 = -size / 2, h / 3
        x3, y3 = size / 2, h / 3

    elseif t == "isosceles" then
        local h = opts.height or (size * 0.75)
        x1, y1 = 0, -h
        x2, y2 = -size / 2, 0
        x3, y3 = size / 2, 0

    elseif t == "right" then
        x1, y1 = 0, 0
        x2, y2 = size, 0
        x3, y3 = 0, size

    elseif t == "scalene" then
        local b = size
        local h = opts.height or (size * 0.5)
        x1, y1 = -b / 2, 0
        x2, y2 = b / 2, 0
        x3, y3 = opts.offsetX or (b * 0.2), -h
    else
        error("Unknown triangle type: " .. tostring(t))
    end

    -- Rotate & scale if needed
    local function transform(px, py)
        px, py = px * sx, py * sy
        local c, s = math.cos(angle), math.sin(angle)
        return
            x + px * c - py * s,
            y + px * s + py * c
    end

    local tx1, ty1 = transform(x1, y1)
    local tx2, ty2 = transform(x2, y2)
    local tx3, ty3 = transform(x3, y3)

    self:addLine(name, tx1, ty1, tx2, ty2)
    self:addLine(name, tx2, ty2, tx3, ty3)
    self:addLine(name, tx3, ty3, tx1, ty1)
end


-- Rebuild vertex data
function WireMesh:update()
    local allVerts = {}

    for _, part in pairs(self.parts) do
        if part.visible then
            local t = part.transform
            for _, v in ipairs(part.verts) do
                -- Apply scale, then rotate, then translate
                local x = v[1] * t.sx
                local y = v[2] * t.sy
                x, y = rotate(x, y, t.rot)
                x = x + t.x
                y = y + t.y
                table.insert(allVerts, {x, y})
            end
        end
    end

    self.mesh:setVertices(allVerts)
    self.dirty = false
end

-- Draw the mesh
function WireMesh:draw()
    if self.dirty then self:update() end
    love.graphics.draw(self.mesh)
end

return WireMesh
