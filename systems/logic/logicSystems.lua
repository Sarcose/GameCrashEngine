local s = {}

s.talkingSystem = tiny.processingSystem()
s.talkingSystem.filter = tiny.requireAll("name", "mass", "phrase")
function s.talkingSystem:process(e, dt)
    e.time = e.time - dt
    if e.time < 0 then 
        e.time = e.timer
        e.mass = love.math.random(1,10) * 150
        e.say = tostring(e.name).." who weighs "..tostring(e.mass).." pounds, says "..tostring(e.phrase) 
    end
    
end




return s