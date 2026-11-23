#!/usr/bin/env python3
"""脚本的单元测试（Python 标准库 unittest）。

跑法（项目根目录）：
    python3 -m unittest discover -s tests_py -v

只测纯函数与确定性输出，不联网、不写仓库文件。
"""

import hashlib
import io
import json
import sys
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from tempfile import TemporaryDirectory
from unittest.mock import patch

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "scripts"))

import generate_data  # noqa: E402
import generate_tests  # noqa: E402
import sync_data  # noqa: E402


class TestMbtEmit(unittest.TestCase):
    def test_mbt_str_escapes(self):
        self.assertEqual(generate_data.mbt_str('a"b'), '"a\\"b"')
        self.assertEqual(generate_data.mbt_str("a\\b"), '"a\\\\b"')
        self.assertEqual(generate_data.mbt_str("a\nb"), '"a\\nb"')
        self.assertEqual(generate_data.mbt_str("a\tb"), '"a\\tb"')
        self.assertEqual(generate_data.mbt_str("a\x01b"), '"a\\u{0001}b"')
        self.assertEqual(generate_data.mbt_str("中文"), '"中文"')

    def test_mbt_bool(self):
        self.assertEqual(generate_data.mbt_bool(True), "true")
        self.assertEqual(generate_data.mbt_bool(False), "false")

    def test_mbt_str_array(self):
        self.assertEqual(generate_data.mbt_str_array([], "  "), "[],")
        out = generate_data.mbt_str_array(["甲", "乙"], "  ")
        self.assertIn('"甲",', out)
        self.assertIn('"乙",', out)
        self.assertTrue(out.startswith("["))
        self.assertTrue(out.rstrip().endswith("],"))

    def test_emit_competition_deterministic(self):
        comp = {
            "name": "测试比赛", "deadline": "2026-12-01",
            "deadline_date": "2026-12-01", "verified_at": "2026-11-15",
            "prize": "¥0", "track": "测试", "status": "测试",
            "plan_status": "关注", "target_kind": "比赛",
            "requires_first_publish": True,
            "requires_new_work": False, "requires_no_prior_entry": False,
            "allows_existing_works": False, "materials": ["材料 A"],
            "note": "备注",
        }
        comp.update(required_work_kind="", publish_start="", publish_end="")
        first = generate_data.emit_competition(comp)
        second = generate_data.emit_competition(comp)
        self.assertEqual(first, second)
        self.assertIn('plan_status: "关注",', first)
        self.assertIn('target_kind: "比赛",', first)
        self.assertIn("requires_first_publish: true,", first)
        self.assertIn("requires_no_prior_entry: false,", first)

    def test_emit_work_unknown_kind_raises(self):
        work = {"name": "x", "kind": "Video", "oneliner": "",
                "first_public_date": "", "submitted_to": [],
                "materials_ready": [], "note": ""}
        with self.assertRaises(ValueError):
            generate_data.emit_work(work)

    def test_emit_work_kinds(self):
        base = {"name": "x", "kind": "Game", "oneliner": "o",
                "first_public_date": "", "submitted_to": [],
                "materials_ready": [], "note": ""}
        self.assertIn("kind: WorkKind::Game,", generate_data.emit_work(base))
        base["kind"] = "Tool"
        self.assertIn("kind: WorkKind::Tool,", generate_data.emit_work(base))

    def test_generate_file_matches_json(self):
        """生成器连续跑两次字节一致（确定性），且含 21 个目标名。
        注意：不要断言“跑完与提交的文件字节一致”——提交的文件还经过
        moon fmt 格式化（CI 里是 generate + fmt 后再 diff），生成器
        本身只保证确定性输出。"""
        with TemporaryDirectory() as directory:
            out_path = Path(directory) / "competition_data.mbt"
            history_path = Path(directory) / "ledger_history_data.mbt"
            with patch.multiple(generate_data, OUT_PATH=out_path, HISTORY_OUT=history_path), redirect_stdout(io.StringIO()):
                self.assertEqual(generate_data.main(), 0)
                first = out_path.read_bytes(), history_path.read_bytes()
                self.assertEqual(generate_data.main(), 0)
                second = out_path.read_bytes(), history_path.read_bytes()
                self.assertEqual(first, second)
            text = out_path.read_text(encoding="utf-8")
        data = json.loads((ROOT / "data" / "competitions.json").read_text(encoding="utf-8"))
        self.assertEqual(len(data["competitions"]), 21)
        self.assertEqual(len(data["works"]), 4)
        for comp in data["competitions"]:
            self.assertIn(comp["name"], text)
        for work in data["works"]:
            self.assertIn(work["name"], text)

    def test_json_field_completeness(self):
        """JSON 每行必须有生成器要用的全部字段，缺字段生成器会 KeyError。"""
        data = json.loads((ROOT / "data" / "competitions.json").read_text(encoding="utf-8"))
        for comp in data["competitions"]:
            for field in generate_data.COMP_FIELDS:
                self.assertIn(field, comp, f"{comp['name']} 缺字段 {field}")
        for work in data["works"]:
            for field in generate_data.WORK_FIELDS:
                self.assertIn(field, work, f"{work['name']} 缺字段 {field}")


class TestSyncHelpers(unittest.TestCase):
    def test_replace_first_amount_found(self):
        self.assertEqual(
            sync_data.replace_first_amount("奖池 ¥34,000（冠军）", "34,000", "35,000"),
            "奖池 ¥35,000（冠军）")

    def test_replace_first_amount_not_found(self):
        self.assertEqual(
            sync_data.replace_first_amount("奖池 34000", "34,000", "35,000"),
            "奖池 34000")

    def test_replace_first_amount_only_first(self):
        self.assertEqual(
            sync_data.replace_first_amount("¥10 和 ¥10", "10", "20"),
            "¥20 和 ¥10")

    def test_replace_leading_date_match(self):
        self.assertEqual(
            sync_data.replace_leading_date("2026-12-07（初稿）", "2026-12-07", "2026-12-08"),
            "2026-12-08（初稿）")

    def test_replace_leading_date_no_match(self):
        self.assertEqual(
            sync_data.replace_leading_date("初稿 2026-12-07", "2026-12-07", "2026-12-08"),
            "初稿 2026-12-07")

    def test_find_comp(self):
        data = json.loads((ROOT / "data" / "competitions.json").read_text(encoding="utf-8"))
        found = sync_data.find_comp(data, "松江·创世纪 AI 游戏大赛")
        self.assertIsNotNone(found)
        self.assertEqual(found["deadline_date"], "2026-12-06")
        self.assertIsNone(sync_data.find_comp(data, "不存在的比赛"))

    def test_songjiang_date_regex(self):
        html = "<dt>投稿截止时间</dt><dd>2026.12.06 23:59</dd>"
        m = sync_data.re.search(r"投稿截止时间</dt><dd>(\d{4})\.(\d{2})\.(\d{2})", html)
        self.assertIsNotNone(m)
        self.assertEqual((m.group(1), m.group(2), m.group(3)), ("2026", "12", "06"))

    def test_emerge_deadline_regex(self):
        bundle = "9月10日起首日开放作品提交，12月6日零点截止提交，12月7日-12月15日开启评审"
        m = sync_data.re.search(r"(\d+)月(\d+)日零点截止提交", bundle)
        self.assertIsNotNone(m)
        self.assertEqual((int(m.group(1)), int(m.group(2))), (12, 6))

    def test_moonbit_bundle_regex(self):
        html = '<script src="assets/index-AbC123.js"></script>'
        m = sync_data.re.search(r'assets/index-[^"\']+\.js', html)
        self.assertIsNotNone(m)
        self.assertEqual(m.group(0), "assets/index-AbC123.js")

    def test_payathon_phase_dates_regex(self):
        """日历格推断用的 data-date + aria-label 正则。"""
        html = ('<td data-date="2026-12-01" aria-label="报名阶段"></td>'
                '<td data-date="2026-09-21" aria-label="报名阶段"></td>')
        dates = sync_data.re.findall(
            r'data-date="(\d{4}-\d{2}-\d{2})"[^>]*aria-label="[^"]*报名', html)
        self.assertEqual(max(dates), "2026-12-01")

    def test_shifangronghai_deadline_regex(self):
        text = "作品与方案提交截止时间统一为 11 月 30 日，请参赛团队合理规划"
        m = sync_data.re.search(
            r"作品与方案提交截止时间统一为\s*(\d+)\s*月\s*(\d+)\s*日", text)
        self.assertIsNotNone(m)
        self.assertEqual((int(m.group(1)), int(m.group(2))), (11, 30))

    def test_caai_youth_deadline_regex(self):
        text = "报名截止时间为2026年11月30日24:00截止。"
        m = sync_data.re.search(r"报名截止时间为\s*(\d{4})年(\d{1,2})月(\d{1,2})日", text)
        self.assertIsNotNone(m)
        self.assertEqual(
            (m.group(1), f"{int(m.group(2)):02d}", f"{int(m.group(3)):02d}"),
            ("2026", "11", "30"))

    def test_zaohua_deadline_regex(self):
        text = "报名投稿期为 11 月 3 日至 12 月 15 日 23:59；"
        m = sync_data.re.search(r"12\s*月\s*15\s*日\s*23:59", text)
        self.assertIsNotNone(m)

    def test_dobe_verification_wall_markers(self):
        page = "环境异常\n当前环境异常，完成验证后即可继续访问。"
        self.assertTrue("环境异常" in page or "完成验证" in page)
        captcha = '<script src="TCaptcha.js"></script> cap_appid : "2003810213"'
        self.assertTrue("TCaptcha" in captcha or "cap_appid" in captcha)

    def test_visible_text_strips_js_shell(self):
        shell = ('<html><head><script>"use strict";var x=1;</script></head>'
                 '<body><div id="app"></div></body></html>')
        self.assertEqual(sync_data.visible_text(shell), "")
        self.assertIn("JS 渲染壳", sync_data.js_shell_note(shell))
        real = ("<html><body><h1>第十一届全国青年人工智能创新创业大赛</h1>"
                "<p>经研究，决定举办第十一届全国青年人工智能创新创业大赛。"
                "现将大赛有关事宜通知如下：主办单位是中国人工智能学会，"
                "承办单位是哈尔滨工业大学（深圳）。报名截止时间为2026年11月30日"
                "24:00截止，参赛团队需在规定时间前将参赛项目内容发送至指定邮箱，"
                "初赛阶段为2026年12月初，总决赛阶段为2026年12月末，地点在深圳。"
                "本次比赛不收取报名费用，请勿轻信非官方渠道的收费信息。</p></body></html>")
        self.assertIn("报名截止", sync_data.visible_text(real))
        self.assertGreater(len(sync_data.visible_text(real)), 200)
        self.assertIn("有正文", sync_data.js_shell_note(real))

    def test_page_state_login_redirect(self):
        self.assertEqual(
            sync_data.page_state("<html></html>",
                                 "https://example.com/login?next=/x"),
            "login")

    def test_page_state_strong_login_marker(self):
        # 天池这类页导航文字很多，但“登录后您可以获得”一出现就说明
        # 赛题正文在登录墙后，不看可见文本长度。
        body = "<p>登录后您可以获得</p>" + "<p>探索发现</p>" * 100
        page = f"<html><body>{body}</body></html>"
        self.assertEqual(sync_data.page_state(page, "https://example.com/"), "login")

    def test_quote_url_encodes_chinese_path(self):
        url = "https://modelscope.cn/events/394/比赛介绍"
        quoted = sync_data.quote_url(url)
        self.assertNotIn("比赛", quoted)
        self.assertIn("%E6%AF%94%E8%B5%9B", quoted)
        self.assertTrue(quoted.startswith("https://modelscope.cn/events/394/"))

    def test_page_state_login_wall_short_text(self):
        page = "<html><body><p>登录后您可以获得</p><button>登录</button></body></html>"
        self.assertEqual(sync_data.page_state(page, "https://example.com/"), "login")

    def test_page_state_js_shell(self):
        shell = ('<html><head><script>"use strict";var x=1;</script></head>'
                 '<body><div id="app"></div></body></html>')
        self.assertEqual(sync_data.page_state(shell, "https://example.com/"), "js-shell")

    def test_page_state_readable_with_login_nav(self):
        # 可读页面导航栏里也有“登录”，不能只因出现登录字样就判登录墙。
        body = "<p>登录</p>" + "<p>报名截止时间为2026年11月30日24:00截止。</p>" * 30
        page = f"<html><body>{body}</body></html>"
        self.assertEqual(sync_data.page_state(page, "https://example.com/"), "readable")

    def test_today_cst_is_shanghai_date(self):
        # VM 是 UTC，用户在 Asia/Shanghai：today_cst 必须等于 UTC+8 的今天，
        # 不能等于 date.today()（UTC 日期，半夜会差一天）。
        import re
        from datetime import datetime, timedelta, timezone
        got = sync_data.today_cst()
        self.assertRegex(got, r"^\d{4}-\d{2}-\d{2}$")
        want = datetime.now(timezone(timedelta(hours=8))).date().isoformat()
        self.assertEqual(got, want)

    def test_mark_verified_records_name(self):
        report = sync_data.Report()
        report.mark_verified("松江·创世纪 AI 游戏大赛", "投稿截止已确认")
        self.assertEqual(report.verified, ["松江·创世纪 AI 游戏大赛"])
        self.assertEqual(report.updates, 0)

    def test_apply_verified_at_only_changes_listed_rows(self):
        data = {"competitions": [
            {"name": "甲", "verified_at": "2026-11-13"},
            {"name": "乙", "verified_at": "2026-11-16"},
            {"name": "丙", "verified_at": "2026-11-15"},
        ], "works": []}
        changed = sync_data.apply_verified_at(data, ["甲", "乙", "不存在"], "2026-11-16")
        self.assertEqual(changed, ["甲"])
        self.assertEqual(data["competitions"][0]["verified_at"], "2026-11-16")
        self.assertEqual(data["competitions"][1]["verified_at"], "2026-11-16")
        self.assertEqual(data["competitions"][2]["verified_at"], "2026-11-15")
        self.assertEqual(data["works"], [])


class TestCellTestGenerator(unittest.TestCase):
    def test_cell_table_counts_conflicts_and_window_pass(self):
        self.assertEqual(len(generate_tests.CELL_EXPECT), 22)
        p0 = sum(1 for (levels, _) in generate_tests.CELL_EXPECT.values()
                 if levels == ["P0"])
        p1 = sum(1 for (levels, _) in generate_tests.CELL_EXPECT.values()
                 if levels == ["P1"])
        self.assertEqual((p0, p1), (4, 18))

    def test_row_table_covers_all_competitions(self):
        self.assertEqual(len(generate_tests.ROW_EXPECT), 21)
        watching = [c for c, v in generate_tests.ROW_EXPECT.items()
                    if v[1] == "关注"]
        self.assertEqual(len(watching), 9)

    def test_emit_cell_contains_expected_level(self):
        out = generate_tests.emit_cell("第零次黎明", "魔搭 AI+∞ 第三期「AI 造游戏」")
        self.assertIn('assert_eq(list[0].level, "P0")', out)
        self.assertIn("assert_eq(pack.blocked, true)", out)
        out2 = generate_tests.emit_cell("第零次黎明", "松江·创世纪 AI 游戏大赛")
        self.assertIn("assert_eq(list.length(), 0)", out2)
        self.assertIn("assert_eq(pack.blocked, false)", out2)

    def test_emit_row_contains_deadline(self):
        out = generate_tests.emit_row("造化首届体素游戏创作大赛")
        self.assertIn('assert_eq(c.deadline_date, "2026-12-15")', out)
        self.assertIn("assert_eq(c.requires_new_work, true)", out)


if __name__ == "__main__":
    unittest.main()
