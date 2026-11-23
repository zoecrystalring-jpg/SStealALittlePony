--!strict
local ServerStorage = game:GetService("ServerStorage")
local DataTypes = require(game:GetService("ReplicatedStorage").Scripts.tools.DataTypes)
local Validate = require(game:GetService("ReplicatedStorage").Scripts.tools.Validate)
local regions = require(script.Parent.EggSpawnRegions)
local pool = require(script.Parent.EggSpawnPool)

local EggSpawnManager = {}
local random = Random.new()
local initialized = false

type Choice = { template: Model, lastTicket: number }

-- 先检查所有区域，再把编辑态的蛋图转为模板，避免配置出错时留下半张地图。
local function prepare(config: DataTypes.EggSpawnRegion, region: Instance, libraryRoot: Folder): () -> ()
    assert(Validate.args("EggSpawn.prepare", {
        { name = "config", value = config, expected = "table" },
        { name = "region", value = region, expected = "Instance" },
        { name = "libraryRoot", value = libraryRoot, expected = "Instance" },
    }))
    assert(Validate.args("EggSpawn.region", {
        { name = "regionId", value = config.regionId, expected = "number", min = 1, integer = true },
        { name = "regionName", value = config.regionName, expected = "string", nonEmpty = true },
        { name = "activeCount", value = config.activeCount, expected = "number", min = 1, integer = true },
        { name = "respawnSeconds", value = config.respawnSeconds, expected = "number", min = 0 },
    }))
    assert(region:GetAttribute("RegionId") == config.regionId, region.Name)
    local nests = region:FindFirstChild("EggNests")
    assert(nests and nests:IsA("Folder"), region.Name .. " 缺少 EggNests")
    local pivots: { [number]: CFrame } = {}
    local freeSlots: { number } = {}
    local templates: { [string]: Model } = {}
    for _, model in nests:GetChildren() do
        assert(model:IsA("Model"), model.Name)
        local slot = model:GetAttribute("Slot")
        local id = model:GetAttribute("EggId")
        assert(typeof(slot) == "number" and slot > 0 and slot % 1 == 0 and not pivots[slot], model.Name)
        assert(typeof(id) == "string" and not templates[id], model.Name)
        pivots[slot] = model:GetPivot()
        table.insert(freeSlots, slot)
        templates[id] = model
    end
    assert(config.activeCount <= #freeSlots, region.Name .. " 蛋巢不足")

    local choices: { Choice } = {}
    local total = 0
    for _, option in pool do
        if option.regionId ~= config.regionId then continue end
        local template = templates[option.eggId]
        assert(template and template:GetAttribute("PonyId") == option.ponyId, option.eggId)
        assert(Validate.args("EggSpawn.chance", {
            { name = "chancePercent", value = option.chancePercent, expected = "number", min = 0, max = 100 },
        }))
        local tickets = math.round(option.chancePercent * 100)
        assert(math.abs(option.chancePercent * 100 - tickets) < 0.000001, option.eggId)
        total += tickets
        table.insert(choices, { template = template, lastTicket = total })
    end
    assert(total == 10000, region.Name .. " 概率之和必须为 100%")
    local occupied: { [Instance]: number } = {}

    local function spawnOne()
        if not nests:IsDescendantOf(workspace) then return end
        local slotIndex = random:NextInteger(1, #freeSlots)
        local slot = table.remove(freeSlots, slotIndex) :: number
        local ticket = random:NextInteger(1, total)
        for _, choice in choices do
            if ticket <= choice.lastTicket then
                local egg = choice.template:Clone()
                egg.Name = string.format("Nest%02d", slot)
                egg:SetAttribute("Slot", slot)
                egg:SetAttribute("RegionId", config.regionId)
                egg:PivotTo(pivots[slot])
                occupied[egg] = slot
                egg.Parent = nests
                return
            end
        end
    end

    return function()
        local library = Instance.new("Folder")
        library.Name = region.Name
        library.Parent = libraryRoot
        for _, template in templates do
            template.Parent = library
        end
        nests.ChildRemoved:Connect(function(egg: Instance)
            if not Validate.args("EggSpawn.childRemoved", {
                { name = "egg", value = egg, expected = "Instance" },
            }) then return end
            local slot = occupied[egg]
            if not slot then return end
            occupied[egg] = nil
            table.insert(freeSlots, slot)
            task.delay(config.respawnSeconds, spawnOne)
        end)
        for _ = 1, config.activeCount do spawnOne() end
    end
end

function EggSpawnManager.initialize()
    if initialized then return end
    local sceneRegions = workspace.PonyEggScene.Regions
    local library = Instance.new("Folder")
    library.Name = "EggSpawnTemplates"
    local starters: { () -> () } = {}
    for _, config in regions do
        local region = sceneRegions:FindFirstChild(string.format("Region%02d", config.regionId))
        assert(region, config.regionName .. " 缺少场景")
        table.insert(starters, prepare(config, region, library))
    end
    library.Parent = ServerStorage
    initialized = true
    for _, start in starters do start() end
end

return EggSpawnManager
