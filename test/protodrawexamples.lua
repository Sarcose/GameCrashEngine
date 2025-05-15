--[[
protodraw examples (under construction)

in this example, we use color() to get a random color
might want to standardize where fg/bg are, then again this is a dirty protodraw
in the future we will probably make each shape a polygon mesh and each outline a separate
    poly mesh, and then draw them together.
--]]


--dynamic segmentation:



return function(mdf,color,x,y)
    local _r = 0    --no need for rotations imo
    x,y = x or 0, y or 30
    local t = love.timer.getTime()
    local function next(mod)
        x = x + mod
        return x
    end
    do  --rectangles
        local w= 14
            --equilateral
        mdf:rectangle(next(w+5),y,w,w,_r,_r,color(),color())
            --tall
        mdf:rectangle(next(w+5),y,w,w*2,_r,_r,color(),color())
            --wireframe
        mdf:rectangle(next(w+5),y,w,w*2,_r,_r,color.transparent,color())
    end
        --rounded rectangle
        local w= 14
        mdf._segments = 30
        mdf:rectangle(next(w+5),y,w,w*2,_r,_r,color.transparent,color())
        --rounded rectangle
        mdf._segments = 30
        mdf:rectangle(next(w+5),y,w*2,w,_r,_r,color.transparent,color())
    
    do  --ellipses
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
        mdf:ellipse(next(r+5),y,r,nil,color(),color())

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
    do  --triangles
        x,y = 0,200
        -- Equilateral: cx,cy,size,rotation
        mdf:triangle("equilateral",color(),color(),1, next(60), y, 40, math.rad(30))

        -- Isosceles: cx,cy,base,height,rotation
        mdf:triangle("isosceles",color(),color(),1, next(60),y, 40, 70, math.rad(15))

        -- Right: x,y,base,height,orientation
        mdf:triangle("right",color(),color(),1, next(60), 60, 100, 120, "tl")

        -- Arbitrary points; can't be defined with x/y
        mdf:triangle(nil,color(),color(),1, 500, 100, 550, 200, 480, 180)
    end

    do --spiral
        x,y = 0, 300
        local points = 3
        local mod = 3
        --static
        local t = 0 
        for i=points, 15 do  --loops are being used to generate multiple point totals.
            mdf:spiral(t,next(30),y, i*mod, 0)
        end
        --spinning
        t = os.time()
        x,y = 0, 400 
        local spin = 3
        for i=points, 15 do
            mdf:spiral(t,next(30),y, i*mod, spin)
        end
        x,y = 0, 500
        --spinning faster
        for i=1, 5 do
            mdf:spiral(t,next(30),y, i*3, spin+i)
        end
    end

    do --fractals
        lg.setColor(1,1,1)  --basic color at first
        x,y = 0, 600
        local t = 0 --static time at first
        local depth = 1
        mdf:fractal(t, next(30),y, depth)
        --depth test
        for i=1, 10 do
            mdf:fractal(t,next(30),y,i)
        end
        --movement test
        t = os.time()
        x,y = 0,700
        mdf:fractal(t, next(30),y, depth)
        --depth test
        for i=1, 10 do
            mdf:fractal(t,next(30),y,i)
        end

    end

    do --blobs
        lg.setColor(1,1,1)  --basic color at first
        --static test
        x,y = 0, 800
        local t = 0
        local points = 3
        mdf:blob(t,next(30),y,points)
        for i=6, 30, 3 do
            mdf:blob(t,next(30),y,i)
        end
    
        --movement test
        x,y = 0, 900
        t = os.time()
        mdf:blob(t,next(30),y,points)
        for i=6, 30, 3 do
            mdf:blob(t,next(30),y,i)
        end
    
    end


    color:reset()
end

