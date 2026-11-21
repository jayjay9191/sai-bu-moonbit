"""Replay the second-review CLI and retained certification results."""
from datetime import datetime
from pathlib import Path
import json
from itertools import permutations
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def run(*args, success=True):
    result = subprocess.run(["moon", "run", "cmd/main", "--", *args], cwd=ROOT,
                            capture_output=True, text=True, encoding="utf-8", timeout=90)
    assert result.returncode == (0 if success else 2), result.stdout + result.stderr
    return result.stdout


def verify_calendar():
    args = ["moon", "run", "cmd/main", "--", "calendar", "2026-11-20"]
    result = subprocess.run(args, cwd=ROOT, capture_output=True, timeout=90, check=True)
    raw = result.stdout
    assert b"\r\r\n" not in raw and raw.endswith(b"END:VCALENDAR\r\n")
    assert all(len(line) <= 75 for line in raw.split(b"\r\n"))
    unfolded = raw.decode("utf-8").replace("\r\n ", "")
    events = re.findall(r"BEGIN:VEVENT\r\n(.*?)END:VEVENT\r\n", unfolded, re.S)
    assert len(events) == 12
    assert len({re.search(r"^UID:(.+)\r$", item, re.M).group(1) for item in events}) == 12
    assert "SUMMARY:itch.io 游戏上架" not in unfolded and "SUMMARY:兴智杯" not in unfolded
    assert "SUMMARY:AI PLAY" not in unfolded
    dates = [re.search(r"^DTSTART;VALUE=DATE:(\d{8})\r$", event, re.M).group(1) for event in events]
    assert dates == sorted(dates)
    assert all(datetime.strptime(date, "%Y%m%d").date() >= datetime(2026, 11, 20).date()
               for date in dates)
    assert "12:00（报名）/ 18:00（提交）" in unfolded
    later = run("calendar", "2026-12-02").replace("\n ", "")
    assert "SUMMARY:PAYATHON 2026（后续截止）" in later
    assert "DTSTART;VALUE=DATE:20261209" in later
    assert "DTSTART;VALUE=DATE:20261201" not in later
    bounded = run("calendar", "2026-11-20", "--days", "14")
    assert bounded.count("BEGIN:VEVENT") == 4
    assert "DTSTART;VALUE=DATE:20261201" in bounded and "DTSTART;VALUE=DATE:20261204" not in bounded
    assert run("calendar", "2026-11-20", "--days", "15").count("BEGIN:VEVENT") == 5
    for args in (("--days",), ("--days", "0"), ("--days", "1.5"), ("--days", "2147483648")):
        assert run("calendar", "2026-11-20", *args, success=False) == ""
    print("PASS calendar: 12 verified date reminders, later stage retained, unique UIDs and UTF-8 folding")


def main():
    assert "用法" in run("help")
    verify_calendar()
    audit = run("audit-evidence", "2026-11-20")
    assert "规则证据：6条；结论：84项；完整性问题：8项" in audit
    items = [line for line in audit.splitlines() if "| 用户本人 |" in line]
    assert len(items) == 4
    assert "已过时" in items[0] and "2026-11-16" in items[0]
    assert "待确认" in items[1] and "待确认" in items[2]
    assert "Qoder 高校创造力大赛" in items[3] and "已确认" in items[3]
    assert "2026-11-18" in items[3]
    expired = run("audit-evidence", "2026-12-20")
    assert "P0（证据待复核）" in expired and "| 过期 |" in expired
    order = run("order", "第零次黎明", "2026-11-20")
    assert "推荐顺序：0步；未可安排：21项" in order
    for name in ("Qoder 高校创造力大赛", "AI PLAY 72H 创作黑客松", "魔搭 AI+∞ 第三期「AI 造游戏」"):
        assert f"{name} | 当前可提交 false" in order
    assert "首次发布冲突" in order and "台账已登记投稿，不重复规划" in order
    names = ("Qoder 高校创造力大赛", "AI PLAY 72H 创作黑客松", "魔搭 AI+∞ 第三期「AI 造游戏」")
    exact = json.loads(run("order-exact", "第零次黎明", "2026-11-20", *names))
    assert exact["steps"] == [] and {row["name"] for row in exact["remaining"]} == set(names)
    assert exact["optimal_order_count"] == 1
    assert exact["required_targets"] == exact["possible_targets"] == []
    first_choices = {row["name"]: row for row in exact["first_choices"]}
    assert set(first_choices) == set(names)
    assert all(row["completed"] == 0 and row.get("lost_steps") is None and row["blockers"]
               for row in first_choices.values())
    assert any("首次发布冲突" in reason for row in exact["remaining"] for reason in row["reasons"])
    assert run("order-exact", "第零次黎明", "2026-11-20", names[0], names[0], success=False) == ""
    print("PASS exact shortlist preserves the three recorded blockers for Dawn")
    demo = run("order-demo")
    assert "合成案例" in demo and "未投稿 | 材料齐备" in demo
    assert "普通赛 A | 当前可提交 true | 其后剩余可投 1" in demo
    assert "后续阻断 首发赛 C：P0" in demo
    assert "首发赛 C | 当前可提交 true | 其后剩余可投 2" in demo
    assert "推荐顺序：3步；未可安排：0项" in demo
    assert [line.split(" |")[0] for line in demo.splitlines() if re.match(r"[1-3]\. ", line)] == [
        "1. 首发赛 C", "2. 普通赛 B", "3. 普通赛 A"]
    # Independent fixed-rule oracle: any prefix containing C must start with C.
    names = ("普通赛 A", "普通赛 B", "首发赛 C")
    legal = [order for n in range(1, 4) for order in permutations(names, n)
             if names[2] not in order or order[0] == names[2]]
    exact_demo = json.loads(run("order-demo", "--exact"))
    longest = max(map(len, legal))
    expected = {name: max(len(order) for order in legal if order[0] == name)
                for name in names}
    assert {row["name"]: row["completed"] for row in exact_demo["first_choices"]} == expected
    assert all(row["lost_steps"] == longest - expected[row["name"]]
               and row["blockers"] == [] for row in exact_demo["first_choices"])
    assert exact_demo["optimal_order_count"] == sum(len(order) == longest for order in legal)
    without = {name: max(len(order) for order in legal if name not in order) for name in names}
    assert {row["name"]: row["completed"] for row in exact_demo["drop_impacts"]} == without
    assert all(row["lost_steps"] == longest - without[row["name"]] for row in exact_demo["drop_impacts"])
    print("PASS first-choice and drop-one consequences match exhaustive fixed-rule replay")
    materials = run("materials-plan", "小店日结", "2026-11-20", "3")
    assert "已具备条件：1；补齐后新增：2" in materials
    assert [line for line in materials.splitlines() if line.startswith("待补材料")] == [
        "待补材料 | 作品策划案", "待补材料 | PPT（发邮箱）", "待补材料 | AIUI 智能体（Rokid AIUI Studio）"]
    assert "满足台账认证 | Rokid Spatial Joy 2026" in materials
    assert "满足台账认证 | 第十一届全国青年人工智能创新创业大赛" in materials
    assert "已具备条件：1；补齐后新增：0" in run("materials-plan", "小店日结", "2026-11-20", "0")
    frontier = run("materials-plan", "小店日结", "2026-11-20", "frontier")
    headers = [line for line in frontier.splitlines() if line.startswith("预算 ")]
    assert len(headers) == 4
    for i, header in enumerate(headers):
        fixed = run("materials-plan", "小店日结", "2026-11-20", str(i))
        expected = re.search(r"已具备条件：(\d+)；补齐后新增：(\d+)", fixed).groups()
        assert header == f"预算 {i} | 已具备 {expected[0]} | 补齐后新增 {expected[1]}"
    machine = json.loads(run("materials-plan", "小店日结", "2026-11-20", "frontier-json"))
    assert (machine["work"], machine["as_of"]) == ("小店日结", "2026-11-20")
    assert [entry["budget"] for entry in machine["plans"]] == [0, 1, 2, 3]
    evidence = json.loads(run("materials-plan", "小店日结", "2026-11-20", "explain-json"))
    by_target = {row["name"]: row for row in evidence}
    assert machine["plans"][3]["optimal_count"] == 1
    assert "知乎黑客松 S3" not in machine["plans"][3]["plan"]["unlocked"]
    assert any("其他投稿" in reason for reason in by_target["知乎黑客松 S3"]["blockers"])
    zhihu = run("trace", "小店日结", "知乎黑客松 S3")
    assert "已有其他投稿记录" in zhihu and "认证结论：不可提交" in zhihu
    for entry, expected_count in zip(machine["plans"], (0, 1, 1, 2)):
        assert len(entry["plan"]["unlocked"]) == expected_count
        assert len(entry["plan"]["ready"]) == 1
        assert len(entry["plan"]["materials"]) <= entry["budget"]
        assert entry["optimal_count"] >= 1
        assert set(entry["required_materials"]) <= set(entry["plan"]["materials"]) <= set(entry["possible_materials"])
        if entry["optimal_count"] == 1:
            assert entry["required_materials"] == entry["possible_materials"] == entry["plan"]["materials"]
        for target in entry["plan"]["unlocked"]:
            row = by_target[target]
            assert not row["blockers"] and set(row["missing"]) <= set(entry["plan"]["materials"])
    print("PASS materials frontier: " + " / ".join(headers))
    explanations = run("materials-plan", "第零次黎明", "2026-11-20", "explain").splitlines()
    starts = [i for i, line in enumerate(explanations) if not line.startswith(" ")]
    assert len(starts) == 21
    rows = {explanations[a].split(" | ")[0]: explanations[a:b]
            for a, b in zip(starts, starts[1:] + [len(explanations)])}
    qoder = rows["Qoder 高校创造力大赛"]
    assert any("待补材料" in line for line in qoder[1:])
    assert any("剩余阻断" in line and "已登记投稿" in line for line in qoder[1:])
    model = next(lines for title, lines in rows.items() if title.startswith("魔搭 AI+∞"))
    assert any("剩余阻断" in line and "首次发布" in line for line in model[1:])
    encoded = json.loads(run("materials-plan", "第零次黎明", "2026-11-20", "explain-json"))
    assert len(encoded) == 21
    qoder_json = next(row for row in encoded if row["name"] == "Qoder 高校创造力大赛")
    assert qoder_json["missing"] and any("已登记投稿" in reason for reason in qoder_json["blockers"])
    assert sum(len(row["missing"]) for row in encoded) == sum(line.startswith("  待补材料") for line in explanations)
    print("PASS material explanations keep missing documents separate from rules and prior-submission blockers")
    assert run("materials-plan", "小店日结", "2026-11-20", "4", success=False) == ""
    trace = run("trace", "第零次黎明", "魔搭 AI+∞ 第三期「AI 造游戏」")
    assert "最短阻断链：首次发布 → 不可提交（P0）" in trace
    assert "认证结论：不可提交" in trace
    preflight = run("preflight", "2026-11-20")
    assert "投稿包认证：84 个，可提交 2 个，P0 挡住 3 个" in preflight
    digest = re.search(r"清单 SHA-256：([0-9a-f]{64})", preflight).group(1)
    historical = run("preflight", "2026-11-15")
    assert "今天：2026-11-15" in historical
    assert "可提交 0 个" in historical and "核验日期晚于审计日" in historical
    assert "12-01 提交前务必" not in run()
    for args in (("unknown-review-command",), ("order",), ("order-demo", "extra"), ("order", "missing"), ("order", "第零次黎明", "2026-02-30"),
                 ("audit-evidence", "2026-02-30"), ("audit-evidence", "2026-11-20", "extra"),
                 ("preflight", "2026-02-30"), ("preflight", "2026-11-20", "extra"),
                 ("calendar", "2026-02-30"), ("calendar", "2026-11-20", "extra")):
        run(*args, success=False)
    data = json.loads((ROOT / "data/competitions.json").read_text(encoding="utf-8"))
    assert len(data["competitions"]) == 21 and len(data["works"]) == 4
    assert len(data["followups"]) == 4
    print("PASS six citations, 84 decisions, eight missing proofs, four follow-ups, expired evidence and CLI input checks")
    print("PASS original 84 packs / 2 certifiable / 3 P0; real Dawn has no eligible route")
    print("Manifest SHA-256:", digest)


if __name__ == "__main__":
    main()
