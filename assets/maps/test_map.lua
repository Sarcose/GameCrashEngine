local Space = require("core.space")

return {
    load = function()
        local root = Space(nil, 0, 0, 2000, 2000, 0)
        
        -- Example: House with a room
        local house = Space(root, 300, 300, 600, 400, 1)
        local room = Space(house, 100, 100, 200, 200, 2)
        
        -- Add portal
        room.portals = {
            {
                x = 180, y = 100, w = 20, h = 20,
                targetSpace = house,
                targetX = 400, targetY = 300,
                sprite = love.graphics.newImage("assets/portal.png")
            }
        }
        
        return root
    end
}