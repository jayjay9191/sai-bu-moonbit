"""Replay the second-review CLI and retained certification results."""
from datetime import datetime
from pathlib import Path
import json
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
    for event in events:
        date = re.search(r"^DTSTART;VALUE=DATE:(\d{8})\r$", event, re.M).group(1)
        assert datetime.strptime(date, "%Y%m%d").date() >= datetime(2026, 11, 20).date()
    assert "12:00（报名）/ 18:00（提交）" in unfolded
    later = run("calendar", "2026-12-02").replace("\n ", "")
    assert "SUMMARY:PAYATHON 2026（后续截止）" in later
    assert "DTSTART;VALUE=DATE:20261209" in later
    assert "DTSTART;VALUE=DATE:20261201" not in later
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
    demo = run("order-demo")
    assert "合成案例" in demo and "未投稿 | 材料齐备" in demo
    assert "普通赛 A | 当前可提交 true | 其后剩余可投 1" in demo
    assert "后续阻断 首发赛 C：P0" in demo
    assert "首发赛 C | 当前可提交 true | 其后剩余可投 2" in demo
    assert "推荐顺序：3步；未可安排：0项" in demo
    assert [line.split(" |")[0] for line in demo.splitlines() if re.match(r"[1-3]\. ", line)] == [
        "1. 首发赛 C", "2. 普通赛 B", "3. 普通赛 A"]
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
