local classic = require("lib.classic")



local Fooey = classic:extend()


function Fooey:new()
    local obj = {
        x=10,
        y=20,
        w=1,
        h=2
    }
    return setmetatable(obj, self)  -- self is GameWorld
end





local Barry = classic:extend()




function Barry:new()
    local obj = self:extend()
    obj.x = 10
    obj.y = 20
    w=1
    h=2
    return obj


end

