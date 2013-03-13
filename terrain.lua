local Terrain = {}

local random = function()
	return math.random() * 2 - 1
end

function wrap(val, range)
	-- if not (val <= 256 and val >= -1) then
	-- 	print('fuck')
	-- end

	if val > range then
		--print("wrapping",val,"to",val-range)
		return val - range
	elseif val < 1 then
		--print("wrapping",val,"to",val+range)
		return val + range
	else
		return val
	end
end

function Terrain:new(w,h, featuresize)
	local t = {}
	Terrain.__index = Terrain

	setmetatable(t, Terrain)

	return t:init(w,h, featuresize)
end

function Terrain:init(w,h, featuresize)
	self.width = w
	self.height = h
	self.featuresize = featuresize
	self.map = {}
	self.debug = true

	for y=1,self.height do
		for x=1,self.width do
			self:set(x,y, -32, true)
		end
	end

	return self
end

function Terrain:set(x,y, val, sokay)
	x = wrap(x, self.width)
	y = wrap(y, self.height)
	local idx = x + (y-1) * self.width

	assert(sokay or self.map[idx] == -32)
	self.map[idx] = val
end

function Terrain:sample(x,y, sokay)
	x = wrap(x, self.width)
	y = wrap(y, self.height)

	local idx = x + (y-1) * self.width

	assert(sokay or self.map[idx] ~= -32)

	return self.map[idx]
end

Terrain.get = Terrain.sample

function Terrain:sampleSquare(x,y,size,value)
	local hs = size / 2;
	assert(hs == math.floor(hs))

	-- a       b
	--
	--	   x
	--
	-- c       d

	local a = self:sample(x - hs, y - hs)
	local b = self:sample(x + hs, y - hs)
	local c = self:sample(x - hs, y + hs)
	local d = self:sample(x + hs, y + hs)

	self:set(x, y, ((a + b + c + d) / 4.0) + value);
	--self:set(x,y,1)
end

function Terrain:sampleDiamond(x, y, size, value)
	local hs = size / 2;
	assert(hs == math.floor(hs))

	--    c
	--
	--a   x	  b
	--
	--    d

	local a = self:sample(x - hs, y);
	local b = self:sample(x + hs, y);
	local c = self:sample(x, y - hs);
	local d = self:sample(x, y + hs);

	self:set(x, y, ((a + b + c + d) / 4.0) + value);
	--self:set(x,y,0)
end

function Terrain:diamondSquarePass(stepsize, scale)
	local halfstep = stepsize / 2;

	local h = self.height
	local w = self.width

	for y=halfstep+1, h+halfstep, stepsize do
		for x=halfstep+1, w+halfstep, stepsize do
			self:sampleSquare(x,y,stepsize, random()*scale)
		end
	end

	for y=1, h, stepsize do
		for x=1, w, stepsize do
			self:sampleDiamond(x + halfstep, y, stepsize, random() * scale)
			self:sampleDiamond(x, y + halfstep, stepsize, random() * scale)
		end
	end

end

function Terrain:normalize()
	local min, max = math.huge, 0

	for y=1,self.height do
		for x=1,self.width do
			local v = self:sample(x,y)
			if v < min then 
				min = v
			end

			if v > max then
				max = v
			end
		end
	end

	for y=1,self.height do
		for x=1,self.width do
			local v = self:sample(x,y)

			self:set(x,y, (v - min)/(max - min), true)
		end
	end	
end

function Terrain:fillDiamondSquare(initialscale, magic, scalemod, scalemodmod)
	local samplesize = self.featuresize

	--initialize sparse points
	for y=1, self.height, samplesize do
		for x=1,self.width, samplesize do
			local r = random()
			--print(r)
			self:set(x,y, r, true)
		end
	end

	local scale = initialscale

	while samplesize > 1 do

		self:diamondSquarePass(samplesize, scale)

		samplesize = samplesize / 2;
		scale = scale * (scalemod + magic);
		scalemod = scalemod * scalemodmod;
	end
	self:normalize()
end

function Terrain:convert(convertfunc)
	for y=1,self.height do
		for x=1,self.width do
			local v = self:sample(x,y)
			self:set(x,y,convertfunc(v), true)
		end
	end
end

function Terrain:draw(size, colorfunc, plotfunc)
	love.graphics.push()

	love.graphics.setPoint(size, "rough")

	for y=1,self.height do
		for x=1,self.width do
			local v = self:sample(x,y)
			assert( v~= 0 )
			if v ~= 0 then
				love.graphics.setColor(colorfunc(v))
				plotfunc(x-1,y-1,size)
			end
		end
	end

	love.graphics.pop()
end

return Terrain