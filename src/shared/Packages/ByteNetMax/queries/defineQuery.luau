--!native
--!optimize 2

local types = require(script.Parent.Parent.types)
local query = require(script.Parent.query)

return function(properties: types.queryProperties<any>)
	-- [LOCAL EXT] localOnly is threaded through by defineLocalNamespace
	return function(id: number, localOnly: boolean?)
		return query(properties, id, localOnly)
	end
end