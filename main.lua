world = require("core.game_world"):new()

function love.load()
    
end

function love.update(dt)
  world:update(dt)
end

function love.draw()
  world:draw()  -- Process render systems
end

function love.keypressed(key)
  if key == "escape" then love.event.quit() end
end