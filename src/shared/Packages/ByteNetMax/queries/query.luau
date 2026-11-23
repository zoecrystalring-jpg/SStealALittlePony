--!native
--!optimize 2
local RunService = game:GetService("RunService")

local types = require(script.Parent.Parent.types)
local client = require(script.Parent.Parent.process.client)

local moduleRunContext: "server" | "client" = if RunService:IsServer() then "server" else "client"

-- [LOCAL EXT] added `localOnly` param: local-only queries (defineLocalNamespace)
-- skip the network invoke and only expose invokeToLocal/listen.
return function(properties: types.queryProperties<types.dataTypeInterface<any>, types.dataTypeInterface<any>>, id: number, localOnly: boolean?)
	local listeners: {types.QueryListener<any, any>} = {}

	local clientInvokeFunction: (id: number, requestWriter: (value: any) -> (), data: any) -> any = client.invoke

	local requestWriter = properties.request.write

	local exported = {}
	exported.requestReader = properties.request.read
	exported.responseReader = properties.response.read
	exported.responseWriter = properties.response.write

	-- [LOCAL EXT] guard: block network invoke on local-only queries
	setmetatable(exported, {
		__index = function(index)
			if localOnly and index == "invoke" then
				error("[ByteNetMax] This query is local-only (defineLocalNamespace); use invokeToLocal instead.")
			end
		end,
	})

	-- [LOCAL EXT] invokeToLocal: same-side request/response, NO serialization,
	-- NO yielding. Calls the single registered local handler synchronously and
	-- returns its result directly. The handler receives (request, nil).
	function exported.invokeToLocal(request)
		local handler = listeners[1]
		if handler == nil then
			warn("[ByteNetMax] invokeToLocal called but no local handler is registered.")
			return nil
		end
		if #listeners > 1 then
			warn("[ByteNetMax] invokeToLocal: multiple handlers registered; only the first responds.")
		end

		local response = handler.Callback(request, nil)

		if handler.OnceCallback == true then
			exported.disconnect(handler)
		end

		return response
	end

	if not localOnly and moduleRunContext == "client" then
		function exported.invoke(data)
			local response = clientInvokeFunction(id, requestWriter, data)

			return response
		end
	end

	function exported.wait()
		-- use a OnceCallback for this still
		local runningThread = coroutine.running()
		table.insert(listeners, {
			Callback = function(data, player)
				task.spawn(runningThread, data, player)
			end,
			OnceCallback = true
		})

		return coroutine.yield()
	end
	
	function exported.listen(callback)
		local listener = {
			Callback = callback,
			OnceCallback = false	
		}
		table.insert(listeners, listener)

		return function()
			exported.disconnect(listener)
		end
	end
	
	function exported.disconnectAll()
		table.clear(listeners)
	end
	
	function exported.disconnect(listener)
		-- Ensure the index isn't nil to avoid removing arbitrary listeners
		local index = table.find(listeners, listener)
		if index ~= nil then
			table.remove(listeners, index)
		else
			warn('Query listener was already disconnected.')
		end
	end
	
	function exported.listenOnce(callback)
		local listener = {
			Callback = callback,
			OnceCallback = true	
		}
		table.insert(listeners, listener)

		return function()
			exported.disconnect(listener)
		end
	end
	
	function exported.getListeners()
		return listeners
	end
	
	return exported
end