--!native
--!optimize 2

--[[
	[LOCAL EXT] Recycled-thread dispatcher.

	Extracted from process/read.luau so that both the network read path and the
	local (same-side) dispatch path (packet.sendToLocal) can share one recycled
	coroutine pool instead of allocating a thread per listener call.

	Behaviour is identical to the original inline implementation in read.luau.
]]

local threadPool = {}

local freeThread: thread?

local function functionPasser(callback, ...)
	local aquiredThread = freeThread
	freeThread = nil
	callback(...)
	freeThread = aquiredThread
end

local function yielder()
	while true do
		functionPasser(coroutine.yield())
	end
end

-- Run a callback on a recycled thread (fire-and-forget).
function threadPool.spawn(callback, ...)
	if freeThread == nil then
		freeThread = coroutine.create(yielder)
		coroutine.resume(freeThread :: thread)
	end

	task.spawn(freeThread :: thread, callback, ...)
end

return threadPool
