#!/usr/bin/env python3
"""从 data/competitions.json 生成 competition_data.mbt。

JSON 是唯一数据源：改数据只改 data/competitions.json，改完跑：
    python3 scripts/generate_data.py
然后跑 moon fmt && moon test。

只用 Python 标准库。生成内容是确定性的：同一份 JSON 每次生成
字节一致（字段按固定顺序输出）。
"""

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
JSON_PATH = ROOT / "data" / "competitions.json"
OUT_PATH = ROOT / "competition_data.mbt"

HEADER = """///|
/// 由 scripts/generate_data.py 从 data/competitions.json 生成，不要手改。
/// 改数据只改 JSON，改完跑：python3 scripts/generate_data.py
/// 数据来源：《最近要参加的比赛汇总》（2026-11-13 晚四路核实后的状态）。
/// 注意：Rokid 截止（01-28 vs 01-22）、魔搭“首次发布”条款（AIBetas 转述，
/// 官网原文未直接读到）等未核实项都在 note 里标明了，不编数据。
"""

COMP_FIELDS = [
    "name",
    "target_kind",  # "比赛" 或 "平台上架"：台账不只管比赛，也管作品投稿目标
    "deadline",
    "deadline_date",
    "required_work_kind",
    "publish_start",
    "publish_end",
    "verified_at",
    "prize",
    "track",
    "status",
    "plan_status",
    "requires_first_publish",
    "requires_new_work",
    "requires_no_prior_entry",
    "allows_existing_works",
    "materials",
    "note",
]

WORK_FIELDS = [
    "name",
    "kind",
    "oneliner",
    "first_public_date",
    "submitted_to",
    "materials_ready",
    "note",
]


def mbt_str(s: str) -> str:
    """转义成 MoonBit 字符串字面量。"""
    out = []
    for ch in s:
        if ch == "\\":
            out.append("\\\\")
        elif ch == '"':
            out.append('\\"')
        elif ch == "\n":
            out.append("\\n")
        elif ch == "\t":
            out.append("\\t")
        elif ord(ch) < 0x20:
            out.append("\\u{%04x}" % ord(ch))
        else:
            out.append(ch)
    return '"' + "".join(out) + '"'


def mbt_bool(b: bool) -> str:
    return "true" if b else "false"


def mbt_str_array(items, indent: str) -> str:
    """字符串数组：每项一行，moon fmt 保持原样。
    调用处均为结构体字段，因此收尾带上字段后的逗号。"""
    if not items:
        return "[],"
    lines = ["["]
    for item in items:
        lines.append(indent + "  " + mbt_str(item) + ",")
    lines.append(indent + "],")
    return "\n".join(lines)


def emit_competition(c: dict) -> str:
    lines = ["    {"]
    for field in COMP_FIELDS:
        value = c[field]
        if isinstance(value, bool):
            lines.append(f"      {field}: {mbt_bool(value)},")
        elif isinstance(value, list):
            lines.append(f"      {field}: {mbt_str_array(value, '      ')}")
        else:
            lines.append(f"      {field}: {mbt_str(value)},")
    lines.append("    },")
    return "\n".join(lines)


def emit_work(w: dict) -> str:
    kind = w["kind"]
    if kind not in ("Game", "Tool"):
        raise ValueError(f"未知的作品类型：{kind!r}")
    lines = ["    {"]
    for field in WORK_FIELDS:
        value = w[field]
        if field == "kind":
            lines.append(f"      kind: WorkKind::{kind},")
        elif isinstance(value, list):
            lines.append(f"      {field}: {mbt_str_array(value, '      ')}")
        else:
            lines.append(f"      {field}: {mbt_str(value)},")
    lines.append("    },")
    return "\n".join(lines)


def main() -> int:
    with open(JSON_PATH, encoding="utf-8") as f:
        data = json.load(f)
    comps = data["competitions"]
    works = data["works"]
    parts = [HEADER.rstrip("\n"), ""]
    parts.append("///|")
    parts.append("pub fn all_competitions() -> Array[Competition] {")
    parts.append("  [")
    parts.extend(emit_competition(c) for c in comps)
    parts.append("  ]")
    parts.append("}")
    parts.append("")
    parts.append("///|")
    parts.append("pub fn all_works() -> Array[Work] {")
    parts.append("  [")
    parts.extend(emit_work(w) for w in works)
    parts.append("  ]")
    parts.append("}")
    parts.append("")
    parts.extend(["///|", "pub fn all_pending_items() -> Array[PendingItem] {", "  ["])
    for item in data.get("followups", []):
        parts.append("    {")
        for field in ("id", "competition", "issue", "owner", "noted_at", "status", "resolved_at"):
            parts.append(f"      {field}: {mbt_str(item[field])},")
        parts.append("    },")
    parts.extend(["  ]", "}", ""])
    OUT_PATH.write_text("\n".join(parts), encoding="utf-8")
    print(f"已生成 {OUT_PATH}：{len(comps)} 个比赛，{len(works)} 件作品")
    return 0


if __name__ == "__main__":
    sys.exit(main())
