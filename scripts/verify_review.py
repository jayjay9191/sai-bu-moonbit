"""Replay the second-review CLI and retained certification results."""
import argparse
from datetime import date, datetime
import hashlib
from pathlib import Path
import json
from itertools import combinations, permutations
import re
import subprocess

from generate_data import COMP_FIELDS, WORK_FIELDS

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


def verify_real_material_choices():
    ledger = json.loads((ROOT / "data/competitions.json").read_text(encoding="utf-8"))
    work = next(row for row in ledger["works"] if row["name"] == "小店日结")
    rokid = "Rokid Spatial Joy 2026"
    youth = "第十一届全国青年人工智能创新创业大赛"
    zhihu = "知乎黑客松 S3"
    names = (rokid, youth, zhihu)
    selected = {row["name"]: row for row in ledger["competitions"] if row["name"] in names}
    assert work["submitted_to"] and selected[zhihu]["requires_new_work"]
    assert all(not selected[n]["requires_first_publish"] for n in names)
    missing = {name: set(row["materials"]) - set(work["materials_ready"]) for name, row in selected.items()}
    days = ("2026-11-30", "2026-12-01", "2026-12-18", "2026-12-19")
    for day in days:
        when = date.fromisoformat(day)
        eligible = [name for name, row in selected.items()
                    if when <= date.fromisoformat(row["deadline_date"])
                    and 0 <= (when - date.fromisoformat(row["verified_at"])).days <= 30
                    and not (work["submitted_to"] and row["requires_new_work"])]
        for prefix in ((), (rokid,), (zhihu,)):
            flags = ("--prefix", *prefix) if prefix else ()
            actual = json.loads(run("order-material-options", work["name"], day, "3", *names, *flags))
            assert len(actual) == 4
            for budget, row in enumerate(actual):
                possible = []
                for length in range(len(eligible) + 1):
                    for order in permutations(eligible, length):
                        bundle = set().union(*(missing[name] for name in order))
                        if len(bundle) <= budget and order[:len(prefix)] == prefix:
                            possible.append((order, bundle))
                if not possible:
                    assert row is None
                    continue
                score = max((len(order), -len(bundle)) for order, bundle in possible)
                best = [(order, bundle) for order, bundle in possible
                        if (len(order), -len(bundle)) == score]
                assert row["plan"]["budget"] == budget
                assert (tuple(row["plan"]["steps"]), set(row["plan"]["materials"])) in best
                assert row["optimal_order_count"] == len(best)
                for label, sets in (("materials", [bundle for _, bundle in best]),
                                    ("targets", [set(order) for order, _ in best])):
                    assert set(row["required_" + label]) == set.intersection(*sets)
                    assert set(row["possible_" + label]) == set.union(*sets)
    print("PASS 48 actual ledger date/prefix/budget combinations recomputed from raw JSON")


def verify_historical_planning():
    work = "验价尺"
    target = "魔搭 AI+∞ 第三期「AI 造游戏」"
    for day in ("2026-11-20", "2026-11-23"):
        archive = json.loads((ROOT / "data" / "history" / f"{day}.json").read_bytes())
        row = next(row for row in archive["works"] if row["name"] == work)
        festival = next(row for row in archive["competitions"] if row["name"] == target)
        assert festival["requires_first_publish"]
        prior_entry_blocks_first_release = any("MoonBit" in name for name in row["submitted_to"])

        exact = json.loads(run("order-exact", work, day, target))
        replay = json.loads(run("order-replay", work, day, target, "--prefix", target))
        explanation = json.loads(run("materials-plan", work, day, "explain-json"))
        material_blockers = next(row["blockers"] for row in explanation if row["name"] == target)
        plan_text = run("order", work, day)
        for reasons in (exact["first_choices"][0]["blockers"], replay["blocked"]["reasons"],
                        material_blockers, plan_text.splitlines()):
            assert any("已投 MoonBit" in reason for reason in reasons) == prior_entry_blocks_first_release, day

    for args in (("order", work, "2026-11-14"),
                 ("order-exact", work, "2026-11-14", target),
                 ("materials-plan", work, "2026-11-14", "explain-json")):
        assert "steps" not in run(*args, success=False)

    early_archive = json.loads((ROOT / "data/history/2026-11-15.json").read_bytes())
    assert work not in {row["name"] for row in early_archive["works"]}
    platform = "itch.io 游戏上架"
    assert platform not in {row["name"] for row in early_archive["competitions"]}
    assert run("order-exact", work, "2026-11-15", target, success=False) == ""
    for command in ("order-materials", "order-material-options"):
        assert run(command, "第零次黎明", "2026-11-15", "3", platform, success=False) == ""
        assert len(json.loads(run(command, "第零次黎明", "2026-11-20", "3", platform))) == 4

    print("PASS six dated planners use recorded work, target and submission evidence")


def verify_archived_manifests(reports):
    for day, report in reports.items():
        path = ROOT / "data" / "history" / f"{day}.json"
        archive = json.loads(path.read_bytes())
        defaults = dict(target_kind="比赛", required_work_kind="", publish_start="", publish_end="")
        comps = [{field: (defaults | row)[field] for field in COMP_FIELDS}
                 for row in archive["competitions"]]
        works = [{field: row[field] for field in WORK_FIELDS} for row in archive["works"]]
        payload = json.dumps(["sai-bu-ledger-v2", comps, works], ensure_ascii=False,
                             separators=(",", ":")).encode("utf-8")
        assert f"清单 SHA-256：{hashlib.sha256(payload).hexdigest()}" in report, day


def verify_preflight_diff(prior, current):
    def dated_pairs(day):
        data = json.loads((ROOT / "data" / "history" / f"{day}.json").read_bytes())
        return {(work["name"], comp["name"]) for work in data["works"] for comp in data["competitions"]}

    def p0_pairs(report):
        blocked_section = report.split("P0 挡住：\n", 1)[1].split("其余 ", 1)[0]
        return {tuple(line.split("：", 1)[0].strip()[2:].split(" → ", 1))
                for line in blocked_section.splitlines() if line.startswith("  - ")}

    result = json.loads(run("preflight-diff", "2026-11-20", "2026-11-23"))
    assert (result["before_date"], result["after_date"]) == ("2026-11-20", "2026-11-23")
    assert result["before_manifest"] in prior and result["after_manifest"] in current
    keys, p0_before, p0_after = set(), set(), set()
    for row in result["changes"]:
        key = row["work"], row["competition"]
        assert key not in keys
        keys.add(key)
        old, new = row.get("before") or {}, row.get("after") or {}
        if old.get("blocked") and not new.get("blocked"):
            p0_before.add(key)
        if new.get("blocked") and not old.get("blocked"):
            p0_after.add(key)
        assert old != new
    assert p0_before == p0_pairs(prior) - p0_pairs(current)
    assert p0_after == p0_pairs(current) - p0_pairs(prior) == {
        ("验价尺", "魔搭 AI+∞ 第三期「AI 造游戏」")}
    growth = json.loads(run("preflight-diff", "2026-11-15", "2026-11-20"))
    added = {(row["work"], row["competition"]) for row in growth["changes"]
             if row.get("before") is None}
    removed = {(row["work"], row["competition"]) for row in growth["changes"]
               if row.get("after") is None}
    assert added == dated_pairs("2026-11-20") - dated_pairs("2026-11-15")
    assert removed == dated_pairs("2026-11-15") - dated_pairs("2026-11-20")
    assert json.loads(run("preflight-diff", "2026-11-20", "2026-11-20"))["changes"] == []
    fixed = json.loads(run("preflight-diff", "2026-11-20", "2026-11-23",
                           "--audit-on", "2026-11-20"))
    assert fixed["before_date"] == fixed["after_date"] == "2026-11-20"
    assert (fixed["before_known_on"], fixed["after_known_on"]) == ("2026-11-20", "2026-11-23")
    assert fixed["before_manifest"] == fixed["after_manifest"] and fixed["changes"] == []
    elapsed = json.loads(run("preflight-diff", "2026-11-23", "2026-11-30"))
    assert elapsed["before_manifest"] == elapsed["after_manifest"] == result["after_manifest"]
    # Independently find expired targets in that unchanged archived dataset.
    archive = json.loads((ROOT / "data/history/2026-11-23.json").read_bytes())
    deadlines = {comp["name"]: comp["deadline_date"] for comp in archive["competitions"]
                 if "2026-11-23" <= comp["deadline_date"] < "2026-11-30"}
    expected = {(work["name"], comp) for work in archive["works"] for comp in deadlines}
    assert {(row["work"], row["competition"]) for row in elapsed["changes"]} == expected
    assert all(any(f"已过截止：{deadlines[row['competition']]}" in reason
                   for reason in row["after"]["reasons"]) for row in elapsed["changes"])
    print(f"PASS unchanged manifest still reports {len(expected)} date-driven reason changes")


    def endpoints(diff):
        return {(row["work"], row["competition"]): (row.get("before"), row.get("after"))
                for row in diff["changes"]}

    dates = ("2026-11-15", "2026-11-20", "2026-11-23", "2026-11-30")
    edges = {(dates[0], dates[1]): growth, (dates[1], dates[2]): result, (dates[2], dates[3]): elapsed}
    for a, b in combinations(dates, 2):
        if (a, b) not in edges:
            edges[a, b] = json.loads(run("preflight-diff", a, b))
    for a, b, c in combinations(dates, 3):
        ab, bc, ac = (edges[edge] for edge in ((a, b), (b, c), (a, c)))
        assert ab["after_manifest"] == bc["before_manifest"]
        assert (ab["before_manifest"], bc["after_manifest"]) == (ac["before_manifest"], ac["after_manifest"])
        first, second = endpoints(ab), endpoints(bc)
        composed = {}
        for key in first.keys() | second.keys():
            if key in first and key in second:
                start, middle = first[key]
                assert middle == second[key][0], (a, b, c, key)
                end = second[key][1]
            else:
                start, end = first[key] if key in first else second[key]
            if start != end:
                composed[key] = (start, end)
        assert composed == endpoints(ac), (a, b, c)
    print("PASS four archived date triples: composed changes equal direct comparisons")

    assert run("preflight-diff", "2026-11-20", "2026-11-23", "--audit-on", "2026-11-21",
               success=False) == ""

    for dates in (("2026-11-23", "2026-11-20"), ("2026-02-30", "2026-11-20"),
                  ("2026-11-14", "2026-11-20")):
        assert run("preflight-diff", *dates, success=False) == ""
    print(f"PASS preflight diff: {len(added)} additions, {len(removed)} removals, "
          f"{len(result['changes'])} changed pairs in the latest comparison, one new P0")


def verify_historical_preflight():
    preflight = run("preflight", "2026-11-23")
    assert "投稿包认证：84 个，可提交 2 个，P0 挡住 4 个" in preflight
    prior = run("preflight", "2026-11-20")
    assert "投稿包认证：84 个，可提交 2 个，P0 挡住 3 个" in prior
    assert "验价尺 → 魔搭" not in prior and "验价尺 → 魔搭" in preflight
    trial = run("pack", "小店日结", "支付宝智能体涌现奖")
    assert "缺口（0 项）" in trial
    assert re.search(r"可提交：\n(?:  - .*\n)*  - 小店日结 → 支付宝智能体涌现奖", preflight), preflight
    digest = re.search(r"清单 SHA-256：([0-9a-f]{64})", preflight).group(1)
    historical = run("preflight", "2026-11-15")
    assert "今天：2026-11-15" in historical
    assert "台账快照：2026-11-15 · Git 6d20bc3" in historical
    assert "投稿包认证：57 个，可提交 2 个，P0 挡住 3 个" in historical
    assert "证据收录：2026-11-23 · 发生日：未知" in preflight
    verify_archived_manifests({"2026-11-15": historical, "2026-11-20": prior, "2026-11-23": preflight})
    retrospective = run("preflight", "2026-11-20", "--known-on", "2026-11-23")
    assert "证据截止：2026-11-23" in retrospective
    assert "验价尺 → 魔搭" not in retrospective and "证据收录：2026-11-23" not in retrospective
    same_day = run("preflight", "2026-11-23", "--known-on", "2026-11-23")
    assert "验价尺 → 魔搭" in same_day and "发生日：未知" in same_day
    verify_archived_manifests({"2026-11-20": retrospective, "2026-11-23": same_day})
    for args in (("2026-11-20", "--known-on", "2026-11-19"),
                 ("2026-11-20", "--known-on", "2026-02-30"),
                 ("2026-11-20", "--known-on")):
        assert "日期必须有效" in run("preflight", *args, success=False)
    print("PASS archived ledger digests and two-date replay without backdating unknown events")
    verify_preflight_diff(prior, preflight)
    return digest


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--quick", action="store_true", help="verify archived preflights, their differences and explicit-date planning")
    args = parser.parse_args()
    if not __debug__:
        parser.error("enable Python assertions (remove -O or PYTHONOPTIMIZE)")
    verify_historical_planning()
    if args.quick:
        print("Manifest SHA-256:", verify_historical_preflight())
        return
    verify_real_material_choices()
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
    constrained = json.loads(run("order-exact", "第零次黎明", "2026-11-20", *names, "--must", names[0]))
    assert constrained["with_required"] == dict(requested=[names[0]], steps=[], optimal_order_count=0,
                                                conflict_cores=[[names[0]]], minimal_waivers=[[names[0]]],
                                                waiver_routes=[dict(waived=[names[0]], steps=[])])
    for required in ((), ("未知目标",), (names[0], names[0])):
        assert run("order-exact", "第零次黎明", "2026-11-20", *names, "--must", *required, success=False) == ""
    replay = json.loads(run("order-replay", "第零次黎明", "2026-11-20", *names, "--prefix", names[0], names[1]))
    assert replay["applied"] == [] and replay.get("continuation") is None
    assert replay["blocked"] == next(row for row in exact["remaining"] if row["name"] == names[0])
    assert run("order-replay", "第零次黎明", "2026-11-20", *names, "--prefix", success=False) == ""
    print("PASS exact shortlist and prefix replay preserve recorded blockers")
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
    for count in range(1, 4):
        for prefix in permutations(names, count):
            result = json.loads(run("order-demo", "--prefix", *prefix))
            if prefix in legal:
                assert [step["name"] for step in result["applied"]] == list(prefix)
                assert all(step["records_entry"] for step in result["applied"])
                assert result.get("blocked") is None
                possible = [order[count:] for order in legal if order[:count] == prefix]
                best = max(map(len, possible))
                continuation = result["continuation"]
                assert tuple(continuation["steps"]) in possible and len(continuation["steps"]) == best
                assert continuation["optimal_order_count"] == sum(len(route) == best for route in possible)
            else:
                blocked_at = prefix.index(names[2])
                assert [step["name"] for step in result["applied"]] == list(prefix[:blocked_at])
                assert result["blocked"]["name"] == names[2] and result["blocked"]["reasons"]
                assert result.get("continuation") is None
    print("PASS exact continuations and first blockers match all 15 fixed-rule prefixes")
    resources = ("海报", "视频")
    material_for = dict(zip(names, ("海报", "视频", "视频")))
    candidates = []
    for count in range(len(resources) + 1):
        for bundle in combinations(resources, count):
            for order in [(), *legal]:
                if all(material_for[name] in bundle for name in order):
                    candidates.append((-len(order), count, order, bundle))
    front = json.loads(run("order-demo", "--materials"))
    for budget, actual in enumerate(front):
        _, _, steps, bundle = min(row for row in candidates if row[1] <= budget)
        assert actual == dict(budget=budget, materials=sorted(bundle), steps=list(steps))
    assert len(front) == 4 and len(front[1]["steps"]) == 2 and len(front[2]["steps"]) == 3
    for count in range(1, 4):
        for prefix in permutations(names, count):
            actual = json.loads(run("order-demo", "--materials", *prefix))
            expected = []
            for budget in range(4):
                pick = min((row for row in candidates
                            if row[1] <= budget and row[2][:count] == prefix), default=None)
                expected.append(None if pick is None else
                                dict(budget=budget, materials=sorted(pick[3]), steps=list(pick[2])))
            assert actual == expected, (prefix, actual, expected)
    for invalid in (("不存在",), (names[0], names[0])):
        assert "InvalidSequence" in run("order-demo", "--materials", *invalid, success=False)
    print("PASS 60 prefix-budget decisions match independent material subsets and permutations")
    real = json.loads(run("order-materials", "第零次黎明", "2026-11-20", "3",
                          "Qoder 高校创造力大赛", "AI PLAY 72H 创作黑客松"))
    assert all(row["steps"] == [] and row["materials"] == [] for row in real)
    blocked = json.loads(run("order-materials", "第零次黎明", "2026-11-20", "3",
                             "Qoder 高校创造力大赛", "--prefix", "Qoder 高校创造力大赛"))
    assert blocked == [None] * 4
    assert run("order-materials", "第零次黎明", "2026-11-20", "4", "Qoder 高校创造力大赛", success=False) == ""
    print("PASS joint budgets against independent material subsets and legal permutations")
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
    digest = verify_historical_preflight()
    assert "12-01 提交前务必" not in run()
    for args in (("unknown-review-command",), ("order",), ("order-demo", "extra"), ("order", "missing"), ("order", "第零次黎明", "2026-02-30"),
                 ("audit-evidence", "2026-02-30"), ("audit-evidence", "2026-11-20", "extra"),
                 ("preflight", "2026-02-30"), ("preflight", "2026-11-20", "extra"), ("preflight", "2026-11-14"),
                 ("calendar", "2026-02-30"), ("calendar", "2026-11-20", "extra")):
        run(*args, success=False)
    data = json.loads((ROOT / "data/competitions.json").read_text(encoding="utf-8"))
    assert len(data["competitions"]) == 21 and len(data["works"]) == 4
    assert len(data["followups"]) == 4
    print("PASS six citations, 84 decisions, eight missing proofs, four follow-ups, expired evidence and CLI input checks")
    print("PASS 84 packs / 2 certifiable / 4 P0; real Dawn has no eligible route")
    print("Manifest SHA-256:", digest)


if __name__ == "__main__":
    main()
