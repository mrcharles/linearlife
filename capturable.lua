local Tools = require 'construct.tools'

Capturable = Tools:Class()

function Capturable:capture(func)
	if self.debug then
		self._capture_todo = self._capture_todo or {}

		table.insert(self._capture_todo, func)
	else
		func()
	end
end

function Capturable:step(...)
	if not self._done_playback then
		self._playback_index = self._playback_index or 1

		local ret = self._capture_todo[self._playback_index](...)

		self._playback_index = self._playback_index + 1
		if self._playback_index > #self._capture_todo then
			self._done_playback = true
		end

		return ret
	else
		return true
	end
end


