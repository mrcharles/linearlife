local BlobDetector = require 'blobdetector'

require 'cellularautomata'

local function makeTest()
	local cavetest = {}

	local function caveparams(map,x,y)
		local alive = 0

		if x > 1 then
			if map:get(x-1,y) == 1 then
				alive = alive + 1
			end

			if y > 1 then
				if map:get(x-1,y-1) == 1 then
					alive = alive + 1
				end
			end

			if y < map.height then
				if map:get(x-1,y+1) == 1 then
					alive = alive + 1
				end
			end
		end

		if x < map.width then
			if map:get(x+1,y) == 1 then
				alive = alive + 1
			end

			if y > 1 then
				if map:get(x+1,y-1) == 1 then
					alive = alive + 1
				end
			end

			if y < map.height then
				if map:get(x+1,y+1) == 1 then
					alive = alive + 1
				end
			end
		end

		if y > 1 then
			if map:get(x,y-1) == 1 then
				alive = alive + 1
			end
		end

		if y < map.height then
			if map:get(x,y+1) == 1 then
				alive = alive + 1
			end
		end

		return 8 - alive
	end

	local function caveset(dead)
		if dead < 4 then
			return true
		end
	end

	local function caveclear(dead)
		if dead > 4 then
			return true
		end
	end

	local caveblob
	local caves
	local plot,size

	function caveiterate(x,y,v)
		if v == 1 then
			caveblob:markBlob4Way(x,y)
		end
	end

	function cavetest.init()
	end

	function cavetest.setDraw(_plot,_size)
		plot = _plot
		size = _size
	end

	function cavetest:enter(prev,w,h)
		caveblob = BlobDetector:new(w,h)
		caves = CellularAutomata:new(w,h, 10, 0.49, caveclear,caveset,caveparams)
		caves.data:iterate(caveiterate)
		self.blobs = caveblob:crunch()

		local function sort(a,b)
			if a.size > b.size then
				return true
			end
		end
		table.sort(self.blobs, sort)
	end

	local blobidx = 1
	local highlight
	function cavetest:keypressed(key)
		if key == " " then
			highlight = not highlight
		end

		if key == "right" then
			blobidx = math.min(blobidx + 1, #self.blobs)
		end
		if key == "left" then
			blobidx = math.max(blobidx - 1, 1)
		end
	end

	function cavetest:draw()
		--print('draw')
		caves:draw(size,plot)

		if highlight then
			love.graphics.setColor(255,0,0)
			self.blobs[blobidx]:draw(size, plot)
		--caveblob:draw(size, plot)
		end
	end

	return cavetest
end

return makeTest()