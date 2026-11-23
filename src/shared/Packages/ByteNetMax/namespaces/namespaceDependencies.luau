--[[
	Basic dependency graph for structs created within a namespace
]]

local current: { [number]: any }?
local currentName: string
local currentIsLocal: boolean = false -- [LOCAL EXT]

local namespacesDependencies = {}

-- [LOCAL EXT] added `isLocal` so struct.luau can skip replication for local namespaces
function namespacesDependencies.start(name: string, isLocal: boolean?)
	current = {} :: { [number]: any }
	currentName = name
	currentIsLocal = isLocal == true
end

-- [LOCAL EXT] whether the namespace currently being defined is local-only
function namespacesDependencies.isLocal(): boolean
	return currentIsLocal
end

function namespacesDependencies.add(data)
	if not current then
		return
	end

	table.insert(current, data)
end

function namespacesDependencies.currentLength()
	return if current then #current else 0
end

function namespacesDependencies.currentName()
	return currentName
end

function namespacesDependencies.empty(): { [number]: any }
	if current == nil then
		return {}
	end

	local result = current
	current = nil

	return result
end

return namespacesDependencies
