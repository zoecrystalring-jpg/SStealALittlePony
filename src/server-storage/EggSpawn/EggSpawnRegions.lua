--!strict
-- 自动从配置表导出；请修改 Excel / CSV 源表后重新导出。
local DataTypes = require(game:GetService("ReplicatedStorage").Scripts.tools.DataTypes)
local rows: {DataTypes.EggSpawnRegion} = {
	{ ["regionId"] = 1, ["regionName"] = "小马镇", ["activeCount"] = 4, ["respawnSeconds"] = 10 },
	{ ["regionId"] = 2, ["regionName"] = "甜苹果庄园", ["activeCount"] = 4, ["respawnSeconds"] = 10 },
	{ ["regionId"] = 3, ["regionName"] = "音乐庆典街", ["activeCount"] = 4, ["respawnSeconds"] = 10 },
	{ ["regionId"] = 4, ["regionName"] = "云中城赛场", ["activeCount"] = 4, ["respawnSeconds"] = 10 },
	{ ["regionId"] = 5, ["regionName"] = "星光魔法学院", ["activeCount"] = 4, ["respawnSeconds"] = 10 },
	{ ["regionId"] = 6, ["regionName"] = "永恒魔法森林", ["activeCount"] = 4, ["respawnSeconds"] = 10 },
	{ ["regionId"] = 7, ["regionName"] = "珊瑚海王国", ["activeCount"] = 4, ["respawnSeconds"] = 10 },
	{ ["regionId"] = 8, ["regionName"] = "水晶帝国", ["activeCount"] = 4, ["respawnSeconds"] = 10 },
	{ ["regionId"] = 9, ["regionName"] = "月影梦境城", ["activeCount"] = 4, ["respawnSeconds"] = 10 },
	{ ["regionId"] = 10, ["regionName"] = "龙焰与虫巢", ["activeCount"] = 4, ["respawnSeconds"] = 10 },
	{ ["regionId"] = 11, ["regionName"] = "皇家传奇殿堂", ["activeCount"] = 4, ["respawnSeconds"] = 10 },
	{ ["regionId"] = 12, ["regionName"] = "和谐星辉圣域", ["activeCount"] = 4, ["respawnSeconds"] = 10 },
}
return rows
