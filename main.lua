Terrain = require 'terrain'
local Tools = require 'construct.tools'

local BlobDetector = {}

local colorGen = Tools:colorGenerator()

function BlobDetector:new(...)
	return Tools:makeClass(BlobDetector,...)
end

function BlobDetector:init(w,h)
	self.width = w
	self.height = h
	self.nextLabel = 1
	self.labelTable = {}
	self.data = {}
	return self
end

function BlobDetector:weldBottomToTop()
	for x=1,self.width do
		local t = self:getBlobID(x,1)
		local b = self:getBlobID(x, self.height)

		if t and b then -- these two blobs touch. make it work
			self:absorbLabel(t, b)
		end
	end
end

function BlobDetector:getLabel( x, y )
	x = Tools:wrap(x, self.width)
	y = Tools:wrap(y, self.height)

	if self.data[y] then
		return self.data[y][x]
	end
end

function BlobDetector:setLabel(x,y,l)
	x = Tools:wrap(x, self.width)
	y = Tools:wrap(y, self.height)

	local row = self.data[y] or {}
	row[x] = l
	self.data[y] = row
end

function BlobDetector:setLabelTable( blob, group )
	if not group or not blob then return end

	local table = self.labelTable

	if table[blob] then
		if group < table[blob] then
			table[blob] = group
		end
	else
		table[blob] = group
	end

end

function BlobDetector:getFullLabel(label)
	local labelTable = self.labelTable

	if label then
		while label ~= labelTable[label] do
			label = labelTable[label]
		end
	end

	return label
end

function BlobDetector:getBlobID(x,y)
	local label = self:getLabel(x,y)
	return self:getFullLabel(label)
end

function BlobDetector:absorbLabel(new, absorb)
	if new and absorb and new ~= absorb then
		local labelTable = self.labelTable
		absorb = self:getFullLabel(absorb)
		print("absorb",new,absorb)
		for blob,label in ipairs(labelTable) do
			if label == absorb then
				labelTable[blob] = new
			end
		end
		
	end
end

function BlobDetector:getKernelLabels(x,y)
	local w = self:getBlobID(x-1,y)
	local nw = self:getBlobID(x-1,y-1)
	local n = self:getBlobID(x,y-1)
	local ne = self:getBlobID(x+1,y-1)

	local min

	if w and ( min == nil or w < min ) then
		min = w
	end
	if nw and ( min == nil or nw < min ) then
		min = nw
	end
	if n and ( min == nil or n < min ) then
		min = n
	end
	if ne and ( min == nil or ne < min ) then
		min = ne
	end

	return w,nw,n,ne, min
end

function BlobDetector:setKernelLabels(x,y,w,nw,n,ne,label)
	self:setLabel(x,y,label)
	if w then
		self:setLabel(x-1,y,label)
	end
	if nw then
		self:setLabel(x-1,y-1,label)
	end
	if n then
		self:setLabel(x,y-1,label)
	end
	if ne then
		self:setLabel(x+1,y-1,label)
	end
end

function BlobDetector:markBlob( x, y )

	local w,nw,n,ne,label = self:getKernelLabels(x,y)
--	print( "found", n, w, ne, nv)
	-- if n and w then
	-- 	if n <= w then
	-- 		label = n
	-- 	elseif w < n then
	-- 		label = w
	-- 	end
	-- elseif n then
	-- 	label = n
	-- elseif w then
	-- 	label = w
	-- end

	-- if label and nv and ne and ne < label then
	-- 	label = ne
	-- end

--	if nv then
--		label = Tools:minmax(n,w,ne,nw)
--	else
--		label = Tools:minmax(n,w)
--	end

	if not label then
		label = self.nextLabel
		self:setLabelTable(label, label)
		self.nextLabel = self.nextLabel + 1
	end

	--print("picked label", label)
	self:setKernelLabels(x,y,w,nw,n,ne,label)

	self:setLabelTable(w,label)
	self:setLabelTable(nw,label)
	self:setLabelTable(n,label)
	self:setLabelTable(ne,label)

	-- self:setLabelTable(label, n) --self:getFullLabel(n))
	-- self:setLabelTable(label, w)
	-- self:setLabelTable(label, ne)
	-- self:absorbLabel(label,w)
	-- self:absorbLabel(label,n)
	-- self:setLabelTable(n, label)
	-- self:setLabelTable(w, label)
	-- if nv then
	-- 	self:setLabelTable(ne, label)
	-- end

end

function BlobDetector:draw(size, plot)
	self.colors = self.colors or {}

	for y=1,self.height do
		local row = self.data[y]
		if row then
			for x=1,self.width do
				local id = self:getBlobID(x,y)
				if id then
					if self.colors[id] == nil then
						self.colors[id] = colorGen()
					end
					love.graphics.setColor(self.colors[id])
					plot(x,y,size)
				end
			end
		end
	end


end

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
			print("welding",i)
			blob:weldBottomToTop()
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