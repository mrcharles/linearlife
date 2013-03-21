local terraintest = require 'terraintest'
local cavestest = require 'cavestest'
Gamestate = require "hump.gamestate"

local size = 3
local function plot(x,y, size)
	local fudge = 0
	fudge = size / 2
	love.graphics.setPoint(size,"rough")
	love.graphics.point(x * size + fudge, y * size + fudge)
end

function love.load()
	Gamestate.registerEvents()
	cavestest.setDraw(plot,size)
	terraintest.setDraw(plot,size)
	Gamestate.switch(terraintest,256,256)

end

function love.keypressed(key)
end

function love.update(dt)
end

function love.draw()
end