#!/usr/bin/env python3
"""生成逐格回归测试 sai-bu-moonbit_generated_test.mbt。

期望值全部手写在这里（CELL_TABLE / ROW_TABLE / WORK_TABLE），
来源是 docs/manual-baseline-2026-11-15.md（2026-11-15 人工手核底稿），
不是工具的输出。改期望先改底稿，再跑：
    python3 scripts/generate_tests.py
然后跑 moon fmt && moon test。

防呆：生成前只用 data/competitions.json 校验“比赛名/作品名存在”，
不从 JSON 读任何期望值——期望与数据不一致时测试会失败，
那时先人工核对是期望错了还是数据错了，不要直接改期望去迎合工具。
"""

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
JSON_PATH = ROOT / "data" / "competitions.json"
OUT_PATH = ROOT / "sai-bu-moonbit_generated_test.mbt"

HEADER = """///|
/// 由 scripts/generate_tests.py 生成，不要手改。
/// 期望值来自 docs/manual-baseline-2026-11-15.md（人工手核底稿），
/// 84 格逐格断言：每格的冲突等级 + 投稿包 blocked 状态；
/// 另有 21 行逐行断言（目标类型/截止/计划状态/核验日期/标志位）
/// 与 4 件作品断言（首次公开/已投比赛）。
/// 改期望先改底稿，再跑：python3 scripts/generate_tests.py
"""

WORKS = ["第零次黎明", "小店日结", "诉求整理台", "验价尺"]

COMPS = [
    "AI PLAY 72H 创作黑客松",
    "BayHack 大湾区黑客松",
    "荣耀·英特尔 AI 智造创新赛",
    "华为小红书 Skill 创新赛",
    "DoBe 全球 AI 创客大赛",
    "兴智杯",
    "Qoder 高校创造力大赛",
    "第二届 AIGC 青年大学生就业创业促进行动",
    "第十一届全国青年人工智能创新创业大赛",
    "魔搭 AI+∞ 第三期「AI 造游戏」",
    "PAYATHON 2026",
    "知乎黑客松 S3",
    "松江·创世纪 AI 游戏大赛",
    "支付宝智能体涌现奖",
    "绿联首届黑客松",
    "中小企业 AI 应用产品大赛",
    "造化首届体素游戏创作大赛",
    "第二十届全国大学生软件创新大赛",
    "Rokid Spatial Joy 2026",
    "TapTap 游戏上架",
    "itch.io 游戏上架",
]

# (作品, 比赛) -> (冲突等级列表, 投稿包是否 blocked)
# 未列出的格子期望：无冲突、不 blocked。
CELL_EXPECT = {
    ("第零次黎明", "魔搭 AI+∞ 第三期「AI 造游戏」"): (["P0"], True),
    ("第零次黎明", "知乎黑客松 S3"): (["P1"], False),
    ("第零次黎明", "造化首届体素游戏创作大赛"): (["P1"], False),
    ("第零次黎明", "第二十届全国大学生软件创新大赛"): (["P0"], True),
    ("小店日结", "魔搭 AI+∞ 第三期「AI 造游戏」"): (["P0"], True),
    ("小店日结", "第二十届全国大学生软件创新大赛"): (["P0"], True),
    ("诉求整理台", "魔搭 AI+∞ 第三期「AI 造游戏」"): (["P0"], True),
    ("诉求整理台", "第二十届全国大学生软件创新大赛"): (["P0"], True),
    ("验价尺", "魔搭 AI+∞ 第三期「AI 造游戏」"): (["P0"], True),
    ("验价尺", "知乎黑客松 S3"): (["P1"], False),
    ("验价尺", "造化首届体素游戏创作大赛"): (["P1"], False),
    # 平台上架目标（规则 4：上架资质缺口 P1，不阻断投稿包）：
    # 4 件作品的材料清单里都没有两平台的资质项，各报 1 个 P1。
    ("第零次黎明", "TapTap 游戏上架"): (["P1"], False),
    ("第零次黎明", "itch.io 游戏上架"): (["P1"], False),
    ("小店日结", "TapTap 游戏上架"): (["P1"], False),
    ("小店日结", "itch.io 游戏上架"): (["P1"], False),
    ("诉求整理台", "TapTap 游戏上架"): (["P1"], False),
    ("诉求整理台", "itch.io 游戏上架"): (["P1"], False),
    ("验价尺", "TapTap 游戏上架"): (["P1"], False),
    ("验价尺", "itch.io 游戏上架"): (["P1"], False),
}

# 目标名 -> (deadline_date, plan_status, verified_at,
#            requires_first_publish, requires_new_work,
#            requires_no_prior_entry, allows_existing_works, target_kind)
# 注意：verified_at 一列是数据镜像——同步脚本核实通过即更新 JSON
# 里的值，这里跟随改日期（只改日期值，不改其他期望）；冲突等级与
# 标志位期望仍以人工底稿为准，改它们先改底稿。
# 平台上架目标无截止，deadline_date 为 ""（不参与撞期检测）。
ROW_EXPECT = {
    "AI PLAY 72H 创作黑客松": ("2026-11-17", "在途", "2026-11-13", False, False, False, True, "比赛"),
    "BayHack 大湾区黑客松": ("2026-11-18", "在途", "2026-11-13", False, False, False, False, "比赛"),
    "荣耀·英特尔 AI 智造创新赛": ("2026-11-22", "在途", "2026-11-13", False, False, False, True, "比赛"),
    "华为小红书 Skill 创新赛": ("2026-11-24", "在途", "2026-11-13", False, False, False, True, "比赛"),
    "DoBe 全球 AI 创客大赛": ("2026-11-27", "关注", "2026-11-15", False, False, False, False, "比赛"),
    "兴智杯": ("2026-11-28", "关注", "2026-11-15", False, False, False, False, "比赛"),
    "Qoder 高校创造力大赛": ("2026-11-30", "在途", "2026-11-13", False, False, False, True, "比赛"),
    "第二届 AIGC 青年大学生就业创业促进行动": ("2026-11-30", "关注", "2026-11-15", False, False, False, False, "比赛"),
    "第十一届全国青年人工智能创新创业大赛": ("2026-11-30", "关注", "2026-11-18", False, False, False, False, "比赛"),
    "魔搭 AI+∞ 第三期「AI 造游戏」": ("2026-12-01", "在途", "2026-11-13", True, False, False, False, "比赛"),
    "PAYATHON 2026": ("2026-12-01", "在途", "2026-11-18", False, False, False, False, "比赛"),
    "知乎黑客松 S3": ("2026-12-04", "在途", "2026-11-13", False, True, False, False, "比赛"),
    "松江·创世纪 AI 游戏大赛": ("2026-12-06", "在途", "2026-11-18", False, False, False, True, "比赛"),
    "支付宝智能体涌现奖": ("2026-12-06", "在途", "2026-11-18", False, False, False, True, "比赛"),
    "绿联首届黑客松": ("2026-12-07", "在途", "2026-11-18", False, False, False, False, "比赛"),
    "中小企业 AI 应用产品大赛": ("2026-12-10", "关注", "2026-11-15", False, False, False, False, "比赛"),
    "造化首届体素游戏创作大赛": ("2026-12-15", "关注", "2026-11-15", False, True, False, False, "比赛"),
    "第二十届全国大学生软件创新大赛": ("2027-01-15", "关注", "2026-11-18", False, False, True, False, "比赛"),
    "Rokid Spatial Joy 2026": ("2027-01-28", "在途", "2026-11-18", False, False, False, False, "比赛"),
    "TapTap 游戏上架": ("", "关注", "2026-11-16", False, False, False, True, "平台上架"),
    "itch.io 游戏上架": ("", "关注", "2026-11-18", False, False, False, True, "平台上架"),
}

# 作品名 -> (首次公开时间, 已投比赛)
WORK_EXPECT = {
    "第零次黎明": ("2026-11-02 之前", ["Qoder", "AI PLAY"]),
    "小店日结": ("", ["涌现奖"]),
    "诉求整理台": ("", ["涌现奖"]),
    "验价尺": ("2026-11-16", []),
}


def mbt_str(s: str) -> str:
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def mbt_bool(b: bool) -> str:
    return "true" if b else "false"


def emit_cell(work: str, comp: str) -> str:
    levels, blocked = CELL_EXPECT.get((work, comp), ([], False))
    lines = [
        "///|",
        f'test "cell: {work} × {comp}" {{',
        f'  match @sai-bu-moonbit.work_by_name({mbt_str(work)}) {{',
        "    Some(w) =>",
        f'      match @sai-bu-moonbit.competition_by_name({mbt_str(comp)}) {{',
        "        Some(c) => {",
        "          let conflicts = @sai-bu-moonbit.detect_conflicts(",
        "            w,",
        "            @sai-bu-moonbit.all_competitions(),",
        "          )",
        "          let list = @sai-bu-moonbit.conflicts_for_competition(",
        f"            conflicts, {mbt_str(comp)},",
        "          )",
        f"          assert_eq(list.length(), {len(levels)})",
    ]
    for i, level in enumerate(levels):
        lines.append(f'          assert_eq(list[{i}].level, "{level}")')
    lines += [
        "          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)",
        f"          assert_eq(pack.blocked, {mbt_bool(blocked)})",
        "        }",
        "        None => assert_true(false)",
        "      }",
        "    None => assert_true(false)",
        "  }",
        "}",
        "",
    ]
    return "\n".join(lines)


def emit_row(comp: str) -> str:
    date, plan, verified, rfp, rnw, rnpe, aew, kind = ROW_EXPECT[comp]
    return "\n".join([
        "///|",
        f'test "row: {comp}" {{',
        f'  match @sai-bu-moonbit.competition_by_name({mbt_str(comp)}) {{',
        "    Some(c) => {",
        f'      assert_eq(c.deadline_date, "{date}")',
        f'      assert_eq(c.plan_status, "{plan}")',
        f'      assert_eq(c.verified_at, "{verified}")',
        f"      assert_eq(c.requires_first_publish, {mbt_bool(rfp)})",
        f"      assert_eq(c.requires_new_work, {mbt_bool(rnw)})",
        f"      assert_eq(c.requires_no_prior_entry, {mbt_bool(rnpe)})",
        f"      assert_eq(c.allows_existing_works, {mbt_bool(aew)})",
        f'      assert_eq(c.target_kind, "{kind}")',
        "      assert_true(c.name != \"\")",
        "      assert_true(c.deadline != \"\")",
        "      assert_true(c.prize != \"\")",
        "      assert_true(c.materials.length() > 0)",
        "    }",
        "    None => assert_true(false)",
        "  }",
        "}",
        "",
    ])


def emit_work(work: str) -> str:
    first_public, submitted = WORK_EXPECT[work]
    lines = [
        "///|",
        f'test "work: {work}" {{',
        f'  match @sai-bu-moonbit.work_by_name({mbt_str(work)}) {{',
        "    Some(w) => {",
        f'      assert_eq(w.first_public_date, "{first_public}")',
        f"      assert_eq(w.submitted_to.length(), {len(submitted)})",
    ]
    for name in submitted:
        lines.append(
            "      assert_true(@sai-bu-moonbit.contains_string("
            f"w.submitted_to, {mbt_str(name)}))"
        )
    lines += [
        "      assert_true(w.oneliner != \"\")",
        "      assert_true(w.materials_ready.length() > 0)",
        "    }",
        "    None => assert_true(false)",
        "  }",
        "}",
        "",
    ]
    return "\n".join(lines)


def main() -> int:
    with open(JSON_PATH, encoding="utf-8") as f:
        data = json.load(f)
    comp_names = {c["name"] for c in data["competitions"]}
    work_names = {w["name"] for w in data["works"]}
    assert set(COMPS) == comp_names, "比赛名与 JSON 对不上"
    assert set(WORKS) == work_names, "作品名与 JSON 对不上"
    assert set(ROW_EXPECT) == comp_names, "行期望表缺比赛"
    assert set(WORK_EXPECT) == work_names, "作品期望表缺作品"
    for (w, c) in CELL_EXPECT:
        assert w in work_names and c in comp_names, (w, c)
    assert len(COMPS) == 21 and len(WORKS) == 4
    assert len(CELL_EXPECT) == 19, "冲突格应为 19 个（P0 7 + P1 12）"

    parts = [HEADER.rstrip("\n"), ""]
    for work in WORKS:
        for comp in COMPS:
            parts.append(emit_cell(work, comp))
    for comp in COMPS:
        parts.append(emit_row(comp))
    for work in WORKS:
        parts.append(emit_work(work))
    OUT_PATH.write_text("\n".join(parts), encoding="utf-8")
    print(f"已生成 {OUT_PATH}：{len(WORKS) * len(COMPS)} 格 + "
          f"{len(COMPS)} 行 + {len(WORKS)} 作品 = "
          f"{len(WORKS) * len(COMPS) + len(COMPS) + len(WORKS)} 个测试")
    return 0


if __name__ == "__main__":
    sys.exit(main())
