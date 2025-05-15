--[[========Low==Level==Framework=========]]
require 'core._g^crash'
require ('lib.batteries'):export()
require 'core.rng'
_G.tiny = require 'lib.tiny'
_G.Class = require 'lib.classic'
_G.Controls = require('test.jsfproto.controller.controls').new()

_G.jsfprototype = require 'test.jsfprototype'


local f = {}

function f:load()
    jsfprototype:load()
end


function f:update(dt)
    Controls:update(dt)
    jsfprototype:update(dt, "drawonly")
end


function f:draw()
    jsfprototype:draw("drawonly")
end



return f