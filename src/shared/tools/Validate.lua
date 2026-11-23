--!strict
--[[
	Validate.lua
	公开方法参数校验工具(信任边界处用)。

	约定(见 lemon.md):公开方法在开头校验参数,任一不匹配则 warn 打印
	所有参数(名/类型/值,并标注哪个不合格),调用方据返回的 false 返回安全值/参数错误。

	用法:
	  local Validate = require(ReplicatedStorage.Scripts.tools.Validate)
	  if not Validate.args("DataStoreManager.get", {
	      { name = "player", value = player, expected = "Instance" },
	      { name = "amount", value = amount, expected = "number", min = 1, integer = true },
	  }) then return nil end

	expected 取 typeof() 的返回值:"string" / "number" / "boolean" / "table" /
	"Instance" / "function" 等。Player 实例的 typeof 是 "Instance"。

	number 的隐性保证:expected == "number" 时**自动拒绝 NaN 和 ±inf**。
	  数值字段没有拿到这两种值的正当理由,而且它们会让 min/max 比较静默失效
	  (NaN < x、math.huge < x 都为 false),放进货币/背包等系统会静默污染数据。
	  这是 fail closed,不需要每个调用方自己判。

	可选约束(都可省;类型不匹配时不生效,先过类型这关):
	  · optional = true   —— value 为 nil 时直接放行(其余情况仍按 expected 校验)
	  · min / max         —— number 的闭区间边界(含端点)
	  · integer = true    —— number 必须是整数
	  · nonEmpty = true   —— string 不能是空串
]]

local DataTypes = require(script.Parent.DataTypes)
type ArgEntry = DataTypes.ArgEntry
type ArgSpec = DataTypes.ArgSpec
local Validate = {}

--[[
	校验单个参数。合格返回 nil,不合格返回一句中文原因(用于 warn)。
]]
local function checkOne(s: ArgEntry): string?
	local value = s.value

	-- optional:nil 直接放行(非 nil 仍要过下面的校验)
	if value == nil and s.optional then
		return nil
	end

	local t = typeof(value)
	if t ~= s.expected then
		return `应为 {s.expected}`
	end

	if t == "number" then
		--[[
			先挡掉 NaN / ±inf。放到 min/max 之前 —— 否则 NaN 会因为
			所有比较都为 false 而"通过"边界检查。
		]]
		if value ~= value then
			return "不能是 NaN"
		end
		if value == math.huge or value == -math.huge then
			return "不能是无穷大"
		end
		if s.integer and value % 1 ~= 0 then
			return `必须是整数,当前 {value}`
		end
		if s.min ~= nil and value < s.min then
			return `不能小于 {s.min},当前 {value}`
		end
		if s.max ~= nil and value > s.max then
			return `不能大于 {s.max},当前 {value}`
		end
	elseif t == "string" then
		if s.nonEmpty and value == "" then
			return "不能是空字符串"
		end
	end

	return nil
end

-- 校验一组参数;任一不合格则打印全部参数(标注 ✓/✗ 及原因),返回 false
function Validate.args(context: string, spec: ArgSpec): boolean
	local ok = true
	for _, s in spec do
		if checkOne(s) ~= nil then
			ok = false
			break
		end
	end

	if not ok then
		warn(`[{context}] 参数校验失败`)
		for _, s in spec do
			local reason = checkOne(s)
			if reason then
				warn(`  ✗ {s.name}:`, typeof(s.value), s.value, `({reason})`)
			else
				warn(`  ✓ {s.name}:`, typeof(s.value), s.value)
			end
		end
	end

	return ok
end

return Validate
