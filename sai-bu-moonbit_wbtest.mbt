// Whitebox tests run within the package scope.
// Use them to validate internal helpers or invariants.
// Keep them focused; public behavior belongs in `_test.mbt`.

// 本文件补防御性分支的覆盖（2026-11-16）：
// - digit_value 的非数字分支：公开接口 is_valid_date 已先验过数字，
//   只能白盒直接调内部函数触发。
// - days_from_civil 的负年份分支与 civil_from_days 的负天数分支：
//   有效日期的年份 >= 1、天数 >= -719162，公开接口永不触发；
//   白盒用公元 0 年 / 公元前 1 年的构造输入触发。
//   注意：这两个分支与已走分支共用同一行，行口径的覆盖工具本来
//   就不报它们未覆盖；这里的测试是 pin 住负值换算的正确性。
// - certify_pack 的 "P0 冲突（未知原因）" 分支：白盒也触发不了。
//   pack.blocked 由 generate_pack 对同一份 conflicts 数组算出
//   （has_p0_conflict），blocked 为真当且仅当该比赛的冲突列表里
//   有 P0；certify_pack 随后扫同一份列表，found_p0 必然为真。
//   所以这行是逻辑上不可达的防御代码，不编造测试去“覆盖”它；
//   下面只用一个测试 pin 住这个不变式：被 P0 挡住的包，原因里
//   一定是具名的 P0 冲突，绝不出现“（未知原因）”。

///|
test "digit_value returns -1 for non-digit" {
  assert_eq(digit_value('a'), -1)
  assert_eq(digit_value('-'), -1)
  assert_eq(digit_value(' '), -1)
}

///|
test "digit_value returns digit for 0 and 9" {
  assert_eq(digit_value('0'), 0)
  assert_eq(digit_value('9'), 9)
}

///|
/// 负年份分支：y0 = 0、m <= 2 时 y = -1，走 y - 399。
/// 向量用 Python datetime 对过：0000-01-01 距 1970-01-01 为 -719528 天
///（0001-01-01 是 -719162 天，公元 0 年是闰年，再往前 366 天）。
test "days_from_civil negative year" {
  assert_eq(days_from_civil(0, 1, 1), -719528)
  assert_eq(days_from_civil(-1, 12, 31), -719529)
}

///|
/// 负天数分支：z0 < -719468 时 z < 0，走 z - 146096。
test "civil_from_days negative days" {
  assert_eq(civil_from_days(-719528), (0, 1, 1))
  assert_eq(civil_from_days(-719529), (-1, 12, 31))
}

///|
/// 负年份往返：公元前 5 年到公元 5 年，闰日与年末都走一遍。
test "date round-trip for negative years" {
  for y in -5..<5 {
    assert_eq(civil_from_days(days_from_civil(y, 2, 28)), (y, 2, 28))
    assert_eq(civil_from_days(days_from_civil(y, 12, 31)), (y, 12, 31))
  }
}

///|
/// certify_pack 被 P0 挡住时，原因一定是具名的 P0 冲突，
/// 绝不出现“（未知原因）”——这就是 fallback 分支不可达的原因。
test "certify_pack blocked pack always names the P0 conflict" {
  let work : Work = {
    name: "测试作品",
    kind: Tool,
    oneliner: "测试用作品",
    first_public_date: "2026-11-01",
    submitted_to: ["某比赛"],
    materials_ready: ["材料 A"],
    note: "",
  }
  let comp : Competition = {
    name: "测试比赛",
    deadline: "2026-12-01",
    deadline_date: "2026-12-01",
    verified_at: "2026-11-13",
    prize: "¥0",
    track: "测试",
    status: "测试",
    plan_status: "在途",
    target_kind: "比赛",
    required_work_kind: "",
    publish_start: "",
    publish_end: "",
    requires_first_publish: true,
    requires_new_work: false,
    requires_no_prior_entry: false,
    allows_existing_works: false,
    materials: ["材料 A"],
    note: "",
  }
  let conflicts = detect_conflicts(work, [comp])
  assert_eq(conflicts.length(), 1)
  assert_eq(conflicts[0].level, "P0")
  let row = row_verdict(comp, date_to_days("2026-11-15"))
  assert_true(row.verified)
  let v = certify_pack(work, comp, conflicts, row)
  assert_true(v.blocked)
  assert_eq(v.reasons.length(), 1)
  assert_true(v.reasons[0].contains("P0 冲突："))
  assert_true(!v.reasons[0].contains("未知原因"))
}
