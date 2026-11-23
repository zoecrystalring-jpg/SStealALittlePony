--!strict
-- 自动从配置表导出；请修改 Excel / CSV 源表后重新导出。
local DataTypes = require(game:GetService("ReplicatedStorage").Scripts.tools.DataTypes)
local rows: {DataTypes.EggGuardSpeedsRow} = {
	{ ["regionId"] = 1, ["guardSpeed"] = 14 },
	{ ["regionId"] = 2, ["guardSpeed"] = 15 },
	{ ["regionId"] = 3, ["guardSpeed"] = 16 },
	{ ["regionId"] = 4, ["guardSpeed"] = 17 },
	{ ["regionId"] = 5, ["guardSpeed"] = 18 },
	{ ["regionId"] = 6, ["guardSpeed"] = 19 },
	{ ["regionId"] = 7, ["guardSpeed"] = 20 },
	{ ["regionId"] = 8, ["guardSpeed"] = 21 },
	{ ["regionId"] = 9, ["guardSpeed"] = 22 },
	{ ["regionId"] = 10, ["guardSpeed"] = 23 },
	{ ["regionId"] = 11, ["guardSpeed"] = 24 },
	{ ["regionId"] = 12, ["guardSpeed"] = 25 },
}
return rows
