local s = {}

s.spriteSystem = tiny.processingSystem()
s.spriteSystem.filter = tiny.requireAll("texture","pos")
s.spriteSystem.isDrawSystem = true
function s.spriteSystem:process(e)
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(e.sprite,e.pos.x,e.pos.y)
end

s.shapeSystem = tiny.processingSystem()
s.shapeSystem.filter = tiny.requireAll("shape","pos","dims","color")
s.shapeSystem.isDrawSystem = true
function s.shapeSystem:process(e)
    local shapetype = e.shape
    love.graphics.setColor(e.color)
    love.graphics[shapetype]("fill",e.pos.x,e.pos.y,e.dims.w,e.dims.h)
end
s.dialogueSystem = tiny.processingSystem()
s.dialogueSystem.filter = tiny.requireAll("name","say","pos")
s.dialogueSystem.isDrawSystem = true
function s.dialogueSystem:process(e)
    local ox = 30
    Font.set()
    love.graphics.setColor(1,1,1)
    love.graphics.print(e.say, e.pos.x+ox,e.pos.y)
end

return s