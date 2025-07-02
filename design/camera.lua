return function()
    local c = {
        iscamera = true,
        x = 0,
        y = 0,
        scale = 1,
        finalx = 0,
        finaly = 0,
        world = nil,
        debugui = {},
    }
    function c:latch(cam)
        if cam.iscamera then
            self.x = cam.x
            self.y = cam.y
            self.scale = cam.scale
            self.finalx = cam.finalx
            self.finaly = cam.finaly
            self.world = cam.world
        end
    end
    function c:debugObject(obj)
        local fn, color = obj.fn, obj.color or {1,1,1}
        if not fn then
            if obj[1] == "rectangle" then
                fn = function()
                    local r,g,b = lg.getColor()
                    lg.setColor(color)
                    lg.rectangle("line",obj[1],obj[2],obj[3],obj[4])
                    lg.setColor(r,g,b)
                end
            end
        end
    end
    function c:attach(w)
        self.world = w
    end
    function c:zoom(s)
        if s == 0 then return end
        self.scale = self.scale + s
    end
    function c:updateScale()
        self.finalx = self.x * self.scale
        self.finaly = self.y * self.scale
    end
    function c:move(x,y)
        self.x = self.x + x
        self.y = self.y + y
    end
    function c:update(dt)
        self:updateScale()
        self.debugui = {}
    end
    function c:draw()
        love.graphics.push()
        love.graphics.translate(self.finalx, self.finaly)
        love.graphics.scale(self.scale)
        if type(self.world) == "function" then
            self.world() 
        elseif self.world and self.world.draw then
            self.world:draw()
        end
        for _,fn in ipairs(self.debugui) do fn() end
        love.graphics.pop()
    end
end