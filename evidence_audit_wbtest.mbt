///|
fn audit_citation() -> RuleCitation {
  {
    rule: "首次发布",
    rule_text: "fixture rule",
    source: "fixture source",
    source_note: "synthetic test",
    verified_at: "2026-11-20",
  }
}

///|
test "shared preflight refuses future verification before certifying any route" {
  let today = date_to_days("2026-11-20")
  let comp = { ..order_fixture("future"), verified_at: "2026-11-21", }
  let row = row_verdict(comp, today)
  assert_false(row.verified)
  assert_true(row.reason.contains("核验日期晚于"))
  assert_false(certify_pack(order_work(), comp, [], row).certifiable)
}

///|
test "citation freshness has non-overlapping 20 21 30 31 day boundaries" {
  let citation = audit_citation()
  let today = date_to_days(citation.verified_at)
  for
    (age, grade) in [
      (0, "新鲜"),
      (20, "新鲜"),
      (21, "将过期"),
      (30, "将过期"),
      (31, "过期"),
    ] {
    let result = audit_rule(citation, today + age)
    assert_eq(result.grade, grade)
    assert_eq(result.age, Some(age))
  }
}

///|
test "future or invalid evidence dates require verification" {
  let citation = audit_citation()
  for value in ["", "2026-02-30", "2026-11-21"] {
    let result = audit_rule(
      { ..citation, verified_at: value, },
      date_to_days("2026-11-20"),
    )
    assert_eq(result.grade, "待核对")
    assert_true(result.age is None)
  }
}

///|
test "citation completeness distinguishes missing text source and verification date" {
  let citation = audit_citation()
  for
    (bad, kind) in [
      ({ ..citation, rule_text: "", }, "缺原文"),
      ({ ..citation, source: "", }, "缺来源"),
      ({ ..citation, source: "未收录", }, "缺来源"),
      ({ ..citation, verified_at: "", }, "缺核实日期"),
    ] {
    assert_true(
      audit_rule(bad, date_to_days("2026-11-20")).issues.any(issue => {
        issue.kind == kind
      }),
    )
  }
}

///|
test "expired evidence qualifies P0 without erasing the original blocking result" {
  guard work_by_name("第零次黎明") is Some(work) else {
    abort("missing work")
  }
  guard competition_by_name("魔搭 AI+∞ 第三期「AI 造游戏」")
    is Some(comp) else {
    abort("missing competition")
  }
  let trace = trace_first_publish(work, comp)
  let result = audit_decision(trace, work, date_to_days("2026-12-20"))
  assert_eq(result.level, "P0（证据待复核）")
  assert_eq(trace.level, "P0")
  assert_false(result.evidence_current)
}

///|
test "fresh evidence retains a rule verdict and expiring evidence warns" {
  guard work_by_name("第零次黎明") is Some(work) else {
    abort("missing work")
  }
  guard competition_by_name("魔搭 AI+∞ 第三期「AI 造游戏」")
    is Some(comp) else {
    abort("missing competition")
  }
  let trace = { ..trace_first_publish(work, comp), rule: audit_citation(), }
  assert_eq(audit_decision(trace, work, date_to_days("2026-11-20")).level, "P0")
  assert_eq(
    audit_decision(trace, work, date_to_days("2026-12-12")).grade,
    "将过期",
  )
}

///|
test "missing first-public or submitted facts downgrade dependent verdicts" {
  guard work_by_name("第零次黎明") is Some(work) else {
    abort("missing work")
  }
  guard competition_by_name("魔搭 AI+∞ 第三期「AI 造游戏」")
    is Some(comp) else {
    abort("missing competition")
  }
  let unsupported = { ..work, name: "unrecorded synthetic work", }
  let result = audit_decision(
    trace_first_publish(unsupported, comp),
    unsupported,
    date_to_days("2026-11-20"),
  )
  assert_eq(result.grade, "待核对")
  assert_true(
    fact_evidence_issues(unsupported).any(issue => {
      issue.kind == "缺事实证据"
    }),
  )
}

///|
test "non-applicable rules have no citation dependency" {
  guard work_by_name("第零次黎明") is Some(work) else {
    abort("missing work")
  }
  guard competition_by_name("Qoder 高校创造力大赛") is Some(comp) else {
    abort("missing competition")
  }
  let trace = trace_all_rules(work, comp)[0]
  assert_eq(
    audit_decision(trace, work, date_to_days("2026-11-20")).level,
    "通过",
  )
}

///|
test "pending item aging freezes on resolution and invalid start dates stay unknown" {
  let item : PendingItem = {
    id: "fixture",
    competition: "fixture",
    issue: "fixture",
    owner: "用户本人",
    noted_at: "2026-11-13",
    status: "待确认",
    resolved_at: "",
  }
  assert_eq(pending_age(item, date_to_days("2026-11-20")), Some(7))
  assert_eq(
    pending_age(
      { ..item, status: "已确认", resolved_at: "2026-11-18", },
      date_to_days("2026-11-20"),
    ),
    Some(5),
  )
  assert_true(
    pending_age({ ..item, noted_at: "", }, date_to_days("2026-11-20")) is None,
  )
  assert_true(
    pending_age({ ..item, status: "unknown", }, date_to_days("2026-11-20"))
    is None,
  )
}

///|
test "structured follow-ups retain four cases and explicit unresolved ownership" {
  let items = all_pending_items()
  assert_eq(items.length(), 4)
  assert_eq(items[0].status, "已过时")
  assert_eq(items[3].competition, "Qoder 高校创造力大赛")
  assert_eq(items[3].status, "已确认")
  assert_eq(items[3].resolved_at, "2026-11-18")
  for index in [1, 2] {
    assert_eq(items[index].status, "待确认")
    assert_eq(items[index].owner, "用户本人")
  }
}

///|
test "whole evidence audit retains all targets and lists missing material proof" {
  let report = audit_evidence(
    all_competitions(),
    all_works(),
    date_to_days("2026-11-20"),
  )
  assert_eq(report.decisions.length(), 84)
  assert_true(report.issues.any(issue => issue.kind == "缺事实证据"))
  assert_true(report.rules.length() >= 6)
}

///|
test "blank fact evidence or source cannot support a first-public claim" {
  let work = order_work()
  for (evidence, source) in [("", "source"), ("proof", " ")] {
    let facts : WorkEvidence = {
      first_public_date: work.first_public_date,
      first_public: Some({ fact: "首次公开", evidence, source, }),
      submitted: [],
    }
    assert_true(
      audit_work_facts(work, facts, "首次发布").any(issue => {
        issue.detail == "首次公开"
      }),
    )
  }
}

///|
test "unrecorded rule citations are exposed by the full audit" {
  let comp = order_fixture("unknown-rule", first=true)
  let report = audit_evidence(
    [comp],
    [order_work()],
    date_to_days("2026-11-20"),
  )
  assert_true(report.issues.any(issue => issue.kind == "缺原文"))
  assert_true(report.issues.any(issue => issue.kind == "缺来源"))
  assert_true(report.issues.any(issue => issue.kind == "缺核实日期"))
}

///|
test "changing the first-public claim invalidates the stored fact evidence" {
  guard work_by_name("第零次黎明") is Some(work) else {
    abort("missing work")
  }
  let changed = { ..work, first_public_date: "2026-11-20", }
  assert_true(
    fact_evidence_issues(changed, rule="首次发布").any(issue => {
      issue.detail == "首次公开"
    }),
  )
  assert_true(evidence_for_work(work).first_public is Some(_))
  assert_true(evidence_for_work(changed).first_public is None)
  guard competition_by_name("魔搭 AI+∞ 第三期「AI 造游戏」")
    is Some(comp) else {
    abort("missing competition")
  }
  assert_false(
    trace_first_publish(changed, comp).steps.any(step => {
      step.contains("Combos 分享页")
    }),
  )
  assert_eq(
    audit_decision(
      trace_first_publish(changed, comp),
      changed,
      date_to_days("2026-11-20"),
    ).grade,
    "待核对",
  )
}

///|
test "audit never certifies evidence from a different work or a padded placeholder" {
  guard work_by_name("第零次黎明") is Some(work) else {
    abort("missing work")
  }
  guard work_by_name("验价尺") is Some(other) else { abort("missing work") }
  guard competition_by_name("Qoder 高校创造力大赛") is Some(comp) else {
    abort("missing competition")
  }
  let trace = trace_all_rules(work, comp)[0]
  let audit = audit_decision(trace, other, date_to_days("2026-11-20"))
  assert_false(audit.evidence_current)
  assert_eq(audit.grade, "待核对")
  assert_eq(
    audit_rule(
      { ..audit_citation(), source: " 未收录 ", },
      date_to_days("2026-11-20"),
    ).grade,
    "待核对",
  )
}

///|
test "pack certification cannot reuse a verdict from another target" {
  let work = order_work()
  let first = order_fixture("合成目标A")
  let second = order_fixture("合成目标B")
  let wrong = row_verdict(first, date_to_days("2026-11-20"))
  let result = certify_pack(
    work,
    second,
    detect_conflicts(work, [second]),
    wrong,
  )
  assert_false(result.certifiable)
  assert_true(result.reasons.any(reason => reason.contains("不匹配")))
}
