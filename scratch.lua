--[[
protodraw examples (under construction)

in this example, we use color() to get a random color
might want to standardize where fg/bg are, then again this is a dirty protodraw
in the future we will probably make each shape a polygon mesh and each outline a separate
    poly mesh, and then draw them together.



--dynamic segmentation:

local x,y = 0,30
local mdf = messyDrawFunctions
local function next(mod)
    x = x + mod
    return x
end


--do end blocks used to limit scoped variables like w,r etc.
--rectangles:
do
    local w= 14
        --equilateral
    mdf:rectangle(next(w+5),y,w,w,color(),color())
        --tall
    mdf:rectangle(next(w+5),y,w,w*2,color(),color())
        --wireframe
    mdf:rectangle(next(w+5),y,w,w*2,color.transparent,color())

    --rounded rectangle
    mdf._segments = 30
    mdf:rectangle(next(w+5),y,w,w*2,color.transparent,color())
    --rounded rectangle
    mdf._segments = 30
    mdf:rectangle(next(w+5),y,w*2,w,color.transparent,color())
end  
--ellipses:
do
    x,y = 0,60
    local r = 14
    --circle
    mdf:ellipse(next(r+5),y,r,nil,color(),color())

    --bounce circle
    mdf:ellipse(next(r+5),y,r,nil,color.purple,color.white)
    
    --very jaggy circle?
    mdf._segments = 2
    mdf:ellipse(next(r+5),y,r,nil,color.orange,color.white)

    --very smooth circle?
    mdf._segments = 10
    mdf:ellipse(next(r+5),y,r,nil,color(),color()))

    --VERY smooth circle?
    mdf._segments = 30
    mdf:ellipse(next(r+5),y,r,nil,color(),color())

    --very jaggy horizontal ellipse?
    mdf._segments = 2
    mdf:ellipse(next(r+5),y,r/2,r,color.orange,color.white)
    --very jaggy vertical ellipse?
    mdf._segments = 2
    mdf:ellipse(next(r+5),y,r,r/2,color.orange,color.white)

    --very smooth horizontal ellipse?
    mdf._segments = 15
    mdf:ellipse(next(r+5),y,r/2,r,color.orange,color.white)
   
    --very smooth vertical ellipse?
    mdf._segments = 15
    mdf:ellipse(next(r+5),y,r,r/2,color.orange,color.white)
end
--triangles:
do
  -- Equilateral: cx,cy,size,rotation
  triangle("equilateral",color(),color(),1, 300, 300, 100, math.rad(30))

  -- Isosceles: cx,cy,base,height,rotation
  triangle("isosceles",color(),color(),1, 100, 100, 60, 80, math.rad(15))

  -- Right: x,y,base,height,orientation
  triangle("right",color(),color(),1, 400, 300, 80, 120, "tl")

  -- Arbitrary points; can't be defined with x/y
  triangle(nil,color(),color(),1, 500, 100, 550, 200, 480, 180)
end
  local t = love.timer.getTime()



--spirals:
  testSpiralShape(t, 1)
  testFractalShape(t, 2)
  testBlobShape(t, 3)




]]