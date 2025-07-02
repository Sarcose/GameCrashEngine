local designer = {
    active = false,
    ctx = {
        world = nil,
        camera = nil,
    },
    internal = {
        selected = nil,
        camera = require ('design.camera')(),
        UX = require 'design.ux',
        mouse = require 'design.mouse'
    },
    controls = require 'design.controls',
}

function designer:configure(t)
    for k,v in pairs(t) do
        self.ctx[k] = v
    end
    assert(self.ctx.world,"designer configured without world!")
    self.internal.camera:attach(self.ctx.world)
end


function designer:activate()
    self.active = true
    if self.ctx.camera then
        self.internal.camera:latch(self.ctx.camera)
    end
end

function designer:deactivate()
    self.active = false
end



function designer:processControls(dt)
    self.controls:update(dt)
    if self.controls.movecamera.move then self.camera:move(self.controls.movecamera.x,self.controls.movecamera.y) end
    if self.controls.zoom then self.camera:zoom(self.controls.zoom) end
    if self.controls.mb1 then self:checkClick() end
    if self.controls.mb1drag then self:checkDrag() end
    if self.controls.mb2 then self:checkRightClick() end
    if self.controls.mb2drag then self:checkRightDrag() end
    if self.controls.menumove.UD then
        self.internal.ux:input((self.controls.menumove.UD))
    end
    if self.controls.menumove.LR then

    end


end
function designer:update(dt)
    if not self.active then return end
    self:processControls(dt)
    self.internal.camera:update(dt)
    --self.internal.ux:update(dt)
    --self.internal.mouse:update(dt)
end


function designer:draw()
    if not self.active then return end
    self.internal.UX:draw()
    self.internal.mouse:draw()
    if self.internal.selected then
        local s = self.internal.selected
        love.graphics.rectangle(s.x,s.y,s.w,s.h)
    end

end

return designer