local tiny = require("lib.tiny") --#TODO system

return tiny.system({
    filter = tiny.requireAll("position", "velocity", "size"),
    process = function(_, entity, dt)
        local space = entity.space
        local goalX, goalY = entity.position.x + entity.velocity.x * dt, 
                             entity.position.y + entity.velocity.y * dt
        
        -- Resolve collisions in local space
        local actualX, actualY = space.bumpWorld:move(entity, goalX, goalY)
        entity.position.x, entity.position.y = actualX, actualY
    end
})