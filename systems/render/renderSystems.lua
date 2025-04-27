local s = {}

s.spriteSystem = tiny.processingSystem()
s.spriteSystem.filter = tiny.requireAll("sprite","pos")
function s.spriteSystem:process(e)
    love.graphics.setColor()
    love.graphics.draw(e.sprite,e.pos.x,e.pos.y)
end

s.shapeSystem = tiny.processingSystem()
s.shapeSystem.filter = tiny.requireAll("shape","pos","dims","color")
function s.shapeSystem:process(e)
    local shapetype = e.shape.type
    love.graphics.setColor(e.color)
    love.graphics[shapetype]("fill",e.pos.x,e.pos.y,e.dims.w,e.dims.h)
end

s.dialogueSystem = tiny.processingSystem()
s.dialogueSystem.filter = tiny.requireAll("name","say","x","y")
function s.dialogueSystem:process(e)
    love.graphics.setFont(font)
    love.graphics.print(e.say, e.x,e.y)
end

return s