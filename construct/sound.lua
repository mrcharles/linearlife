tools = require "construct.tools"

local soundbank = {}
local streams = {}

local sounddata = {}

local sources = {}

local sound = {}
function sound:loadTable(soundtable)
	if soundtable.static then
		for name,sound in pairs(soundtable.static) do
			if sound.data then
				print("loading static sound", name, sound.data)
				soundbank[name] = love.sound.newSoundData(sound.data)
			end
			assert(sound[name] == nil)
			sounddata[name] = tools:copy(sound)
			sounddata[name].data = "soundbank"
		end
	end
	if soundtable.stream then
		for name,sound in pairs(soundtable.stream) do
			if sound.data then
				print("loading streamed sound", name, sound.data)
				streams[name] = love.audio.newSource(sound.data, "stream")
			end
			assert(sound[name] == nil)
			sounddata[name] = tools:copy(sound)
			sounddata[name].data = "streams"
		end
	end
end

function sound:play(name)
	local s = sounddata[name]

	if not s then print("soound not found") return end

	if s.data == "soundbank" then 
		if soundbank[name] then
			local src = love.audio.newSource(soundbank[name])
			table.insert(sources, src)
			love.audio.play(src)
		end
	else
		local src = streams[name]
		if src then
			love.audio.play(src)
		end
	end
end

--stop only valid on streams
function sound:stop(name)
	local s = sounddata[name]

	if not s then return end

	if s.data == "stream" then
		streams[name]:stop()
	end
end

function sound:update()
	local i = 1

	while i < #sources do
		if sources[i]:isStopped() then
			table.remove(sources, i)
		else
			i = i + 1
		end
	end
end

return sound