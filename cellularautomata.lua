local Tools = require 'construct.tools'
require 'capturable'


local Map = Tools:Class()

function Map:init(w,h)
	self.width = w
	self.height = h
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
end

function Map:iterate(iterator)
	for y=1,self.height do
		for x=1,self.width do
			iterator(x,y,self:get(x,y))
		end
	end	
end

CellularAutomata = Tools:Class(Capturable)

function CellularAutomata:init(w,h,generations, population, clearfunc, setfunc, paramfunc)
	self.width = w
	self.height = h
	self.generationsLeft = generations
	self.setfunc = setfunc
	self.clearfunc = clearfunc
	self.paramfunc = paramfunc
	self.data = Map:new(w,h)
	self.generations = {}
	--self.debug = true

	self:populate(population)

	local gens = self.generationsLeft
	while gens > 0 do
		self:capture(function()
			self:makeGeneration()
			return true
		end)
		gens = gens - 1
	end

	return self
end


function CellularAutomata:populate(chance)
	local random = math.random

	local data = self.data
	for y=1,self.height do
		for x=1,self.width do
			if random() <= chance then
				data:set(x,y,1)
			end
		end
	end
end

function CellularAutomata:generate(data)
	local new = Map:new(data.width,data.height)

	local clear = self.clearfunc
	local set = self.setfunc
	local param = self.paramfunc

	for y=1,self.height do
		for x=1,self.width do
			local params = {param(data,x,y)}
			if set( unpack(params) ) then
				new:set(x,y,1)
			elseif clear( unpack(params) ) then
				new:set(x,y,0)
			else
				new:set(x,y,data:get(x,y))
			end
		end
	end

	return new

end

function CellularAutomata:makeGeneration()
	--push our existing map
	table.insert(self.generations, self.data)
	self.data = self:generate(self.data)
	self.generationsLeft = self.generationsLeft - 1
end

function CellularAutomata:getGenerations()
	return self.generations
end

function CellularAutomata:draw(size, plot)
	for y=1,self.height do
		for x=1,self.width do
			local v = self.data:get(x,y)

			if v == 0 then --dead
				love.graphics.setColor(40,40,40)
				plot(x,y,size)
			elseif v == 1 then
				love.graphics.setColor(225,225,225)
				plot(x,y,size)
			end
		end
	end
end
