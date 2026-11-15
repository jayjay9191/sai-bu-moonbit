#!/usr/bin/env python3
"""同步比赛数据：联网抓取公开可读的官方页面，核实台账里的字段。

只用 Python 标准库。用法（在项目根目录）：
    python3 scripts/sync_data.py            # 核实并更新 JSON（有变化才写）
    python3 scripts/sync_data.py --dry-run  # 只打印报告，不改任何文件

原则：
- 只抓公开可读、无需登录的页面；登录墙后、JS 渲染后才能看到的
  内容一律不抓、不猜。
- 只更新能从抓到的页面核实的字段；抓不到、页面里没有该字段、
  或提取结果含糊的，一律保留旧值，并在报告里说明。
- 更新分两档：页面上明确标注的数值（绿联“初稿作品提交”对应的
  日期、总奖金池金额，PAYATHON 明确写出的奖金）可以自动更新；
  需要推断的值（PAYATHON 日历格里各阶段的最后一天）只核实、
  不自动写，对不上就报“需人工确认”，绝不靠推断改数据。
- 绝不编造数据。每次运行都打印“改了什么、没核实什么”。
- 更新 JSON 后自动跑 scripts/generate_data.py 重新生成
  competition_data.mbt；生成后请跑 moon fmt && moon test。

当前覆盖的来源（2026-11-15 实测可读）：
- MoonBit 黑客松官网：页面是 JS 渲染，抓 HTML 里的 JS 包再搜文本。
  只报告 11 月轮截止是否公布（台账 12 个比赛里没有 MoonBit 本身，
  所以只报告、不更新 JSON）。
- 绿联黑客松官网：核实初稿截止 2026-12-07 与总奖金池 ¥34,000。
- PAYATHON 官网：核实报名阶段最后一天、作品提交阶段最后一天、
  Vibe Pay 一等奖 ¥30,000（日期是日历格推断，只核实不自动写；
  奖金是明确标注，可自动更新）。
- 松江专题页：核实投稿截止（页面明文“投稿截止时间 2026.12.06 23:59”）。
  只核实、不自动写（2026-11-15 新增）。
- 涌现奖官网：页面是 JS 壳，内容在 async JS 包里（与 MoonBit 检查
  同款做法：HTML 里找包地址再抓包搜文本）。核实提交截止
  （包里明文“12月6日零点截止提交”）。只核实、不自动写
  （2026-11-15 新增）；页面不写年份，按 2026 赛季理解。
未覆盖（页面打不开、登录墙、或日期不在公开页上）：AI PLAY、
BayHack、荣耀、华为、Qoder、魔搭、知乎 S3、Rokid。
"""

import argparse
import json
import re
import subprocess
import sys
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
JSON_PATH = ROOT / "data" / "competitions.json"
GENERATE_SCRIPT = ROOT / "scripts" / "generate_data.py"

UA = {"User-Agent": "Mozilla/5.0 (sai-chang-guan-jia sync check)"}
TIMEOUT = 25


def fetch(url: str) -> str:
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=TIMEOUT) as resp:
        return resp.read().decode("utf-8", "replace")


def find_comp(data: dict, name: str) -> dict | None:
    for c in data["competitions"]:
        if c["name"] == name:
            return c
    return None


def replace_first_amount(text: str, old: str, new: str) -> str:
    """把文本里第一次出现的 ¥<old> 换成 ¥<new>，找不到返回原文本。"""
    return text.replace("¥" + old, "¥" + new, 1)


def replace_leading_date(text: str, old: str, new: str) -> str:
    """deadline 显示串以日期开头时，把开头的旧日期换成新日期。"""
    if text.startswith(old):
        return new + text[len(old):]
    return text


class Report:
    def __init__(self):
        self.lines = []
        self.updates = 0

    def add(self, line: str):
        self.lines.append(line)
        print(line)

    def update(self, line: str):
        self.updates += 1
        self.add("  [已更新] " + line)

    def ok(self, line: str):
        self.add("  [一致] " + line)

    def unknown(self, line: str):
        self.add("  [未核实] " + line)

    def fail(self, line: str):
        self.add("  [抓取失败] " + line)


def check_moonbit(report: Report):
    """MoonBit 官网：11 月轮截止是否公布。只报告，不更新 JSON。"""
    report.add("MoonBit 黑客松官网 https://moonbitlang.github.io/Hackathon2026/")
    try:
        html = fetch("https://moonbitlang.github.io/Hackathon2026/")
    except Exception as e:
        report.fail(f"官网打不开：{type(e).__name__}: {e}")
        return
    m = re.search(r'assets/index-[^"\']+\.js', html)
    if not m:
        report.unknown("官网 HTML 里找不到 JS 包地址，无法读取页面内容")
        return
    try:
        bundle = fetch("https://moonbitlang.github.io/Hackathon2026/" + m.group(0))
    except Exception as e:
        report.fail(f"JS 包抓不到：{type(e).__name__}: {e}")
        return
    if "以官方通知为准" in bundle:
        report.unknown("11 月轮报名/验收截止仍写“以官方通知为准”，未公布具体日期")
    else:
        report.add("  [需人工确认] 官网不再写“以官方通知为准”，11 月轮截止可能已公布，请人工打开官网确认")


def check_ugreen(report: Report, data: dict, dry_run: bool):
    """绿联：核实初稿截止与总奖金池。"""
    report.add("绿联首届黑客松 https://hackathon.ugnas.com/l/htyda3")
    comp = find_comp(data, "绿联首届黑客松")
    if comp is None:
        report.unknown("台账里没有绿联，跳过")
        return
    try:
        page = fetch("https://hackathon.ugnas.com/l/htyda3")
    except Exception as e:
        report.fail(f"页面打不开：{type(e).__name__}: {e}")
        return
    m = re.search(
        r'datetime="(\d{4}-\d{2}-\d{2})"[^>]*>[^<]*</time>\s*</p>\s*<h3>初稿作品提交</h3>',
        page,
    )
    if m:
        page_date = m.group(1)
        if page_date == comp["deadline_date"]:
            report.ok(f"初稿截止 {page_date}，与台账一致")
        else:
            report.update(
                f"初稿截止：台账 {comp['deadline_date']} → 官网 {page_date}"
            )
            if not dry_run:
                comp["deadline"] = replace_leading_date(
                    comp["deadline"], comp["deadline_date"], page_date
                )
                comp["deadline_date"] = page_date
    else:
        report.unknown("页面里找不到“初稿作品提交”对应的截止日期")
    m = re.search(r"总奖金池 ¥([\d,]+)", page)
    if m:
        page_pool = m.group(1)
        old_pool = re.search(r"¥([\d,]+)", comp["prize"])
        if old_pool and old_pool.group(1) == page_pool:
            report.ok(f"总奖金池 ¥{page_pool}，与台账一致")
        elif old_pool:
            report.update(f"总奖金池：台账 ¥{old_pool.group(1)} → 官网 ¥{page_pool}")
            if not dry_run:
                comp["prize"] = replace_first_amount(
                    comp["prize"], old_pool.group(1), page_pool
                )
        else:
            report.unknown("台账奖金串里找不到 ¥ 金额，无法比对")
    else:
        report.unknown("页面里找不到“总奖金池”金额")


def check_payathon(report: Report, data: dict, dry_run: bool):
    """PAYATHON：核实报名截止、作品提交截止、Vibe Pay 一等奖。"""
    report.add("PAYATHON https://aipay.alipay.com/community/events/payathon-2026")
    comp = find_comp(data, "PAYATHON 2026")
    if comp is None:
        report.unknown("台账里没有 PAYATHON，跳过")
        return
    try:
        page = fetch("https://aipay.alipay.com/community/events/payathon-2026")
    except Exception as e:
        report.fail(f"页面打不开：{type(e).__name__}: {e}")
        return
    # 日历格推断：某阶段的截止 = 该阶段日历格里的最后一天。
    # 这是推断不是明文，只核实、不自动写，对不上就报需人工确认。
    def phase_end(keyword: str) -> str | None:
        dates = re.findall(
            r'data-date="(\d{4}-\d{2}-\d{2})"[^>]*aria-label="[^"]*' + keyword,
            page,
        )
        return max(dates) if dates else None

    reg_end = phase_end("报名")
    if reg_end is not None:
        if reg_end == comp["deadline_date"]:
            report.ok(f"报名阶段最后一天 {reg_end}，与台账报名截止一致")
        else:
            report.add(
                f"  [需人工确认] 报名阶段最后一天是 {reg_end}，台账报名截止是 "
                f"{comp['deadline_date']}，不一致，未自动改"
            )
    else:
        report.unknown("页面日历里找不到报名阶段的日期")
    sub_end = phase_end("作品提交")
    if sub_end is not None:
        if sub_end in comp["deadline"]:
            report.ok(f"作品提交阶段最后一天 {sub_end}，与台账一致")
        else:
            report.add(
                f"  [需人工确认] 作品提交阶段最后一天是 {sub_end}，台账写的是 "
                f"{comp['deadline']}，不一致，未自动改"
            )
    else:
        report.unknown("页面日历里找不到作品提交阶段的日期")
    m = re.search(r"Vibe Pay，一等奖，数量 1，税前 ¥([\d,]+)", page)
    if m:
        page_first = m.group(1)
        old = re.search(r"Vibe Pay 一等奖 ¥([\d,]+)", comp["prize"])
        if old and old.group(1) == page_first:
            report.ok(f"Vibe Pay 一等奖 ¥{page_first}，与台账一致")
        elif old:
            report.update(
                f"Vibe Pay 一等奖：台账 ¥{old.group(1)} → 官网 ¥{page_first}"
            )
            if not dry_run:
                comp["prize"] = comp["prize"].replace(
                    "Vibe Pay 一等奖 ¥" + old.group(1),
                    "Vibe Pay 一等奖 ¥" + page_first,
                    1,
                )
        else:
            report.unknown("台账奖金串里找不到 Vibe Pay 一等奖金额，无法比对")
    else:
        report.unknown("页面里找不到 Vibe Pay 一等奖金额")


def check_songjiang(report: Report, data: dict):
    """松江：核实投稿截止。只核实、不自动写。"""
    report.add("松江·创世纪 AI 游戏大赛 https://aiplaylab.cn/topics/songjiang-ai-genesis-2026")
    comp = find_comp(data, "松江·创世纪 AI 游戏大赛")
    if comp is None:
        report.unknown("台账里没有松江，跳过")
        return
    try:
        page = fetch("https://aiplaylab.cn/topics/songjiang-ai-genesis-2026")
    except Exception as e:
        report.fail(f"页面打不开：{type(e).__name__}: {e}")
        return
    m = re.search(r"投稿截止时间</dt><dd>(\d{4})\.(\d{2})\.(\d{2})", page)
    if m:
        page_date = f"{m.group(1)}-{m.group(2)}-{m.group(3)}"
        if page_date == comp["deadline_date"]:
            report.ok(f"投稿截止 {page_date}，与台账一致")
        else:
            report.add(
                f"  [需人工确认] 投稿截止是 {page_date}，台账是 "
                f"{comp['deadline_date']}，不一致，未自动改"
            )
    else:
        report.unknown("页面里找不到“投稿截止时间”对应的日期")


def check_emerge(report: Report, data: dict):
    """涌现奖：核实提交截止。页面是 JS 壳，内容在 async JS 包里
    （与 MoonBit 检查同款做法：HTML 里找包地址再抓包搜文本）。
    只核实、不自动写。页面只写“12月6日零点”，不写年份，
    按 2026 赛季理解，年份取台账的 2026。"""
    report.add("支付宝智能体涌现奖 https://abao.alipay.com/emerge")
    comp = find_comp(data, "支付宝智能体涌现奖")
    if comp is None:
        report.unknown("台账里没有涌现奖，跳过")
        return
    try:
        html = fetch("https://abao.alipay.com/emerge")
    except Exception as e:
        report.fail(f"官网打不开：{type(e).__name__}: {e}")
        return
    m = re.search(
        r'https://gw\.alipayobjects\.com/render/p/yuyan/[^"\']+/async\.[^"\']+\.js',
        html,
    )
    if not m:
        report.unknown("官网 HTML 里找不到 async JS 包地址，无法读取页面内容")
        return
    try:
        bundle = fetch(m.group(0))
    except Exception as e:
        report.fail(f"JS 包抓不到：{type(e).__name__}: {e}")
        return
    m2 = re.search(r"(\d+)月(\d+)日零点截止提交", bundle)
    if m2:
        month, day = int(m2.group(1)), int(m2.group(2))
        want_month, want_day = comp["deadline_date"][5:7], comp["deadline_date"][8:10]
        if f"{month:02d}" == want_month and f"{day:02d}" == want_day:
            report.ok(f"提交截止 {month}月{day}日零点，与台账 {comp['deadline_date']} 一致")
        else:
            report.add(
                f"  [需人工确认] 提交截止是 {month}月{day}日零点，台账是 "
                f"{comp['deadline_date']}，不一致，未自动改"
            )
    else:
        report.unknown("JS 包里找不到“零点截止提交”的日期")


def main() -> int:
    parser = argparse.ArgumentParser(description="同步比赛数据（只更新能核实的字段）")
    parser.add_argument("--dry-run", action="store_true", help="只打印报告，不改文件")
    args = parser.parse_args()

    with open(JSON_PATH, encoding="utf-8") as f:
        data = json.load(f)

    report = Report()
    report.add("== 同步报告 ==")
    check_moonbit(report)
    check_ugreen(report, data, args.dry_run)
    check_payathon(report, data, args.dry_run)
    check_songjiang(report, data)
    check_emerge(report, data)
    report.add("未覆盖：AI PLAY、BayHack、荣耀、华为、Qoder、魔搭、知乎 S3、"
               "Rokid（页面打不开、登录墙、或日期不在公开页上），"
               "均保留旧值。")
    if report.updates > 0 and not args.dry_run:
        with open(JSON_PATH, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, separators=(",", ":"),
                      sort_keys=True)
            f.write("\n")
        report.add(f"已写入 {JSON_PATH}，共 {report.updates} 项更新")
        result = subprocess.run(
            [sys.executable, str(GENERATE_SCRIPT)],
            capture_output=True, text=True,
        )
        print(result.stdout, end="")
        if result.returncode != 0:
            print(result.stderr, end="")
            report.add("生成 competition_data.mbt 失败，请手动跑 "
                       "python3 scripts/generate_data.py")
            return 1
        report.add("已重新生成 competition_data.mbt，请跑 moon fmt && moon test")
    elif report.updates > 0:
        report.add(f"dry-run：共 {report.updates} 项更新未写入")
    else:
        report.add("本次 0 项更新，JSON 未改动")
    return 0


if __name__ == "__main__":
    sys.exit(main())
