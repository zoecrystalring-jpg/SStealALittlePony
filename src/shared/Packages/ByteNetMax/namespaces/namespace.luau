--[[
	The file that contains the function for handling and creating namespaces.
	Namespaces aren't really anything special, they are just an encapsulation to make it easier to manage packets and structs.
	
	Dependency management is fun!
]]

local RunService = game:GetService("RunService")

local values = require(script.Parent.Parent.replicated.values)
local types = require(script.Parent.Parent.types)
local namespacesDependencies = require(script.Parent.namespaceDependencies)
local packetIDs = require(script.Parent.packetIDs)
local queryIDs = require(script.Parent.queryIDs)

local runContext: "server" | "client" = if RunService:IsServer() then "server" else "client"

local count = 0
local queryCount = 0

-- [LOCAL EXT] local-only namespaces get their own id counters and never touch
-- the network packetIDs/queryIDs registries, so a malicious client cannot reach
-- them over the wire even by guessing an id.
local localCount = 0
local localQueryCount = 0

local function defineNamespace(
	name: string,
	input: () -> {
		packets: { [string]: any },
		queries: { [string]: any },
	}
)
	local namespaceReplicator = values.access(name)

	namespacesDependencies.start(name)
	local namespaceInput = input()

	local packets = namespaceInput.packets or {}
	local queries = namespaceInput.queries or {}

	local structs = namespacesDependencies.empty()

	local packetResult = {}
	local queryResult = {}

	if runContext == "server" then
		local constructedNamespace = {
			structs = {},
			packets = {},
			queries = {},
		}

		for key in packets do
			count += 1
			constructedNamespace.packets[key] = count
			packetResult[key] = packets[key](count)

			packetIDs.set(count, packetResult[key])
		end

		for key in queries do
			queryCount += 1
			constructedNamespace.queries[key] = queryCount
			queryResult[key] = queries[key](queryCount)

			queryIDs.set(queryCount, queryResult[key])
		end

		for index, value in structs do
			constructedNamespace.structs[index] = value
		end

		namespaceReplicator:write(constructedNamespace)
	elseif runContext == "client" then
		-- yes, this means that packets technically don't need to be defined on the client
		-- we do it anyway for typechecking and perf shortcuts
		local namespaceData = namespaceReplicator:read() :: types.namespaceData

		for key, packet in packets do
			packetResult[key] = packet(namespaceData.packets[key])

			packetIDs.set(namespaceData.packets[key], packetResult[key])
		end

		for key, query in queries do
			queryResult[key] = query(namespaceData.queries[key])

			queryIDs.set(namespaceData.queries[key], queryResult[key])
		end
	end

	local TotalResult = {
		packets = packetResult,
		queries = queryResult,
	}

	return TotalResult
end

-- [LOCAL EXT] defineLocalNamespace: builds packets/queries for SAME-SIDE use only.
-- No replication (no BytenetStorage StringValue), no packetIDs/queryIDs registration,
-- builders receive localOnly = true. Works identically on server or client; a
-- server-only local namespace is simply required only on the server.
local function defineLocalNamespace(
	name: string,
	input: () -> {
		packets: { [string]: any },
		queries: { [string]: any },
	}
)
	namespacesDependencies.start(name, true)
	local namespaceInput = input()
	namespacesDependencies.empty()

	local packets = namespaceInput.packets or {}
	local queries = namespaceInput.queries or {}

	local packetResult = {}
	local queryResult = {}

	for key in packets do
		localCount += 1
		packetResult[key] = packets[key](localCount, true)
	end

	for key in queries do
		localQueryCount += 1
		queryResult[key] = queries[key](localQueryCount, true)
	end

	return {
		packets = packetResult,
		queries = queryResult,
	}
end

return {
	defineNamespace = defineNamespace,
	defineLocalNamespace = defineLocalNamespace,
}
