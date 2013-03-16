local tools = {}
tools.__index = tools

local rect = {}
rect.__index = rect

function rect:new(l,t,r,b)
	local r = {
		x = l,
		y = t,
		width = r - l,
		height = b - t,
	}
	--print("rect", r.x,r.width,r.y,r.height)
	setmetatable(r, rect)

	return r
end

function rect:draw(mode)
	love.graphics.rectangle(mode or "fill", self.x, self.y, self.width, self.height)
end

function rect:contains(x,y)
	if x >= self.x and x <= self.x + self.width 
		and y >= self.y and y <= self.y + self.height then
		return true
	end
end

function rect:center()
	return self.x + self.width/2, self.y + self.height/2
end

function rect:halfsize()
	return self.width/2, self.height/2
end

function tools:rect(x1,x2,y1,y2)
	--print("in",x1,x2,y1,y2)
	local l,t,r,b
	if x2 < x1 then
		l = x2
		r = x1
	else
		l = x1
		r = x2
	end

	if y2 < y1 then
		t = y2
		b = y1
	else
		t = y1
		b = y2
	end

	return rect:new(l,t,r,b)
end

function tools:copy(t)
	if type(t) == "table" then
		local o = {}
		for k,v in pairs(t) do
			o[k] = tools:copy(v)
		end
		return o
	else
		return t
	end
end

function tools:makeClass(super, ...)
	local c = {}

	super.__index = super

	function super:isA(class)
		if class == super or getmetatable(self) == super then
			return true
		end
	end
	
	setmetatable(c, super)

	assert( super.init ~= nil, "Cannot make a class out of a function without init()")

	return c:init(...)
end

function tools:minmax(...)
	local min,max
	for i,v in ipairs(...) do
		if v then
			if not min or v < min then
				min = v
			end
			if not max or v > max then
				max = v
			end
		end
	end
	return min,max
end

function tools:wrap(val, range)
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

function tools:colorGenerator(start, delta, index, dir)
	local c = tools:copy(start) or {255,255,255}
	local orig = tools:copy(start or c)
	local d = delta or 60
	local i = index or math.random(3)
	local n = dir or ((math.random() > 0.5 and -1) or 1)

	return function()
		local r = tools:copy(c)

		c[i] = tools:wrap(c[i] - d, 255)
		i = tools:wrap(i + n, 3)

		-- if c[i] < 0 then
		-- 	if c[i] < 0 then -- we've finished, restart
		-- 		c = tools:copy(orig)
		-- 		c[1] = c[1] - d/2
		-- 		c[2] = c[2] - d/2
		-- 		c[3] = c[3] - d/2
		-- 	end
		-- end
		--print("new color:", unpack(c))
		return tools:copy(c)
	end
end


return tools