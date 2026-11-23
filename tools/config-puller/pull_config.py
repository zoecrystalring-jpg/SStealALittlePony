#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
pull_config.py — 把 configSource/ 下的 Excel / CSV 表转成项目里的 JSON / Luau 配置。

数据流:
    钉钉文档表格  --(手动导出)-->  configSource/*.xlsx / *.csv
                 --(本脚本)-->    src/shared/config/*.json
                 --(Rojo)-->      Roblox 里的 ModuleScript

清单文件 sources.json 描述每张表怎么转(源文件、sheet、输出名等)。

Excel 约定:
    - 第 headerRow 行(默认第 1 行)是表头,每列的表头名 = JSON 里的字段名。
    - 表头行之后是数据行,一行一条记录。
    - 生成的永远是「数组」(顺序表),保证顺序;wrapKey 非空时再包一层。
    - 可选:typeRow 指定一行做「类型行」,强制某列的类型
      (如 id 想固定为字符串,避免 "001" 被当成数字)。留 0 表示不用,自动推断。

用法:
    python pull_config.py                # 转清单里所有表
    python pull_config.py --only LevelConfig  # 只转指定表(可多个)
    python pull_config.py --manifest path/to/sources.json
"""

import argparse
import csv
import datetime
import json
import math
import re
import sys
from pathlib import Path

try:
    import openpyxl
except ImportError:
    sys.exit("缺少依赖 openpyxl,请先运行: pip install -r requirements.txt")

# Windows 终端默认 GBK,强制 stdout 用 UTF-8,避免中文提示乱码
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")


# 脚本位于 tools/config-puller/,项目根目录是它上两级
SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent.parent


def coerce(value, type_hint):
    """按类型行的提示强制转换单元格值;type_hint 为空则原样返回。"""
    if value is None:
        return None
    if not type_hint:
        # 自动推断:openpyxl 已给出原生类型,只把日期转成字符串
        if isinstance(value, (datetime.datetime, datetime.date)):
            return value.isoformat()
        return value

    hint = str(type_hint).strip().lower()
    if hint in ("str", "string", "text"):
        return str(value)
    if hint in ("int", "integer"):
        return int(float(value))
    if hint in ("float", "number", "double"):
        return float(value)
    if hint in ("bool", "boolean"):
        return str(value).strip().lower() in ("1", "true", "yes", "y", "是", "真")
    if hint == "json":
        # 单元格里存的是 JSON 字符串(嵌套结构),解析成对象/数组
        return json.loads(value) if isinstance(value, str) and value.strip() else value
    # 未知提示,原样返回
    return value


def read_table(entry, source_dir):
    """读一张 Excel / UTF-8 CSV 表,返回记录列表(list[dict])。"""
    file_path = source_dir / entry["file"]
    if not file_path.exists():
        raise FileNotFoundError(f'源文件不存在: {file_path}')

    if file_path.suffix.lower() == ".csv":
        # UTF-8 BOM、带引号的逗号/换行由 csv 模块处理；空单元格与 Excel 保持一致。
        with file_path.open(encoding="utf-8-sig", newline="") as source:
            rows = [[cell if cell.strip() else None for cell in row] for row in csv.reader(source)]
    else:
        wb = openpyxl.load_workbook(file_path, data_only=True)
        try:
            sheet_name = entry.get("sheet")
            ws = wb[sheet_name] if sheet_name else wb.active
            rows = list(ws.iter_rows(values_only=True))
        finally:
            wb.close()
    if not rows:
        return []

    header_row = entry.get("headerRow", 1)
    type_row = entry.get("typeRow", 0)

    headers = [str(h).strip() if h is not None else None for h in rows[header_row - 1]]
    aliases = entry.get("columnAliases", {})
    headers = [aliases.get(header, header) for header in headers]
    named_headers = [header for header in headers if header]
    if len(set(named_headers)) != len(named_headers):
        raise ValueError("字段名重复（含 columnAliases 映射后的字段）")
    explicit_types = entry.get("types", {})
    type_hints = None
    if type_row and type_row >= 1:
        raw_types = rows[type_row - 1]
        type_hints = [raw_types[i] if i < len(raw_types) else None for i in range(len(headers))]

    data_start = max(header_row, type_row)  # 数据从表头/类型行之后开始

    records = []
    for row in rows[data_start:]:
        record = {}
        has_value = False
        for i, header in enumerate(headers):
            if not header:
                continue
            cell = row[i] if i < len(row) else None
            hint = explicit_types.get(header, type_hints[i] if type_hints else None)
            converted = coerce(cell, hint)
            if converted is not None:
                has_value = True
            record[header] = converted
        # 整行都空则跳过(常见于表格末尾的空行)
        if has_value:
            records.append(record)

    # 可选:某列必须唯一(如 AnimationConfig 的 masterKey)。重复即硬报错,不静默生成坏表。
    unique_key = entry.get("uniqueKey")
    if unique_key:
        seen = set()
        for rec in records:
            value = rec.get(unique_key)
            if value in seen:
                raise ValueError(
                    f'"{unique_key}" 列出现重复值 {value!r},该列要求唯一'
                )
            seen.add(value)

    return records


def build_output(entry, records):
    """按 wrapKey 决定输出结构:有则包一层,无则直接是数组。"""
    wrap_key = entry.get("wrapKey")
    if wrap_key:
        return {wrap_key: records}
    return records


def serialize_output(entry, output):
    """默认 JSON；服务器配置可指定 luau，且只接受标量记录数组。"""
    output_format = entry.get("format", "json")
    if output_format == "json":
        return json.dumps(output, ensure_ascii=False, indent=2)
    if output_format != "luau" or not isinstance(output, list):
        raise ValueError("仅支持 JSON 或 Luau 标量记录数组")

    def literal(value):
        if value is None:
            return "nil"
        if isinstance(value, bool):
            return "true" if value else "false"
        if isinstance(value, (int, float)) and math.isfinite(value):
            return str(int(value)) if value == int(value) else repr(value)
        if isinstance(value, str):
            # 使用十进制字节转义控制字符，避免 JSON 的 \\uXXXX 不是 Luau 语法。
            return '"' + ''.join(
                '\\\\' if char == '\\' else '\\"' if char == '"'
                else f"\\{ord(char):03d}" if ord(char) < 32 else char
                for char in value
            ) + '"'
        raise ValueError(f"Luau 配置只支持有限数字、字符串、布尔值或空值: {value!r}")

    lines = ["--!strict", "-- 自动从配置表导出；请修改 Excel / CSV 源表后重新导出。"]
    luau_type = entry.get("luauType")
    if luau_type:
        if not isinstance(luau_type, str) or not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", luau_type):
            raise ValueError("luauType 必须是 DataTypes 中的类型名称")
        lines += ['local DataTypes = require(game:GetService("ReplicatedStorage").Scripts.tools.DataTypes)',
                  f"local rows: {{DataTypes.{luau_type}}} = {{"]
    else:
        lines.append("return {")
    for record in output:
        if not isinstance(record, dict):
            raise ValueError("Luau 配置的每一行必须是记录")
        if any(not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", key) for key in record):
            raise ValueError("Luau 配置字段名必须是标识符")
        fields = ', '.join(f'[{literal(key)}] = {literal(value)}' for key, value in record.items())
        lines.append("\t{ " + fields + " },")
    return '\n'.join(lines + ["}"] + (["return rows"] if luau_type else []) + [""])


def main():
    parser = argparse.ArgumentParser(description="按清单把 configSource 的 Excel / CSV 转成 JSON 或服务器 Luau 配置")
    parser.add_argument("--manifest", default=str(SCRIPT_DIR / "sources.json"),
                        help="清单文件路径(默认 tools/config-puller/sources.json)")
    parser.add_argument("--only", nargs="*", default=None,
                        help="只转指定名字的表(可多个),不填则全部转")
    args = parser.parse_args()

    manifest_path = Path(args.manifest)
    if not manifest_path.exists():
        sys.exit(f"清单文件不存在: {manifest_path}")

    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    source_dir = (PROJECT_ROOT / manifest.get("sourceDir", "configSource")).resolve()
    output_dir = (PROJECT_ROOT / manifest.get("outputDir", "src/shared/config")).resolve()
    output_dir.mkdir(parents=True, exist_ok=True)

    tables = manifest.get("tables", [])
    if args.only:
        wanted = set(args.only)
        tables = [t for t in tables if t["name"] in wanted]
        if not tables:
            sys.exit(f"清单里没有匹配 --only {args.only} 的表")

    ok, failed = 0, 0
    for entry in tables:
        name = entry["name"]
        try:
            records = read_table(entry, source_dir)
            output = build_output(entry, records)
            # outputPath 仅来自项目清单；保底写服务器目录，不进入 shared。
            out_path = (PROJECT_ROOT / entry["outputPath"]).resolve() if entry.get("outputPath") else output_dir / f"{name}.json"
            out_path.resolve().relative_to(PROJECT_ROOT.resolve())
            content = serialize_output(entry, output)
            out_path.parent.mkdir(parents=True, exist_ok=True)
            out_path.write_text(content, encoding="utf-8")
            print(f"[OK] {name}: {len(records)} 条 -> {out_path.relative_to(PROJECT_ROOT)}")
            ok += 1
        except Exception as exc:  # noqa: BLE001 - 单张表失败不影响其它表
            print(f"[FAIL] {name}: {exc}")
            failed += 1

    print(f"\n完成:成功 {ok},失败 {failed}")
    if failed:
        sys.exit(1)


if __name__ == "__main__":
    main()
