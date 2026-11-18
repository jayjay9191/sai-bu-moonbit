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
- verified_at 自动更新（2026-11-16 接，规则见 README“下一步路线图”
  第三批）：某行检查覆盖的全部字段都被确认，才把该行 verified_at
  更新为运行当天日期；任一字段未核实，该行不动；只报告的检查
  （MoonBit、第二批 8 个）永远不更新 verified_at；dry-run 只报告
  “哪些行会被更新”，不写 JSON。
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
- 第一批（2026-11-16 新增，全部只核实、不自动写）：
  十方融海（第二届 AIGC 促进行动）：协同方十方融海官网新闻页
  明文“作品与方案提交截止时间统一为 11 月 30 日”；
  DoBe：官方入口是微信文章（mp.weixin.qq.com），返回 TCaptcha
  验证码页（HTML 里有 cap_appid / verify.js），需完成验证，
  urllib 抓不到正文，只能报告、无法核实；
  中小企业 AI 应用产品大赛：协会官网首页（www.zxsx.org）找
  “AI 应用产品大赛”与“12月10日”，首页无专区入口时只报告；
  CAAI 青年赛（第十一届全国青年人工智能创新创业大赛）：
  承办方哈工大（深圳）计算机应用研究中心通知页明文
  “报名截止时间为2026年11月30日24:00截止”；
  兴智杯：官网 www.aiinnovation.com.cn 不稳定——https 常直接断开
  连接（此前已确认 ERR_CONNECTION_CLOSED），http 返回 Vue 单页
  应用壳（HTML 里无正文），报名截止不在公开 HTML 里，只能报告；
  11-05 与 11-28 两来源冲突仍未解决，不要以任一版本为准；
  造化：官方活动页 zaohua.qq.com/activity/voxel-jam-2026
  是 JS 渲染壳（HTML 里只有内联脚本，无正文），“12 月 15 日 23:59”
  不在公开 HTML 里，只能报告。
- 第二批（2026-11-16 新增，全部只报告、不写数据）：
  Qoder：天池赛题页需登录后查看（页面显示“登录后您可以获得”），
  赛题正文不在公开 HTML 里；入口 ID 532536 来自 CompeteHub
  赛事页 slug，未在公开内容里得到确认；
  魔搭：赛事页为 JS 渲染，参赛方式与日程在海报图片里，不在页面文本上；
  AI PLAY：无公开报名页面，报名只走小红书群，无 URL 可抓；
  BayHack：官网 bayhack.cn 打不开，报名走公众号「BayHack」；
  荣耀：参赛协议页是公开页，明文写“截止投稿日期为2026 年 11 月
  22 日 23:59”，只报告、不自动写；
  华为：华为云开发者大赛平台页面，需登录报名；
  知乎 S3：赛事挂在魔搭活动列表里，细则登录墙后；
  Rokid：官网链接未找到，无法检查。
- 软件创新大赛（2026-11-18 新增，只核实、不自动写）：大连理工大学
  软件学院参赛通知页引用第二十届规则原文，核实原创条款、报名截止
  2027-01-15 与一等奖 ¥14,000；官网 https://www.swcontest.com.cn/
  在本机抓取时未通（以通知页为准，通知页内明确写出官网地址）。
未覆盖：无（19 个比赛全部有检查覆盖；MoonBit 只报告）。
"""

import argparse
import json
import re
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timedelta, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
JSON_PATH = ROOT / "data" / "competitions.json"
GENERATE_SCRIPT = ROOT / "scripts" / "generate_data.py"

UA = {"User-Agent": "Mozilla/5.0 (sai-chang-guan-jia sync check)"}
TIMEOUT = 25


def visible_text(page: str) -> str:
    """去掉 script/style 标签及所有 HTML 标签后剩下的可见文本。
    用于判断一个页面是不是 JS 渲染壳：壳的可见文本只有几十字。"""
    no_script = re.sub(r"<script[\s\S]*?</script>", "", page, flags=re.I)
    no_style = re.sub(r"<style[\s\S]*?</style>", "", no_script, flags=re.I)
    text = re.sub(r"<[^>]+>", "", no_style)
    return re.sub(r"\s+", " ", text).strip()


def js_shell_note(page: str) -> str:
    """日期没找到时，补一句页面形态的判断（JS 壳 / 有正文但无该字段）。"""
    n = len(visible_text(page))
    if n < 200:
        return f"页面为 JS 渲染壳，HTML 里无正文（可见文本仅 {n} 字）"
    return "页面有正文，但里面找不到该日期"


CST = timezone(timedelta(hours=8))  # 用户在 Asia/Shanghai，无夏令时


def today_cst() -> str:
    """用户所在时区（Asia/Shanghai）的今天，YYYY-MM-DD。
    VM 是 UTC，直接用 date.today() 会差一天
    （UTC 11-15 17:00 = CST 11-16 01:00），verified_at 必须按用户日期写。"""
    return datetime.now(CST).date().isoformat()


def quote_url(url: str) -> str:
    """把 URL 里的非 ASCII 字符百分号编码（魔搭赛事页路径里有中文，
    urllib 直接传会报 UnicodeEncodeError）。safe 保留已有结构字符
    与百分号，不重复编码。"""
    return urllib.parse.quote(url, safe="/:?&=#@%+")


def fetch_with_url(url: str) -> tuple[str, str]:
    """抓页面，返回 (正文, 最终 URL)。
    只报告的检查用：登录墙常表现为重定向到登录页。"""
    req = urllib.request.Request(quote_url(url), headers=UA)
    with urllib.request.urlopen(req, timeout=TIMEOUT) as resp:
        return resp.read().decode("utf-8", "replace"), resp.geturl()


def page_state(page: str, final_url: str) -> str:
    """给只报告的检查用：判断抓到的页面处于哪种状态。
    返回 'login'（登录墙）/ 'js-shell'（JS 渲染壳，无正文）/
    'readable'（有正文可读）。强登录墙标记（“登录后您可以获得”、
    “请先登录”等）一旦出现就判登录墙，不看可见文本长度——天池
    这类页导航文字很多，但赛题正文仍在登录墙后。弱登录字样
    （导航栏里的“登录”）只在可见文本很少时才算登录墙。"""
    if "login" in final_url.lower() or "signin" in final_url.lower():
        return "login"
    low = page.lower()
    if any(m in low for m in ("登录后您可以获得", "请先登录", "请登录后",
                              "需要登录后", "登录后查看")):
        return "login"
    text = visible_text(page)
    if len(text) < 200 and any(
        m in low for m in ("请登录", "登录后", "login", "sign in")
    ):
        return "login"
    if len(text) < 200:
        return "js-shell"
    return "readable"


def fetch(url: str) -> str:
    req = urllib.request.Request(quote_url(url), headers=UA)
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
        self.verified = []

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

    def mark_verified(self, comp_name: str, what: str):
        """该行检查覆盖的字段全部确认，verified_at 可更新为今天。
        只记录，不直接改 JSON（写 JSON 在 main 里统一做，
        dry-run 时只报告不写）。只报告的检查不调这个方法。"""
        self.verified.append(comp_name)
        self.add(f"  [已核实] {comp_name}：{what}")


def apply_verified_at(data: dict, names: list[str], today: str) -> list[str]:
    """把 names 里各行的 verified_at 改成 today，返回实际改了的行。
    只改 verified_at，不碰其他字段、不碰 works 数组。"""
    changed = []
    for name in names:
        comp = find_comp(data, name)
        if comp is not None and comp["verified_at"] != today:
            comp["verified_at"] = today
            changed.append(name)
    return changed


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
    date_ok = False
    if m:
        page_date = m.group(1)
        if page_date == comp["deadline_date"]:
            report.ok(f"初稿截止 {page_date}，与台账一致")
            date_ok = True
        else:
            report.update(
                f"初稿截止：台账 {comp['deadline_date']} → 官网 {page_date}"
            )
            if not dry_run:
                comp["deadline"] = replace_leading_date(
                    comp["deadline"], comp["deadline_date"], page_date
                )
                comp["deadline_date"] = page_date
            date_ok = True  # 明确标注的值被自动更新，也算确认
    else:
        report.unknown("页面里找不到“初稿作品提交”对应的截止日期")
    m = re.search(r"总奖金池 ¥([\d,]+)", page)
    prize_ok = False
    if m:
        page_pool = m.group(1)
        old_pool = re.search(r"¥([\d,]+)", comp["prize"])
        if old_pool and old_pool.group(1) == page_pool:
            report.ok(f"总奖金池 ¥{page_pool}，与台账一致")
            prize_ok = True
        elif old_pool:
            report.update(f"总奖金池：台账 ¥{old_pool.group(1)} → 官网 ¥{page_pool}")
            if not dry_run:
                comp["prize"] = replace_first_amount(
                    comp["prize"], old_pool.group(1), page_pool
                )
            prize_ok = True  # 明确标注的值被自动更新，也算确认
        else:
            report.unknown("台账奖金串里找不到 ¥ 金额，无法比对")
    else:
        report.unknown("页面里找不到“总奖金池”金额")
    if date_ok and prize_ok:
        report.mark_verified(comp["name"], "初稿截止与总奖金池均已确认")


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
    reg_ok = False
    if reg_end is not None:
        if reg_end == comp["deadline_date"]:
            report.ok(f"报名阶段最后一天 {reg_end}，与台账报名截止一致")
            reg_ok = True
        else:
            report.add(
                f"  [需人工确认] 报名阶段最后一天是 {reg_end}，台账报名截止是 "
                f"{comp['deadline_date']}，不一致，未自动改"
            )
    else:
        report.unknown("页面日历里找不到报名阶段的日期")
    sub_end = phase_end("作品提交")
    sub_ok = False
    if sub_end is not None:
        if sub_end in comp["deadline"]:
            report.ok(f"作品提交阶段最后一天 {sub_end}，与台账一致")
            sub_ok = True
        else:
            report.add(
                f"  [需人工确认] 作品提交阶段最后一天是 {sub_end}，台账写的是 "
                f"{comp['deadline']}，不一致，未自动改"
            )
    else:
        report.unknown("页面日历里找不到作品提交阶段的日期")
    m = re.search(r"Vibe Pay，一等奖，数量 1，税前 ¥([\d,]+)", page)
    prize_ok = False
    if m:
        page_first = m.group(1)
        old = re.search(r"Vibe Pay 一等奖 ¥([\d,]+)", comp["prize"])
        if old and old.group(1) == page_first:
            report.ok(f"Vibe Pay 一等奖 ¥{page_first}，与台账一致")
            prize_ok = True
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
            prize_ok = True  # 明确标注的值被自动更新，也算确认
        else:
            report.unknown("台账奖金串里找不到 Vibe Pay 一等奖金额，无法比对")
    else:
        report.unknown("页面里找不到 Vibe Pay 一等奖金额")
    if reg_ok and sub_ok and prize_ok:
        report.mark_verified(comp["name"], "报名/作品提交两阶段与 Vibe Pay 一等奖均已确认")


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
            report.mark_verified(comp["name"], "投稿截止已确认")
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
            report.mark_verified(comp["name"], "提交截止已确认")
        else:
            report.add(
                f"  [需人工确认] 提交截止是 {month}月{day}日零点，台账是 "
                f"{comp['deadline_date']}，不一致，未自动改"
            )
    else:
        report.unknown("JS 包里找不到“零点截止提交”的日期")


def check_shifangronghai(report: Report, data: dict):
    """十方融海（第二届 AIGC 青年大学生就业创业促进行动）：
    协同方十方融海官网新闻页明文。只核实、不自动写。"""
    report.add("十方融海 / 第二届 AIGC 青年大学生就业创业促进行动 "
               "https://www.goweike.cn/new_pages/det_news_1008.html")
    comp = find_comp(data, "第二届 AIGC 青年大学生就业创业促进行动")
    if comp is None:
        report.unknown("台账里没有十方融海，跳过")
        return
    try:
        page = fetch("https://www.goweike.cn/new_pages/det_news_1008.html")
    except Exception as e:
        report.fail(f"页面打不开：{type(e).__name__}: {e}")
        return
    m = re.search(r"作品与方案提交截止时间统一为\s*(\d+)\s*月\s*(\d+)\s*日", page)
    if m:
        month, day = int(m.group(1)), int(m.group(2))
        want_month, want_day = comp["deadline_date"][5:7], comp["deadline_date"][8:10]
        if f"{month:02d}" == want_month and f"{day:02d}" == want_day:
            report.ok(f"作品与方案提交截止 {month}月{day}日，与台账 "
                      f"{comp['deadline_date']} 一致")
            report.mark_verified(comp["name"], "作品与方案提交截止已确认")
        else:
            report.add(
                f"  [需人工确认] 作品与方案提交截止是 {month}月{day}日，台账是 "
                f"{comp['deadline_date']}，不一致，未自动改"
            )
    else:
        report.unknown("页面里找不到“作品与方案提交截止时间统一为”对应的日期")


def check_dobe(report: Report, data: dict):
    """DoBe 全球 AI 创客大赛：官方入口是微信文章，需完成验证。
    urllib 抓到的是验证墙，只能报告、无法核实。只核实、不自动写。"""
    report.add("DoBe 全球 AI 创客大赛 "
               "https://mp.weixin.qq.com/s?__biz=MzcxMDEyMjk4OQ==&mid=2247485348"
               "&idx=1&sn=dd7274e14d2a419debd961d057d3643a")
    comp = find_comp(data, "DoBe 全球 AI 创客大赛")
    if comp is None:
        report.unknown("台账里没有 DoBe，跳过")
        return
    try:
        page = fetch(
            "https://mp.weixin.qq.com/s?__biz=MzcxMDEyMjk4OQ==&mid=2247485348"
            "&idx=1&sn=dd7274e14d2a419debd961d057d3643a"
        )
    except Exception as e:
        report.fail(f"页面打不开：{type(e).__name__}: {e}")
        return
    if "环境异常" in page or "完成验证" in page:
        report.unknown("官方入口（微信文章）需完成验证，urllib 抓到的是验证墙，"
                       "无法核实报名截止")
        return
    if ("TCaptcha" in page or "cap_appid" in page
            or "secitptpage/template/verify.js" in page):
        report.unknown("官方入口（微信文章）返回验证码页（TCaptcha），"
                       "需完成验证后才能读正文，无法核实报名截止")
        return
    m = re.search(r"11\s*月\s*27\s*日", page)
    if m:
        if comp["deadline_date"] == "2026-11-27":
            report.ok("报名截止 11月27日，与台账一致")
            report.mark_verified(comp["name"], "报名截止已确认")
        else:
            report.add(
                f"  [需人工确认] 页面写报名截止 11月27日，台账是 "
                f"{comp['deadline_date']}，不一致，未自动改"
            )
    else:
        report.unknown("微信文章可读，但里面找不到报名截止日期")


def check_sme(report: Report, data: dict):
    """中小企业 AI 应用产品大赛：协会官网首页找大赛与截止日期。
    首页无专区入口时只报告。只核实、不自动写。"""
    report.add("中小企业 AI 应用产品大赛 https://www.zxsx.org/")
    comp = find_comp(data, "中小企业 AI 应用产品大赛")
    if comp is None:
        report.unknown("台账里没有中小企业，跳过")
        return
    try:
        page = fetch("https://www.zxsx.org/")
    except Exception as e:
        report.fail(f"页面打不开：{type(e).__name__}: {e}")
        return
    if "AI 应用产品大赛" not in page and "AI应用产品大赛" not in page:
        report.unknown("协会官网首页无“AI 应用产品大赛”相关内容，"
                       "大赛专区可能在公众号或子页面，日期不在首页上")
        return
    m = re.search(r"12\s*月\s*10\s*日", page)
    if m:
        if comp["deadline_date"] == "2026-12-10":
            report.ok("报名及材料提交截止 12月10日，与台账一致")
            report.mark_verified(comp["name"], "报名及材料提交截止已确认")
        else:
            report.add(
                f"  [需人工确认] 页面写截止 12月10日，台账是 "
                f"{comp['deadline_date']}，不一致，未自动改"
            )
    else:
        report.unknown("首页提到大赛，但里面找不到截止日期")


def check_caai_youth(report: Report, data: dict):
    """CAAI 青年赛（第十一届全国青年人工智能创新创业大赛）：
    承办方哈工大（深圳）通知页明文。只核实、不自动写。"""
    report.add("第十一届全国青年人工智能创新创业大赛 "
               "https://carc.hitsz.edu.cn/info/1033/3934.htm")
    comp = find_comp(data, "第十一届全国青年人工智能创新创业大赛")
    if comp is None:
        report.unknown("台账里没有 CAAI 青年赛，跳过")
        return
    try:
        page = fetch("https://carc.hitsz.edu.cn/info/1033/3934.htm")
    except Exception as e:
        report.fail(f"页面打不开：{type(e).__name__}: {e}")
        return
    m = re.search(r"报名截止时间为\s*(\d{4})年(\d{1,2})月(\d{1,2})日", page)
    if m:
        page_date = f"{m.group(1)}-{int(m.group(2)):02d}-{int(m.group(3)):02d}"
        if page_date == comp["deadline_date"]:
            report.ok(f"报名截止 {page_date}，与台账一致")
            report.mark_verified(comp["name"], "报名截止已确认")
        else:
            report.add(
                f"  [需人工确认] 报名截止是 {page_date}，台账是 "
                f"{comp['deadline_date']}，不一致，未自动改"
            )
    else:
        report.unknown("页面里找不到“报名截止时间”对应的日期")


def check_xingzhi(report: Report, data: dict):
    """兴智杯：官网打不开，只能报告。11-05 与 11-28 两来源冲突
    仍未解决，不要以任一版本为准。只核实、不自动写。"""
    report.add("兴智杯 http://www.aiinnovation.com.cn")
    comp = find_comp(data, "兴智杯")
    if comp is None:
        report.unknown("台账里没有兴智杯，跳过")
        return
    page = None
    last_err = None
    for url in ("https://www.aiinnovation.com.cn", "http://www.aiinnovation.com.cn"):
        try:
            page = fetch(url)
            break
        except Exception as e:
            last_err = e
    if page is None:
        report.fail(f"官网打不开：{type(last_err).__name__}: {last_err}；"
                    "截止仍有 11-05 与 11-28 两来源冲突，未核实")
        return
    m = re.search(r"(\d{4})[-年](\d{1,2})[-月](\d{1,2})日?报名截止", page)
    if m:
        page_date = f"{m.group(1)}-{int(m.group(2)):02d}-{int(m.group(3)):02d}"
        if page_date == comp["deadline_date"]:
            report.ok(f"报名截止 {page_date}，与台账一致")
            report.mark_verified(comp["name"], "报名截止已确认")
        else:
            report.add(
                f"  [需人工确认] 报名截止是 {page_date}，台账是 "
                f"{comp['deadline_date']}，不一致，未自动改"
            )
    else:
        report.unknown("官网能打开，但页面里找不到报名截止日期；"
                       + js_shell_note(page))


def check_zaohua(report: Report, data: dict):
    """造化首届体素游戏创作大赛：官方活动页找报名投稿期截止。
    页面为 JS 渲染时只能报告。只核实、不自动写。"""
    report.add("造化首届体素游戏创作大赛 "
               "https://zaohua.qq.com/activity/voxel-jam-2026")
    comp = find_comp(data, "造化首届体素游戏创作大赛")
    if comp is None:
        report.unknown("台账里没有造化，跳过")
        return
    try:
        page = fetch("https://zaohua.qq.com/activity/voxel-jam-2026")
    except Exception as e:
        report.fail(f"页面打不开：{type(e).__name__}: {e}")
        return
    m = re.search(r"12\s*月\s*15\s*日\s*23:59", page)
    if m:
        if comp["deadline_date"] == "2026-12-15":
            report.ok("报名投稿期截止 12月15日 23:59，与台账一致")
            report.mark_verified(comp["name"], "报名投稿期截止已确认")
        else:
            report.add(
                f"  [需人工确认] 页面写报名投稿期截止 12月15日 23:59，台账是 "
                f"{comp['deadline_date']}，不一致，未自动改"
            )
    else:
        report.unknown("页面里找不到报名投稿期截止日期；" + js_shell_note(page))


def check_qoder(report: Report, data: dict):
    """Qoder：天池赛题页需登录后查看。只报告页面状态，不写数据。
    入口 ID 532536 来自 CompeteHub 赛事页 slug，未在公开内容里
    得到确认（页面标题仅为通用“算法大赛-天池大赛”）。"""
    report.add("Qoder 高校创造力大赛 "
               "https://tianchi.aliyun.com/competition/entrance/532536")
    comp = find_comp(data, "Qoder 高校创造力大赛")
    if comp is None:
        report.unknown("台账里没有 Qoder，跳过")
        return
    try:
        page, final_url = fetch_with_url(
            "https://tianchi.aliyun.com/competition/entrance/532536"
        )
    except Exception as e:
        report.fail(f"页面打不开：{type(e).__name__}: {e}")
        return
    state = page_state(page, final_url)
    if state == "login":
        report.unknown("天池赛题页需登录后查看（页面显示“登录后您可以获得”），"
                       "赛题正文不在公开 HTML 里；截止 2026-11-30 仍靠人工核对")
    elif state == "js-shell":
        report.unknown("天池赛题页为 JS 渲染，HTML 里无赛题正文；"
                       "截止 2026-11-30 仍靠人工核对")
    elif "Qoder" in page and "11 月 30 日" in page:
        report.add("  [仅报告] 页面可读且提到 Qoder 与 11 月 30 日，"
                   "未自动写数据，仍请人工核对")
    else:
        report.unknown("页面可读，但里面找不到 Qoder 赛题的截止日期")


def check_modelscope(report: Report, data: dict):
    """魔搭 AI+∞ 第三期：赛事页为 JS 渲染，参赛方式与日程在海报
    图片里，不在页面文本上。只报告页面状态，不写数据。"""
    report.add("魔搭 AI+∞ 第三期「AI 造游戏」 "
               "https://modelscope.cn/events/394/比赛介绍")
    comp = find_comp(data, "魔搭 AI+∞ 第三期「AI 造游戏」")
    if comp is None:
        report.unknown("台账里没有魔搭，跳过")
        return
    try:
        page, final_url = fetch_with_url(
            "https://modelscope.cn/events/394/比赛介绍"
        )
    except Exception as e:
        report.fail(f"页面打不开：{type(e).__name__}: {e}")
        return
    state = page_state(page, final_url)
    if state == "login":
        report.unknown("魔搭赛事页需登录后查看，赛题正文不在公开 HTML 里；"
                       "截止 2026-12-01 与“首次发布”条款仍靠人工核对")
    elif state == "js-shell":
        report.unknown("魔搭赛事页为 JS 渲染，HTML 里无正文；参赛方式与日程"
                       "在海报图片里，不在页面文本上；截止 2026-12-01 与"
                       "“首次发布”条款仍靠人工核对")
    elif "12月1日" in page or "12 月 1 日" in page:
        report.add("  [仅报告] 页面可读且提到 12月1日，未自动写数据，"
                   "仍请人工核对")
    else:
        report.unknown("页面可读，但里面找不到 12月1日截止日期")


def check_aiplay(report: Report, data: dict):
    """AI PLAY：无公开报名页面，报名只走小红书群。只报告，不写数据。"""
    report.add("AI PLAY 72H 创作黑客松（无公开报名页面）")
    comp = find_comp(data, "AI PLAY 72H 创作黑客松")
    if comp is None:
        report.unknown("台账里没有 AI PLAY，跳过")
        return
    report.unknown("无公开页面可抓：报名只走小红书群（LinkLike 科创社区，"
                   "8609354634）；提案截止 2026-11-17 仍靠人工核对")


def check_bayhack(report: Report, data: dict):
    """BayHack：官网打不开。只报告页面状态，不写数据。"""
    report.add("BayHack 大湾区黑客松 https://bayhack.cn")
    comp = find_comp(data, "BayHack 大湾区黑客松")
    if comp is None:
        report.unknown("台账里没有 BayHack，跳过")
        return
    page = None
    last_err = None
    for url in ("https://bayhack.cn", "http://bayhack.cn"):
        try:
            page = fetch(url)
            break
        except Exception as e:
            last_err = e
    if page is None:
        report.fail(f"官网打不开：{type(last_err).__name__}: {last_err}；"
                    "报名截止 2026-11-18 仍靠人工核对（报名走公众号「BayHack」）")
        return
    if "BayHack" in page or "bayhack" in page.lower():
        report.unknown("官网能打开，但页面里找不到报名截止日期；"
                       + js_shell_note(page))
    else:
        report.unknown("官网能打开，但页面内容与 BayHack 对不上")


def check_honor(report: Report, data: dict):
    """荣耀：参赛协议页是公开页，明文写截止投稿日期。只报告，
    即使页面写明了日期也不自动写数据。"""
    report.add("荣耀·英特尔 AI 智造创新赛 "
               "https://www.honor.com/cn/ai-smart-innovation-challenge/terms/")
    comp = find_comp(data, "荣耀·英特尔 AI 智造创新赛")
    if comp is None:
        report.unknown("台账里没有荣耀，跳过")
        return
    try:
        page, final_url = fetch_with_url(
            "https://www.honor.com/cn/ai-smart-innovation-challenge/terms/"
        )
    except Exception as e:
        report.fail(f"页面打不开：{type(e).__name__}: {e}")
        return
    state = page_state(page, final_url)
    if state in ("login", "js-shell"):
        report.unknown("参赛协议页为登录墙/JS 渲染，HTML 里无正文；"
                       "截止 2026-11-22 仍靠人工核对")
        return
    # 日期被 <span> 隔开（“为<span>2026 年 11 月 22 日 …”），
    # 在可见文本里搜，不在原始 HTML 里搜。
    text = visible_text(page)
    m = re.search(r"截止投稿日期为\s*2026\s*年\s*11\s*月\s*22\s*日\s*23:59", text)
    if m:
        if comp["deadline_date"] == "2026-11-22":
            report.ok("参赛协议页明文：截止投稿 2026-11-22 23:59，"
                      "与台账一致（仅报告，未写数据）")
        else:
            report.add(
                f"  [需人工确认] 参赛协议页写截止投稿 2026-11-22 23:59，"
                f"台账是 {comp['deadline_date']}，不一致，未自动改"
            )
    else:
        report.unknown("参赛协议页可读，但里面找不到截止投稿日期")


def check_huawei(report: Report, data: dict):
    """华为小红书 Skill 创新赛：华为云开发者大赛平台页面，
    需登录报名。只报告页面状态，不写数据。"""
    report.add("华为小红书 Skill 创新赛 "
               "https://developer.huaweicloud.com/competition/information/1300000350/html1")
    comp = find_comp(data, "华为小红书 Skill 创新赛")
    if comp is None:
        report.unknown("台账里没有华为，跳过")
        return
    try:
        page, final_url = fetch_with_url(
            "https://developer.huaweicloud.com/competition/information/1300000350/html1"
        )
    except Exception as e:
        report.fail(f"页面打不开：{type(e).__name__}: {e}")
        return
    state = page_state(page, final_url)
    if state == "login":
        report.unknown("华为云赛题页需登录后查看，赛题正文不在公开 HTML 里；"
                       "截止 2026-11-24 仍靠人工核对")
    elif state == "js-shell":
        report.unknown("华为云赛题页为 JS 渲染，HTML 里无正文；"
                       "截止 2026-11-24 仍靠人工核对")
    elif "小红书" in page and "Skill" in page:
        report.add("  [仅报告] 页面可读且提到小红书 Skill 赛，未自动写数据，"
                   "仍请人工核对")
    else:
        report.unknown("页面可读，但里面找不到小红书 Skill 赛的截止日期")


def check_zhihu(report: Report, data: dict):
    """知乎黑客松 S3：赛事挂在魔搭活动列表里，细则登录墙后。
    只报告页面状态，不写数据。"""
    report.add("知乎黑客松 S3 https://modelscope.cn/events")
    comp = find_comp(data, "知乎黑客松 S3")
    if comp is None:
        report.unknown("台账里没有知乎 S3，跳过")
        return
    try:
        page, final_url = fetch_with_url("https://modelscope.cn/events")
    except Exception as e:
        report.fail(f"页面打不开：{type(e).__name__}: {e}")
        return
    state = page_state(page, final_url)
    if state == "login":
        report.unknown("魔搭活动列表页需登录后查看；报名截止 2026-12-04 "
                       "仍靠人工核对")
    elif state == "js-shell":
        report.unknown("魔搭活动列表页为 JS 渲染，HTML 里无赛事列表；"
                       "报名截止 2026-12-04 仍靠人工核对")
    elif "知乎黑客松" in page and "2026-12-04" in page:
        report.add("  [仅报告] 活动列表页可读且列出知乎黑客松 S3、"
                   "报名截止 2026-12-04，未自动写数据，仍请人工核对")
    else:
        report.unknown("活动列表页可读，但里面找不到知乎黑客松 S3 的截止日期")


def check_rokid(report: Report, data: dict):
    """Rokid：官网链接未找到，无法检查。只报告，不写数据。"""
    report.add("Rokid Spatial Joy 2026（官网链接未找到）")
    comp = find_comp(data, "Rokid Spatial Joy 2026")
    if comp is None:
        report.unknown("台账里没有 Rokid，跳过")
        return
    report.unknown("官网链接未找到，无法检查；截止 2027-01-28 与奖金分项"
                   "多处数字冲突，核对前不要以任一版本为准")


def check_swcontest(report: Report, data: dict):
    """第二十届全国大学生软件创新大赛：大连理工大学软件学院参赛通知
    引用第二十届规则原文。核实原创条款、报名截止与一等奖；只核实、
    不自动写数据（来源链接与 verified_at 由人工在 JSON 里补）。
    官网 https://www.swcontest.com.cn/ 在本机抓取时未通，以通知页
    为准（通知页内明确写出官网地址）。"""
    report.add("第二十届全国大学生软件创新大赛 "
               "https://ss.dlut.edu.cn/info/1371/35562.htm")
    comp = find_comp(data, "第二十届全国大学生软件创新大赛")
    if comp is None:
        report.unknown("台账里没有软件创新大赛，跳过")
        return
    try:
        page = fetch("https://ss.dlut.edu.cn/info/1371/35562.htm")
    except Exception as e:
        report.fail(f"页面打不开：{type(e).__name__}: {e}")
        return
    text = re.sub(r"\s+", "", visible_text(page))
    ok_rule = "参赛作品必须是原创且未参加过其他国家级公开比赛的作品" in text
    ok_deadline = re.search(r"2027年01月15日18:00", text) is not None
    ok_prize = re.search(r"一等奖：?20项，颁发证书，奖金为RMB14000元/项", text) is not None
    if ok_rule:
        report.ok("原创条款原文与台账一致")
    else:
        report.unknown("通知页里找不到原创条款原文")
    if ok_deadline:
        report.ok("报名截止 2027-01-15 18:00，与台账一致")
    else:
        report.unknown("通知页里找不到报名截止 2027-01-15")
    if ok_prize:
        report.ok("一等奖 ¥14,000×20，与台账一致")
    else:
        report.unknown("通知页里找不到一等奖 ¥14,000")
    if ok_rule and ok_deadline and ok_prize:
        report.mark_verified(comp["name"], "原创条款/报名截止/奖金已确认")


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
    check_shifangronghai(report, data)
    check_dobe(report, data)
    check_sme(report, data)
    check_caai_youth(report, data)
    check_xingzhi(report, data)
    check_zaohua(report, data)
    check_qoder(report, data)
    check_modelscope(report, data)
    check_aiplay(report, data)
    check_bayhack(report, data)
    check_honor(report, data)
    check_huawei(report, data)
    check_zhihu(report, data)
    check_rokid(report, data)
    check_swcontest(report, data)
    report.add("未覆盖：无——19 个比赛全部有检查覆盖。")
    today = today_cst()
    if args.dry_run:
        # dry-run 只算“哪些行会被更新”，不改内存里的数据。
        verified_changed = [
            n for n in report.verified
            if (c := find_comp(data, n)) is not None
            and c["verified_at"] != today
        ]
    else:
        verified_changed = apply_verified_at(data, report.verified, today)
    if report.verified:
        report.add(f"核实通过 {len(report.verified)} 行："
                   + "、".join(report.verified))
    if (report.updates > 0 or verified_changed) and not args.dry_run:
        with open(JSON_PATH, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, separators=(",", ":"),
                      sort_keys=True)
            f.write("\n")
        report.add(f"已写入 {JSON_PATH}，共 {report.updates} 项更新、"
                   f"verified_at 更新 {len(verified_changed)} 行"
                   + (f"（{ '、'.join(verified_changed)}）" if verified_changed else ""))
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
    elif report.updates > 0 or verified_changed:
        report.add(f"dry-run：共 {report.updates} 项更新、verified_at 更新 "
                   f"{len(verified_changed)} 行未写入")
    else:
        report.add("本次 0 项更新，JSON 未改动")
    return 0


if __name__ == "__main__":
    sys.exit(main())
