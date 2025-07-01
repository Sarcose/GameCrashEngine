local physics = {}

function physics:configure(system)
    local system = require("lib."..system)
    self.newWorld = system.newWorld
end

function physics:new(w,h)
    return self.newWorld(w,h)
end

return physics