local formula = require 'formula'
_G.Controls = require 'ui.controls'()


function love.load()
    formula:load()

end


function love.update(dt)
    formula:update(dt)

end


function love.draw()
    formula:draw()

end 

function love.wheelmoved(x,y)
    Controls.wheel.x, Controls.wheel.y = x,y

end