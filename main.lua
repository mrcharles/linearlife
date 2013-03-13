Terrain = require 'terrain'

local BlobDetector = {}

function BlobDetector:new(terrain, val)
	local m = {}
	BlobDetector.__index = BlobDetector
	setmetatable(m, BlobDetector)

	return m:init(terrain, val)
end

function BlobDetector:init(terrain, val)
	local src = terrain
	self.debug = true

	for y=1, src.height do
		for x=1, src.width do
			self:capture( function()
				local v = src:get(x,y)
				if v ~= val then return end

				local n = src:get(x,y-1)
				local w = src:get(x-1,y)
				local e = src:get(x+1,y)
				local s = src:get(x, y+1)

				--print(x,y,v,n,w)
				if v ~= n or v ~= w or v ~= e or v ~= s then
					self:markEdge(x,y)
				end
			end)
		end
	end

	return self

end

function BlobDetector:markEdge(x,y)
	--print(x,y)
	self.edges = self.edges or {}
	table.insert(self.edges, {x=x,y=y})
end

function BlobDetector:capture(func)
	if self.debug then
		self.todo = self.todo or {}

		table.insert(self.todo, func)
	else
		func()
	end
end

function BlobDetector:step()
	if not self.done then
		self.stepidx = self.stepidx or 1

		self.todo[self.stepidx]()

		self.stepidx = self.stepidx + 1
		if self.stepidx > #self.todo then
			self.done = true
		end
	end
end

function BlobDetector:draw(size, plot)
	if self.edges then
		for i,edge in ipairs(self.edges) do
			love.graphics.setColor(255,0,0)
			plot(edge.x,edge.y, size)
		end
	end
end


local GroundType = {
	Water = 1,
	Sand = 2,
	Ground = 3,
	Mountain = 4,
	Ice = 5,
}

function convertfunc(v)
	if v < 0.25 then
		return GroundType.Water
	elseif v < 0.3 then
		return GroundType.Sand
	elseif v < 0.6 then
		return GroundType.Dirt
	elseif v < 0.8 then
		return GroundType.Mountain
	else
		return GroundType.Ice
	end 
end

function groundcolor(v)
	if v == GroundType.Water then
		return 0,0,255
	elseif v == GroundType.Sand then
		return 255,255,0
	elseif v == GroundType.Dirt then
		return 0, 255, 0
	elseif v == GroundType.Mountain then
		return 99,36,0
	elseif v == GroundType.Ice then
		return 255,255,255
	end 
end

function plot(x,y, size)
	local fudge = 0
	fudge = size / 2
	love.graphics.setPoint(size,"rough")
	love.graphics.point(x * size + fudge, y * size + fudge)
end


local test
local blob
local steptime = 0.005

local mapimage
local mapquad

function love.load()
	test = Terrain:new(256,256,32)
	test:fillDiamondSquare(1, -0.2, 0.5, 1)
	test:convert(convertfunc)

	blob = BlobDetector:new(test,GroundType.Mountain)
	
	local mapcanvas = love.graphics.newCanvas(256,256)
	love.graphics.setCanvas(mapcanvas)
	love.graphics.setBlendMode("alpha")
	love.graphics.setColorMode("replace")
	test:draw(1, groundcolor, plot)
	love.graphics.setCanvas()

	mapimage = love.graphics.newImage(mapcanvas:getImageData())
	mapimage:setFilter("nearest", "nearest")

end

local drawblob = true
function love.keypressed()
	drawblob = not drawblob
end

function love.update(dt)
	--print(dt)
	for i=1,64 do
		blob:step()
	end
end

function love.draw()

	if test then
		love.graphics.draw(mapimage, 3,3,0,3)
		love.graphics.setBlendMode("alpha")
		love.graphics.setColorMode("replace")

		if drawblob then
			blob:draw(3, plot)
		end
	end
end