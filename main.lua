local formula = require 'formula'
_G.GAMETIME = 0
_G.DRAWHURTBOXES = true
_G.FLASHINTERVALS = {
    iframes = 0.05,
}

function love.load()
    formula:load()

end


function love.update(dt)
    GAMETIME = GAMETIME + dt
    formula:update(dt)

end


function love.draw()
    formula:draw()

end 

function love.wheelmoved(x,y)
    Controls.wheel.x, Controls.wheel.y = x,y

end