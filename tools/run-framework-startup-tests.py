"""Verify the egg-spawn entrypoint and guard against legacy startup or player data access.

Usage: python tools/run-framework-startup-tests.py PATH_TO_LUAU
Runs local Luau only; never connects to Studio or Roblox services.
"""
from pathlib import Path
import csv
from decimal import Decimal
import json
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
ENTRYPOINTS = {
    "src/server/ServerMain.server.lua",
    "src/client/Main.client.lua",
}


def check_egg_regions():
    layout = json.loads((ROOT / "assets/egg-spawns/Regions.project.json").read_text(encoding="utf-8"))["tree"]
    def rows(name):
        with (ROOT / "configSource" / f"{name}.csv").open(encoding="utf-8-sig", newline="") as source:
            return list(csv.DictReader(source))

    regions = rows("EggSpawnRegions")
    options = rows("EggSpawnPool")
    region_ids = {int(row["regionId"]) for row in regions}
    assert region_ids == {r["$attributes"]["RegionId"] for k, r in layout.items() if not k.startswith("$")}
    assert {int(row["regionId"]) for row in options} == region_ids
    assert len({row["eggId"] for row in options}) == len(options)
    for row in regions:
        region = layout[f'Region{int(row["regionId"]):02}']
        assert region["$attributes"]["DisplayName"] == row["regionName"]
        pool = [opt for opt in options if opt["regionId"] == row["regionId"]]
        assert len(pool) == 8 and 0 < int(row["activeCount"]) <= 8
        assert int(row["respawnSeconds"]) >= 0
        chances = [Decimal(opt["chancePercent"]) for opt in pool]
        assert min(chances) >= 0 and sum(chances) == 100


def main():
    check_egg_regions()
    if len(sys.argv) != 2:
        raise SystemExit("Usage: run-framework-startup-tests.py PATH_TO_LUAU")
    luau = Path(sys.argv[1]).resolve()
    scripts = {
        path.relative_to(ROOT).as_posix()
        for path in (ROOT / "src").rglob("*")
        if path.is_file()
        and path.name.endswith((".server.lua", ".client.lua", ".server.luau", ".client.luau"))
    }
    assert scripts == ENTRYPOINTS, f"Unexpected executable scripts: {scripts ^ ENTRYPOINTS}"

    manifest = json.loads((ROOT / "tools/config-puller/sources.json").read_text(encoding="utf-8"))
    assert {entry["name"] for entry in manifest["tables"]} == {"EggSpawnRegions", "EggSpawnPool"}, "Legacy export tables are still registered"
    for directory, allowed in (("configSource", {".gitkeep", "EggSpawnRegions.csv", "EggSpawnPool.csv"}), ("src/shared/config", {"init.meta.json"})):
        unexpected = [p for p in (ROOT / directory).rglob("*") if p.is_file() and p.name not in allowed]
        assert not unexpected, f"Legacy configuration files remain: {unexpected}"

    project = json.loads((ROOT / "default.project.json").read_text(encoding="utf-8"))
    mapped_paths = set()

    def inspect(node):
        if not isinstance(node, dict):
            return
        if "$path" in node:
            path = (ROOT / node["$path"]).resolve()
            path.relative_to(ROOT)
            assert path.exists(), f"Missing Rojo path: {path}"
            mapped_paths.add(node["$path"])
        for value in node.values():
            inspect(value)

    inspect(project["tree"])
    assert mapped_paths == {
        "src/server", "src/client", "src/shared", "src/server-storage",
        "src/replicated-first", "src/gui", "src/workspace", "assets/egg-spawns/Regions.project.json",
    } | {f"assets/pony-ui/{name}.project.json" for name in (
        "MainGui", "currencyGui", "GrowingEggsGui", "ActivePoniesGui", "PonyYardGui",
        "ShopGui", "TrainingGui", "SellPoniesGui", "PonyIndexGui", "TrailsGui", "WorldMapGui",
    )}, f"Unexpected legacy asset or script mappings: {mapped_paths}"

    harness = ["""--!nonstrict
local function forbidden()
    error("Empty startup attempted to access a service, dependency, or scheduler", 2)
end
local blocked = setmetatable({}, { __index = forbidden, __newindex = forbidden })
local game, workspace, task, script, Instance, Enum = blocked, blocked, blocked, blocked, blocked, blocked
local require = forbidden
local started = 0
local manager = { initialize = function() started += 1 end }
local function runServer()
local game = { GetService = function(_, name)
    assert(name == "ServerStorage")
    return { Scripts = { EggSpawn = { EggSpawnManager = manager } } }
end }
local function require(module) assert(module == manager) return manager end
"""
    ]
    harness.append((ROOT / "src/server/ServerMain.server.lua").read_text(encoding="utf-8"))
    harness.append("\nend\nrunServer()\nassert(started == 1)\nlocal function runClient()\n")
    harness.append((ROOT / "src/client/Main.client.lua").read_text(encoding="utf-8"))
    harness.append("\nend\nrunClient()\nlocal function loadProtocols()\n")
    harness.append((ROOT / "src/shared/network/init.lua").read_text(encoding="utf-8"))
    harness.append('\nend\nassert(next(loadProtocols()) == nil, "Business protocols remain")\nprint("PASS: egg-spawn server and empty client startup, no network or datastore access")\n')
    generated = ROOT / "build/empty-startup-test.luau"
    generated.parent.mkdir(parents=True, exist_ok=True)
    generated.write_text("".join(harness), encoding="utf-8")
    subprocess.run([str(luau), str(generated)], check=True, cwd=ROOT)
    print("PASS: script inventory, configuration cleanup, and Rojo mapping")


if __name__ == "__main__":
    main()
