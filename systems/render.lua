local tiny = require("lib.tiny") --#TODO system
return tiny.system({
    filter = tiny.requireAll("position", "sprite"),
    process = function(_, e)
        local x, y = e.space:toGlobal(e.position.x, e.position.y)
        love.graphics.draw(e.sprite, x, y)
    end
})