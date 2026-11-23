--!strict
-- 自动从配置表导出；请修改 Excel / CSV 源表后重新导出。
local DataTypes = require(game:GetService("ReplicatedStorage").Scripts.tools.DataTypes)
local rows: {DataTypes.EggChaseRulesRow} = {
	{ ["id"] = 1, ["playerWalkSpeed"] = 16, ["holdSeconds"] = 2, ["reach"] = 9, ["attackRadius"] = 5, ["knockbackSpeed"] = 46, ["knockbackLift"] = 32, ["droppedLifetime"] = 75 },
}
return rows
