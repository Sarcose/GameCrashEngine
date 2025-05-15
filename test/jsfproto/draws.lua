local shapes = require 'test.jsfproto.shapes'
local d = {
    x=0,y=0,pan = 10,
    messages = {},messagelimit = 5,
    font = lg.newFont(10),
    mx = 0,
    my = 5,
    shapes = {
        all = {},
    }
}


local msgstring = "lorem ipsum dolor sid blah blah"
d.mx = lg.getWidth() - d.font:getWidth(msgstring)

function d:message(m)
    table.insert(self.messages,0,m)
    if #self.messages > self.messagelimit then self.messages[#self.messages] = nil end
end
d:message("initializing draws")

function d:addShape(shape,cat)
    self:message("adding shape "..tostring(shape.__type.__type).." in cat "..tostring(cat))

end

for i,v in ipairs(shapes) do
    d:addShape(v,v.cat)
end

_c_todo{"05/08/2025","Break out processControls into a controlProcessor I can attach to entities","Break out messaging system into a messageProcessor for this same purpose"}
function d:processControls(dt)
    local mod,pan = 0,self.pan
    if Controls:down("lshift") then mod = mod + 0.5 end
    if Controls:down("lalt") then mod = mod + 0.5 end
    if Controls:down("up") then self.y = self.y - pan - (pan * mod)
    elseif Controls:down("down") then self.y = self.y + pan + (pan * mod)
    end
    if Controls:down("left") then self.x = self.x - pan - (pan * mod)
    elseif Controls:down("right") then self.x = self.x + pan + (pan*mod)
    end
    if Controls:pressed("r") then self.x,self.y = 0,0
        self:message("Pan reset")
    end


end




function d:update(dt)
    self:processControls(dt)
end


function d:drawAllShapes()
    for i,v in ipairs(self.shapes.all) do
        v:draw()    --very basic, at first.
    end

    local priorfont = lg.getFont()
    lg.setFont(self.font)
    local h = self.font:getHeight("W")+2 --(margin)
    for i,v in ipairs(self.messages) do
        lg.print(v,self.mx,self.my+((i-1)*h))
    end
    lg.setFont(priorfont)
end

d:message("draws initialized")


return d