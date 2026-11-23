--!strict
-- ConfigHelper.lua
-- 配置表统一访问入口:懒加载 + 缓存
--
-- 用法:
--   local ConfigHelper = require(ReplicatedStorage.Scripts.tools.ConfigHelper)
--
--   -- 取整张表(默认是数组,可配合类型断言拿回类型):
--   local levels = ConfigHelper.get("LevelConfig")
--
--   -- 逐层下钻(按数组下标 / key):
--   local firstName = ConfigHelper.get("LevelConfig", 1, "name")
--
-- 说明:
--   配置表是 configSource/ 下的 Excel 经 pull_config.py 生成的 .json,
--   由 Rojo 同步时转成 ModuleScript。这里第一次用到才 require,并缓存复用。

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local configFolder = ReplicatedStorage.Scripts.config

local ConfigHelper = {}

-- 已加载的配置表缓存:configName -> 该表数据
local cache: { [string]: any } = {}

-- 懒加载:第一次用到某张表才 require,之后走缓存
local function loadConfig(name: string): any
	local cached = cache[name]
	if cached ~= nil then
		return cached
	end

	local moduleScript = configFolder:FindFirstChild(name)
	if not moduleScript or not moduleScript:IsA("ModuleScript") then
		error(`[ConfigHelper] 找不到配置表 "{name}"(应位于 ReplicatedStorage.Scripts.config.{name})`, 2)
	end

	local data = require(moduleScript)
	cache[name] = data
	return data
end

-- 取配置:不传路径返回整表,传路径则按 key / 数组下标逐层下钻
-- 任意一层取到 nil 就直接返回 nil,不会报错
function ConfigHelper.get(name: string, ...: any): any
	local node: any = loadConfig(name)
	for _, key in { ... } do
		if node == nil then
			return nil
		end
		node = node[key]
	end
	return node
end

return ConfigHelper
