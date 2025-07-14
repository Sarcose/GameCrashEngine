--v0.00 is the direct demo in the readme of LUIS
--v0.01 when we start testing different widgets and analyzing the API

--[[
    UX Design Concepts:
        Outer Pixels:
            Generally we were using a "Card flow PDA" appearance and look. Horizontally flowing menus,
                gathered up items, dynamic changes between items
        JSF:
            No idea yet. Something wirey I think... 
        OP Mobile: simpler?

]]



--[[
    Design questions:
        How can we insert SyslText into this? 
        sframe?
        recreate my "flow.lua" effect (also improve it)
        floating widgets?
        icons that move and dynamically change?
]]


--[[
    We can examine luis/widgets to get a sense of the built-in capabilities:
        - button.lua
        - checkBox.lua
        - colorPicker.lua
        - custom.lua
        - dialogueBox.lua   ; 
]]
local initLuis = require("luis.init")
local luis = initLuis("luis/widgets")
luis.flux = require("luis.3rdparty.flux")
local test = {}

--local game = require 'test.luis_test.testgames.gamebase'
--local game = require 'test.luis_test.testgames.sidescrollerplatformer.game'
local game = require 'test.luis_test.testgames.topdownrpg.game'
--local game = require 'test.luis_test.testgames.shmup.game'

--GravitySystem.filter = tiny.requireAll("isPlayer", "velocity", "position")

function test:load()
    --game:load()

end

local time = 0
function test:update(dt)
	game:update(dt)

end


function test:draw()
   game:draw()
end


return test