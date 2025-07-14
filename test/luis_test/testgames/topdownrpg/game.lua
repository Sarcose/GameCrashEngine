--includes
local bump = require("lib.bump")
local tiny = require("lib.tiny")

TILE = 32


--local functions

local function interact(npc)
    print("[DEBUG] Interacted with NPC: " .. (npc.name or "?"))
end



--Systems
--[[Wall system]]
local function wall(x, y, w, h)
    return{
        position = {x = x, y = y},
        shape = {w = w, h = h,},
        drawable = true,
        wall = true,
        draw = function(self)
            love.graphics.setColor(1, 1, 0)
            love.graphics.rectangle("fill",self.position.x,self.position.y,self.shape.w,self.shape.h)
        end
    }
end

--[[NPC system]]
local function NPC(x, y, symbol, name)
    return {
        position = {x = x, y = y},
        shape = {w = TILE, h = TILE,},
        drawable = true,
        npc = true,
        name = name,
        draw = function(self)
            love.graphics.setColor(1, 1, 0)
            love.graphics.print(symbol, x + 8, y + 4)
        end
    }
end

--[[Interaction system]]
local InteractionSystem = tiny.system()
InteractionSystem.filter = tiny.requireAll("isPlayer", "position")

function InteractionSystem:update(dt)
    local physics_world, ecs_world = self.world.physics_world, self.world
    local player = self.entities[1]
    if not player then return end

    if love.keyboard.isDown("z") or love.keyboard.isDown("return") then
        local x, y, w, h = player.position.x, player.position.y, player.shape.w, player.shape.h
        local hits = physics_world:queryRect(x - 2, y - 2, w + 4, h + 4, function(item)
            return item.npc
        end)

        for _, npc in ipairs(hits) do
            interact(npc)
        end
    end
end



local game = require("test.luis_test.testgames.gamebase")


-------[[ Load Override ]]-------
local formula = {}
function formula:load(base)
    local physics_world, ecs_world = base.physics_world, base.ecs_world
    local TE = game.totalEntities

    -- Add walls (top, bottom, left, right)
    TE:add(wall(0, 0, SCREEN_WIDTH, TILE)) -- top
    TE:add(wall(0, SCREEN_HEIGHT - TILE, SCREEN_WIDTH, TILE)) -- bottom
    TE:add(wall(0, 0, TILE, SCREEN_HEIGHT)) -- left
    TE:add(wall(SCREEN_WIDTH - TILE, 0, TILE, SCREEN_HEIGHT)) -- right

    -- Add some inner walls
    TE:add(wall(5 * TILE, 5 * TILE, 3 * TILE, TILE))
    TE:add(wall(8 * TILE, 3 * TILE, TILE, 3 * TILE))

    -- Add NPCs
    TE:add(NPC(6 * TILE, 3 * TILE, "A", "Alice"))
    TE:add(NPC(9 * TILE, 6 * TILE, "B", "Bob"))

    -- Add interaction system
    ecs_world:addSystem(InteractionSystem)


        -- Modify player speed (optional)
    for _, e in ipairs(TE.ecsQueue) do
        if e.isPlayer then
            e.speed = 100
        end
    end

end

game:load(formula)

return game