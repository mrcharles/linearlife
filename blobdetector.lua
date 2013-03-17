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

function BlobDetector:normalize()
	local seen = {}
	local count = 0
	for y=1,self.height do
		for x=1,self.width do
			local id = self:getBlobID(x,y)
			if id then
				if not seen[id] then
					seen[id] = true
					count = count + 1
				end
				self:setLabel(x,y, id)
			end
		end
	end
	print("found",count,"IDs")
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

return BlobDetector