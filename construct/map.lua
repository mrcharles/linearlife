local Tools = require 'construct.tools'
local Map = Tools:Class()

function Map:init(w,h)
	self.width = w
	self.height = h

	if w and h then 
		self.x = 1
		self.y = 1
	else
		self.auto = true
	end

	self.data = {}
	return self
end

function Map:get(x,y)
	if self.data[y] then
		return self.data[y][x]
	end
end

function Map:set(x,y,v)
	local row = self.data[y] or {}
	row[x] = v
	self.data[y] = row
	if self.auto then
		if self.x == nil or x < self.x then
			self.x = x
		end
		if self.width == nil or x > self.width then
			self.width = x
		end
		if self.y == nil or y < self.y then
			self.y = y
		end
		if self.height == nil or y > self.height then
			self.height = y
		end
	end
end



function Map:iterate(iterator)
	for y=self.y,self.height do
		for x=self.x,self.width do
			iterator(x,y,self:get(x,y))
		end
	end	
end

return Map