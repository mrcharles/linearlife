Terrain = require 'terrain'
Tools = require 'construct.tools'
BlobDetector = require 'blobdetector'

local EdgeDetector = {}

function EdgeDetector:new(terrain)
	return Tools:makeClass(EdgeDetector,terrain)
end

function EdgeDetector:init(terrain)
	local src = terrain
	self.debug = true

	self.edges = {}

	self.blobs = {}
	self:detectEdges(src)

	return self

end

function EdgeDetector:detectEdges(src)
	for y=1, src.height do
		for x=1, src.width do
			self:capture( function(debuglayer)
				local v = src:get(x,y)
				--if v ~= val then return end -- not part of blob
				local blob = self.blobs[v] or BlobDetector:new(src.width,src.height)
				blob:markBlob(x,y) 
				self.blobs[v] = blob

				local n = src:get(x,y-1)
				local w = src:get(x-1,y)
				local e = src:get(x+1,y)
				local s = src:get(x, y+1)

				--print(x,y,v,n,w)
				self:markEdge(v,x,y,n,w,e,s)
				if debuglayer and v == debuglayer then
					return true
				end
			end)
		end
	end

	self:capture(function()
		for i,blob in ipairs(self.blobs) do
			print("---Welding",i)
			blob:weldBottomToTop()
			blob:normalize()
		end
	end)


end

function EdgeDetector:markBlob(v, x, y, n, e)

end

function EdgeDetector:markEdge(v, x,y, n,w,e,s)
	--print(x,y)
	if v ~= n or v ~= w or v ~= e or v ~= s then
		local edges = self.edges
		edges[v] = edges[v] or {}
		table.insert(edges[v], {x=x,y=y})
	end
end

function EdgeDetector:capture(func)
	if self.debug then
		self.todo = self.todo or {}

		table.insert(self.todo, func)
	else
		func()
	end
end

function EdgeDetector:step(...)
	if not self.done then
		self.stepidx = self.stepidx or 1

		local ret = self.todo[self.stepidx](...)

		self.stepidx = self.stepidx + 1
		if self.stepidx > #self.todo then
			self.done = true
		end

		return ret
	end
end

function EdgeDetector:draw(size, plot)
	if self.edges then
		for i,edgegroup in ipairs(self.edges) do
			for j, edge in ipairs(edgegroup) do
				love.graphics.setColor(255,0,0)
				plot(edge.x,edge.y, size)
			end
		end
	end
end

function EdgeDetector:drawBlob(id, size, plot)
	if self.blobs[id] then
		self.blobs[id]:draw(size, plot)
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
		return GroundType.Ground
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
	elseif v == GroundType.Ground then
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
	--math.randomseed(1)
	test = Terrain:new(256,256,32)
	test:fillDiamondSquare(1, -0.2, 0.5, 1)
	test:convert(convertfunc)

	blob = EdgeDetector:new(test,GroundType.Water)
	
	local mapcanvas = love.graphics.newCanvas(256,256)
	love.graphics.setCanvas(mapcanvas)
	love.graphics.setBlendMode("alpha")
	love.graphics.setColorMode("replace")
	test:draw(1, groundcolor, plot)
	love.graphics.setCanvas()

	mapimage = love.graphics.newImage(mapcanvas:getImageData())
	mapimage:setFilter("nearest", "nearest")

end

local drawedges
local drawblob = 2 
local autostep = true
local dim = true
function love.keypressed(key)
	if key == " " then
		--drawedges = not drawedges
		autostep = nil
		while not blob:step(drawblob) do

		end
		return
	end

	if key == "e" then
		drawedges = not drawedges
	end

	if key == "c" then
		dim = not dim
	end

	if key == "a" then
		autostep = true
	end

	if key == "right" then
		drawblob = drawblob and drawblob + 1 or 1
	elseif key == "left" then
		drawblob = drawblob and drawblob - 1 or 1
	end

	if key == "b" then
		if drawblob then 
			drawblob = nil
		end
	end

	if key == "l" then
		if drawblob then
			print(unpack(blob.blobs[drawblob].labelTable))
		end
	end	
end


local size = 3
local tests = {}
function love.mousepressed(x,y,btn)
	x = math.floor(x / size)
	y = math.floor(y / size)
	--table.insert(tests, {x=x,y=y})
	print(blob.blobs[drawblob]:getLabel(x,y), blob.blobs[drawblob]:getBlobID(x,y))
end

function love.update(dt)
	--print(dt)
	if autostep then
		for i=1,64 do
			blob:step()
		end
	end
end

function love.draw()

	if test then
		if dim then
			love.graphics.setColorMode("modulate")
			love.graphics.setColor(255,255,255,64)
		else
			love.graphics.setColorMode("replace")
			love.graphics.setColor(255,255,255)
		end
		love.graphics.draw(mapimage, size,size,0,size)
		love.graphics.setBlendMode("alpha")
		love.graphics.setColorMode("replace")

		if drawedges then
			blob:draw(size, plot)
		end
		
		if drawblob then
			blob:drawBlob(drawblob, size, plot)
		end
	end

	for i,v in ipairs(tests) do
		love.graphics.setColor(0,0,0)
		plot(v.x,v.y,size)
	end
end