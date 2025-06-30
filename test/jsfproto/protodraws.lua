--[[
    for optimal drawing of primitives before the use of meshes for batching,
    we first will design a strict syntax

    rectangle
    circle
    square
    triangle
    spiral
    

]]
local function rotatePoint(x, y, angle, ox, oy)
  local s, c = math.sin(angle), math.cos(angle)
  x, y = x - ox, y - oy
  return ox + x * c - y * s, oy + x * s + y * c
end

local function generateTriangle(type,params)
    if type == "points" or not type then
        return {
        params[1], params[2],
        params[3], params[4],
        params[5], params[6],
        }

    elseif type == "equilateral" then
        local cx, cy, size, rotation = unpack(params)
        rotation = rotation or 0
        local h = size * math.sqrt(3) / 2
        local verts = {
        cx, cy - 2/3 * h,
        cx - size / 2, cy + h / 3,
        cx + size / 2, cy + h / 3
        }
        for i = 1, #verts, 2 do
        verts[i], verts[i+1] = rotatePoint(verts[i], verts[i+1], rotation, cx, cy)
        end
        return verts

    elseif type == "isosceles" then
        local cx, cy, base, height, rotation = unpack(params)
        rotation = rotation or 0
        local halfBase = base / 2
        local verts = {
        cx, cy - height / 2,
        cx - halfBase, cy + height / 2,
        cx + halfBase, cy + height / 2
        }
        for i = 1, #verts, 2 do
        verts[i], verts[i+1] = rotatePoint(verts[i], verts[i+1], rotation, cx, cy)
        end
        return verts

    elseif type == "right" then
        local x, y, base, height, orientation = unpack(params)
        orientation = orientation or "bl"
        local a, b, c
        if orientation == "bl" then
        a = {x, y}
        b = {x + base, y}
        c = {x, y - height}
        elseif orientation == "tl" then
        a = {x, y}
        b = {x + base, y}
        c = {x, y + height}
        elseif orientation == "br" then
        a = {x, y}
        b = {x - base, y}
        c = {x, y - height}
        elseif orientation == "tr" then
        a = {x, y}
        b = {x - base, y}
        c = {x, y + height}
        else
        error("Invalid orientation: " .. tostring(orientation))
        end
        return {a[1], a[2], b[1], b[2], c[1], c[2]}
    else
        error("Unknown triangle type: " .. tostring(type))
    end
end
local exampleModifiers = {
    spiral = {
        a = function(t,i)
            return 0.2 * math.sin(t * 2 + i * 0.1) -- base offset pulsates
        end,
        b = function(t,i)
            return 0.2 * math.sin(t * 2 + i * 0.1) -- base offset pulsates
        end
    },
    fractal = {--simple random but smooth displacement
        seed = function(t,i) 
            return math.sin(i * 0.5 + t * 2)
        end,
        modifier = function(t,i) --modifier effects size of displacement
            return 0.1 * math.sin(t + i * 0.25)
        end,
    },
    blob = {
        harmonics = function(t,i) --number of harmonics cycles between 2 and 6 slowly over time
              return 2 + math.floor(2 + math.sin(t * 0.5) * 2)
        end,
        amplitude = function(n,t,i) --each harmonic has a diminishing amplitude
              return 0.15 / n * math.sin(t * 0.7 + n)
        end,
        phase = function(n,t,i) --simulate dynamic wobble 
            return t * n * 0.4 + i * 0.05
        end,
    }
}
local colorStack = {
    {},
}
colorStack[1][1], colorStack[1][2], colorStack[1][3], colorStack[1][4] = lg.getColor()
local function pushColor(color) --push color onto the stack
    local Or, Og, Ob, Oa = lg.getColor()
    table.insert(colorStack,{Or,Og,Ob,Oa})
    lg.setColor(color)
end
_c_todo{"05/14/2025","Working on a quick n dirty protodraws system with pushcolor and popcolor for easy auto-coloring"}
local function popColor(color)  --pop last color. if color is *passed*, then it replaces current color with new color
    local c = colorStack[#colorStack] or {1,1,1,1}
    lg.setColor(c[1],c[2],c[3],c[4])
    colorStack[#colorStack] = nil
    if type(color)=="table" then --optionally, push and change to a new color instead
        pushColor(color)
    end
end


local namedColor = {
    blue = {0, 0, 1},
    red = {1, 0, 0},
    green = {0, 1, 0},
    white = {1, 1, 1},
    cyan = {0, 1, 1},
    magenta = {1, 0, 1},
    yellow = {1, 1, 0},
    orange = {1, 0.5, 0},
    purple = {0.5, 0, 0.5},
    pink = {1, 0.6, 0.8},
    lime = {0.5, 1, 0},
    teal = {0, 0.5, 0.5},
    gray = {0.5, 0.5, 0.5},
    dark_red = {0.5, 0, 0},
}
local color = {}
for k,v in pairs(namedColor) do
    color[k] = v
    color[#color+1] = v
end
setmetatable(color, {
    __call = function(self)
        return self[love.math.random(1, #self)]
    end
})
local determinedColors = {i = 1}

for i=1,100 do
    determinedColors[i] = color()
end
for k,v in pairs(namedColor) do
    determinedColors[k] = v
end
_c_debug(determinedColors)
setmetatable(determinedColors, {
    __call = function(self)
        local c = self[self.i]
        self.i = self.i + 1
        if self.i > #self then self.i = 1 end
        return c
    end
})
function determinedColors:reset()   --use this at the end of protodrawexamples() to keep the list the same every update
    self.i = 1
end
determinedColors.transparent = {0,0,0,0}

local white = {1,1,1}
local black = {0,0,0}
local _segments = 1
local _defaultSegments = 1

--written, example prototypes, slightly tested, all the way tested, implemented
--[ ] [ ] [ ] [ ] [ ]
local messyDrawFunctions = {
    _segments = 0,
    _defaultSegments = 0,
    reset = function(self)
        self._segments = self._defaultSegments
        popColor()
    end,
    face = function(self)   --[ ] [ ] [ ] [ ] [ ]

    end,
    asciisomething = function(self) ----[ ] [ ] [ ] [ ] [ ]

    end,
    --love.graphics.rectangle( mode, x, y, width, height, rx, ry, segments )
    rectangle = function(self,x,y,w,h,rx,ry,bg,fg,lineWidth)--[X] [X] [ ] [ ] [ ]
        local seg = self._segments
        if seg == 0 then seg = nil end
        bg = bg or white
        pushColor(bg)
        lg.rectangle("fill",x,y,w,h,rx,ry,seg)
        if fg then
            lineWidth = lineWidth or 1
            popColor(fg)
            lg.setLineWidth(lineWidth)
            lg.rectangle("line",x,y,w,h,rx,ry,seg)
            lg.setLineWidth(1)
        end
        self:reset()
    end,

    --love.graphics.ellipse( mode, x, y, radiusx, radiusy, segments )   --radiusy is optional, in which case total radius is assumed
    ellipse = function(self,x,y,rx,ry,bg,fg,lineWidth)--[X] [X] [ ] [ ] [ ]
        local seg = self._segments
        if seg == 0 then seg = nil end
        bg = bg or white
        if not ry then rx = rx/2; ry = rx end   --use ellipse for both circles and 
        pushColor(bg)
        lg.ellipse("fill",x,y,rx,ry,seg)
        if fg then
            lineWidth = lineWidth or 1
            popColor(fg)
            lg.setLineWidth(lineWidth)
            lg.ellipse("line",x,y,rx,ry,seg)
            lg.setLineWidth(1)
        end
        self:reset()
    end,
    triangle = function(self,type, bg, fg, lineWidth, ...)--[X] [X] [ ] [ ] [ ]
        bg = bg or white
        pushColor(bg)
        local verts = generateTriangle(type, {...})
        lg.polygon("fill", verts)
        if lineWidth and lineWidth > 0 then
            fg = fg or black
            popColor(fg)
            lg.setLineWidth(lineWidth)
            lg.polygon("line",verts)
            lg.setLineWidth(1)
        end
        popColor()
    end,
    spiral = function(self,t, dx,dy, points, spinRate, aFunc, bFunc, startColor, endColor, gradation)--[X] [X] [ ] [ ]    
        --TODO: apply color gradation to spiral
        --t = current tick, time, dt, or state. spinRate = revolutions per t
        love.graphics.translate(dx,dy)
        aFunc = aFunc or exampleModifiers.spiral.a --optional time/index based modifiers for later complexity
        bFunc = bFunc or exampleModifiers.spiral.b   
        local vertices = {}
        for i = 1, points do
            local theta = (i / points) * 2 * math.pi * spinRate * t
            local a = aFunc(t, i)
            local b = bFunc(t, i)
            local r = a + b * theta
            local x = r * math.cos(theta)
            local y = r * math.sin(theta)
            table.insert(vertices, x)
            table.insert(vertices, y)
        end
        love.graphics.polygon("line", vertices)
        love.graphics.translate(-dx,-dy)
    end,
    fractal = function(self,t, dx,dy, depth, seedFunc, modifierFunc, colorTable)--[X] [X] [ ] [ ] [ ]
        --TODO: apply color table deterministically based on fractal growth. Maybe a gradient like above
        love.graphics.translate(dx,dy)
        seedFunc = seedFunc or exampleModifiers.fractal.seed
        modifierFunc = modifierFunc or exampleModifiers.fractal.modifier
        local function subdivide(points, depthLeft)
            if depthLeft == 0 then return points end
            local newPoints = {}
            for i = 1, #points - 2, 2 do
            local x1, y1 = points[i], points[i+1]
            local x2, y2 = points[i+2], points[i+3]
            local mx, my = (x1 + x2)/2, (y1 + y2)/2
            local offset = seedFunc(t, i) * modifierFunc(t, i)
            local dx, dy = y2 - y1, x1 - x2
            local length = math.sqrt(dx*dx + dy*dy)
            dx, dy = dx / length, dy / length
            mx, my = mx + dx * offset, my + dy * offset
            table.insert(newPoints, x1)
            table.insert(newPoints, y1)
            table.insert(newPoints, mx)
            table.insert(newPoints, my)
            end
            table.insert(newPoints, points[#points - 1])
            table.insert(newPoints, points[#points])
            return subdivide(newPoints, depthLeft - 1)
        end

        -- Start with a circle
        local base = {}
        local points = 30
        for i = 1, points do
            local theta = (i / points) * 2 * math.pi
            table.insert(base, math.cos(theta))
            table.insert(base, math.sin(theta))
        end
        local verts = subdivide(base, depth)
        love.graphics.polygon("line", verts)
        love.graphics.translate(-dx,-dy)
    end,
    blob = function(self,t, dx,dy, points, harmonicsFunc, amplitudeFunc, phaseFunc, fg, bg, lineWidth)--[X] [ ] [ ] [ ] [ ]
        --TODO: add outline and coloration
        love.graphics.translate(dx,dy)
        harmonicsFunc = harmonicsFunc or exampleModifiers.blob.harmonics
        amplitudeFunc = amplitudeFunc or exampleModifiers.blob.amplitude
        phaseFunc = phaseFunc or exampleModifiers.blob.phase
        local vertices = {}
        for i = 1, points do
            local theta = (i / points) * 2 * math.pi
            local r = 1
            for n = 1, harmonicsFunc(t, i) do
            local amp = amplitudeFunc(n, t, i)
            local phase = phaseFunc(n, t, i)
            r = r + amp * math.sin(n * theta + phase)
            end
            local x = r * math.cos(theta)
            local y = r * math.sin(theta)
            table.insert(vertices, x)
            table.insert(vertices, y)
        end
        love.graphics.polygon("line", vertices)
        love.graphics.translate(-dx,-dy)
    end,

}


local pd = {

}

local shapeExamples = require 'test.protodrawexamples'
function pd:drawAllShapes()
    shapeExamples(messyDrawFunctions, determinedColors, 0,30, "tri")
end
return pd