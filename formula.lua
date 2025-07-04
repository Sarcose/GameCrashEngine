--[[========Low==Level==Framework=========]]
require 'core._g^crash'
require ('lib.batteries'):export()
require 'core.rng'
_G.tiny = require 'lib.tiny'
_G.Class = require 'lib.classic'
_G.Controls = require('test.jsfproto.controller.controls').new() -- i'm just overriding this in the formula for now, later we will modularize it better.
_c_todo{"06/27/2025","Break jsfproto.controller.controls out into an external module"}


--[[========Game==Design==Formula=========]]--essential game is designed here.
_G.jsfprimitiveproto = require 'test.jsf_primitiveproto'  --first mesh prototype for jsf
_G.retro_jsf = require 'test.retro_jsf' --regressive JSF concept meant to rebuild the original to reach basic design goals.
_G.luis_test = require 'test.luis_test'

local f = {}


local formula = luis_test   --set the formula we are testing, here.

function f:load()
    love.graphics.setBlendMode("alpha")
    formula:load()
end


function f:update(dt)
   -- Controls:update(dt)
   -- formula:update(dt, "drawonly")
    formula:update(dt, "drawonly")
end


function f:draw()
   -- formula:draw("drawonly")
    formula:draw("drawonly")
end



return f