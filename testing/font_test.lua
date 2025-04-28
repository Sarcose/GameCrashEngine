local ox, oy, sy = 40,40,60
_c_warn("These tests don't really work to show fonts but they do prove the fonts work. Moving on for now.")

local env = {
    entities = {}
}

local fontObj = {
    variants = {}
}

function fontObj:new(fontmeta)
    local obj = nil
    if type(fontmeta)=="table" then
        obj = {
            name = fontmeta.name,
        }
        obj.testString = obj.name..": Lorem ipsum dolor sit amet, consectetur"
        for i,v in ipairs(fontmeta) do
            obj[i] = v
        end
        function obj:draw(offset)
            lg.setColor(1,1,1)
            for i,font in ipairs(self) do
                local xo = (i-1)*offset
                lg.setFont(font)
                local x = ox + xo
                local y = (oy*offset) + (i-1)*sy
                lg.print(self.testString,x,y)
            end
        end
    end
    return obj    
end

function env:draw()
    for i,v in ipairs(self.entities) do
        v:draw(i)
    end
end

function env:start()
    for i,v in ipairs(Font.fonts.__indices) do
        local f = fontObj:new(v)
        table.insert(self.entities,f)
    end
end




return function()
    env:start()
    return env
end