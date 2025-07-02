local designcontrols = {
    movecamera = {
        move = false,
        x = 0,
        y = 0,
        controls = {up = {y = -1}, down = {y = 1}, left = {x = -1}, right = {x = 1}}
    },
    menumove = {
        UD = nil,
        LR = nil,
        controls = {
            UD = {"up","down"},
            LR = {"left","right"},
        }
    },
    zoom = false,
    mb1 = false,
    mb2 = false

}

function designcontrols:update(dt)
    self.zoom, self.mb1, self.mb2, self.mb1drag, self.mb2drag = false, false, false, false, false
    self.movecamera.move, self.movecamera.x, self.movecamera.y = false, 0,0
    self.menumove
    if Controls:pressed("c") then
        self.cameramode = boolswitch(self.cameramode)
    end
    if self.cameramode then
        for k,v in pairs(self.movecamera.controls) do
            if Controls:down(k) then 
                for dir,val in pairs(v) do
                    self.movecamera[dir] = val
                end
            end
        end
    else    --if not cameramode then menu move mode
        for _,v in ipairs(self.menumove.controls.UD) do
            if Controls:down(v) then
                self.menumove.UD = v
                break
            end
        end
        for _,v in ipairs(self.menumove.controls.LR) do
            if Controls:down(v) then
                self.menumove.LR = v
                break
            end
        end
    end
    if self.movecamera.x ~= 0 or self.movecamera.y ~= 0 then self.movecamera.move = true end
    if Controls:down("=") or Controls:down("+") then
        self.zoom = 1
    elseif Controls:down("-") or Controls:down("-") then
        self.zoom = -1
    else
        self.zoom = false
    end

    if Controls:pressed("mb_left") then self.mb1 = true end
    if Controls:pressed("mb_right") then self.mb2 = true end
    if Controls:down("mb_left") then self.mb1drag = true end
    if Controls:down("mb_right") then self.mb2drag = true end

end

return designcontrols