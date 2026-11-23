--!strict
-- 公共契约集中于此。
export type EggChaseRulesRow = {
    id: number, playerWalkSpeed: number, holdSeconds: number, reach: number, attackRadius: number, knockbackSpeed: number, knockbackLift: number, droppedLifetime: number,
}
export type EggGuardSpeedsRow = { regionId: number, guardSpeed: number }
export type EggSpawnRegion = {
    regionId: number, regionName: string, activeCount: number, respawnSeconds: number,
}
export type EggSpawnOption = {
    regionId: number, eggId: string, eggName: string, ponyId: string, chancePercent: number,
}
export type ErrorResult = { code: number, data: any? }

-- 动态参数校验边界；业务接口仍须声明具体类型。
export type ArgEntry = {
    name: string,
    value: any,
    expected: string,
    optional: boolean?,
    min: number?,
    max: number?,
    integer: boolean?,
    nonEmpty: boolean?,
}
export type ArgSpec = { ArgEntry }

return {}
