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

function test:load()
    local container = luis.newFlexContainer(20, 20, 10, 10)

    -- Add some widgets to the container
    local button1 = luis.newButton("Button 1", 15, 3, function() print("Button 1 clicked!") end, function() print("Button 1 released!") end, 5, 2)
    local button2 = luis.newButton("Button 2", 15, 3, function() print("Button 2 clicked!") end, function() print("Button 2 released!") end, 5, 2)
    local slider = luis.newSlider(0, 100, 50, 10, 2, function(value)
        print('Slider value:', value)
    end, 10, 2)


    container:addChild(button1)
    container:addChild(button2)
    container:addChild(slider)

    luis.newLayer("main")
    luis.setCurrentLayer("main")
    
    -- Add the container to your LUIS layer
    luis.createElement(luis.currentLayer, "FlexContainer", container)

    love.window.setMode(1280, 1024)
end

local time = 0
function test:update(dt)
	time = time + dt
	if time >= 1/60 then	
		luis.flux.update(time)
		time = 0
	end

    luis.update(dt)
end


function test:draw()
    luis.draw()


end



--Looks like luis has its own input system which is nice, will likely have to do some merging with our baton integration

function love.mousepressed(x, y, button, istouch)
    luis.mousepressed(x, y, button, istouch)
end

function love.mousereleased(x, y, button, istouch)
    luis.mousereleased(x, y, button, istouch)
end

function love.keypressed(key)
    if key == "escape" then
        if luis.currentLayer == "main" then
            love.event.quit()
        end
    elseif key == "tab" then -- Debug View
        luis.showGrid = not luis.showGrid
        luis.showLayerNames = not luis.showLayerNames
        luis.showElementOutlines = not luis.showElementOutlines
    else
        luis.keypressed(key)
    end
end


return test