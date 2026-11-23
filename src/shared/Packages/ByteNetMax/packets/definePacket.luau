--!native
--!optimize 2

--[[
	Exists so that the namespace can set the ID of the packet

	Packet shouldnt need to care about making its own ID
]]
local types = require(script.Parent.Parent.types)
local packet = require(script.Parent.packet)

return function(props: types.packetProps<any>)
	-- [LOCAL EXT] localOnly is threaded through by defineLocalNamespace
	return function(id: number, localOnly: boolean?)
		return packet(props, id, localOnly)
	end
end
