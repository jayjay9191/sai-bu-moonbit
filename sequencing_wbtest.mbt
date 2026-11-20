///|
fn order_fixture(name : String, first~ : Bool = false) -> Competition {
  guard competition_by_name("Qoder 高校创造力大赛") is Some(base) else {
    abort("missing fixture")
  }
  {
    ..base,
    name,
    deadline_date: "2026-12-01",
    verified_at: "2026-11-20",
    materials: ["fixture"],
    note: "synthetic order test",
    requires_first_publish: first,
    allows_existing_works: !first,
    publish_start: "2026-11-01",
    publish_end: "2026-12-01",
  }
}

///|
fn order_work() -> Work {
  guard work_by_name("第零次黎明") is Some(base) else {
    abort("missing fixture")
  }
  {
    ..base,
    name: "合成顺序案例",
    first_public_date: "2026-11-20",
    submitted_to: [],
    materials_ready: ["fixture"],
  }
}

///|
test "synthetic Qoder first leaves one route and blocks the first-public target" {
  let comps = [
    order_fixture("Qoder"),
    order_fixture("AI PLAY"),
    order_fixture("魔搭", first=true),
  ]
  let options = submission_options(
    order_work(),
    comps,
    date_to_days("2026-11-20"),
  )
  assert_true(options[0].can_submit)
  assert_eq(options[0].remaining, 1)
  assert_true(
    options[0].blocked.any(target => {
      target.name == "魔搭" && target.reasons.any(s => s.contains("P0"))
    }),
  )
}

///|
test "synthetic first-public target first retains the two unrestricted routes" {
  let comps = [
    order_fixture("Qoder"),
    order_fixture("AI PLAY"),
    order_fixture("魔搭", first=true),
  ]
  let options = submission_options(
    order_work(),
    comps,
    date_to_days("2026-11-20"),
  )
  assert_true(options[2].can_submit)
  assert_eq(options[2].remaining, 2)
  assert_eq(options[2].blocked.length(), 0)
}

///|
test "greedy plan preserves routes with non-increasing remaining counts" {
  let comps = [
    order_fixture("Qoder"),
    { ..order_fixture("AI PLAY"), deadline_date: "2026-11-28", },
    order_fixture("魔搭", first=true),
  ]
  let plan = plan_submission_order(
    order_work(),
    comps,
    date_to_days("2026-11-20"),
  )
  assert_eq(plan.steps.map(step => step.name), ["魔搭", "AI PLAY", "Qoder"])
  assert_eq(plan.steps.map(step => step.remaining), [2, 1, 0])
}

///|
test "unrestricted targets each retain all other eligible targets" {
  let comps = [order_fixture("A"), order_fixture("B"), order_fixture("C")]
  for
    option in submission_options(
      order_work(),
      comps,
      date_to_days("2026-11-20"),
    ) {
    assert_eq(option.remaining, 2)
  }
}

///|
test "actual Dawn cannot regain first-public eligibility by reordering" {
  guard work_by_name("第零次黎明") is Some(work) else {
    abort("missing fixture")
  }
  let comps = all_competitions().filter(c => {
    c.name.has_prefix("Qoder") ||
    c.name.has_prefix("AI PLAY") ||
    c.requires_first_publish
  })
  let options = submission_options(work, comps, date_to_days("2026-11-20"))
  assert_eq(options.length(), 3)
  assert_true(options.all(option => !option.can_submit))
  assert_eq(
    plan_submission_order(work, comps, date_to_days("2026-11-20")).steps.length(),
    0,
  )
  assert_eq(work.submitted_to, ["Qoder", "AI PLAY"])
}

///|
test "eligibility includes missing materials expired deadlines and known submissions" {
  let work = order_work()
  for
    comp in [
      { ..order_fixture("missing"), materials: ["missing"], },
      { ..order_fixture("expired"), deadline_date: "2026-11-19", },
    ] {
    assert_false(
      submission_options(work, [comp], date_to_days("2026-11-20"))[0].can_submit,
    )
  }
  assert_false(
    submission_options(
      { ..work, submitted_to: ["A"], },
      [order_fixture("A")],
      date_to_days("2026-11-20"),
    )[0].can_submit,
  )
}

///|
test "empty target lists are valid but duplicates and invalid dates are rejected" {
  assert_eq(
    submission_options(order_work(), [], date_to_days("2026-11-20")).length(),
    0,
  )
  assert_eq(
    submission_options(
      order_work(),
      [{ ..order_fixture("open"), deadline_date: "", }],
      date_to_days("2026-11-20"),
    )[0].deadline,
    "9999-12-31",
  )
  let comp = order_fixture("A")
  assert_true(
    (Ok(
      submission_options(order_work(), [comp, comp], date_to_days("2026-11-20")),
    ) catch {
      e => Err(e)
    })
    is Err(_),
  )
  assert_true(
    (Ok(
      submission_options(
        order_work(),
        [{ ..comp, deadline_date: "invalid", }],
        date_to_days("2026-11-20"),
      ),
    ) catch {
      e => Err(e)
    })
    is Err(_),
  )
}

///|
test "same-score deadlines and names give deterministic ordering" {
  let comps = [order_fixture("B"), order_fixture("A")]
  assert_eq(
    plan_submission_order(order_work(), comps, date_to_days("2026-11-20")).steps[0].name,
    "A",
  )
}

///|
test "new-work qualification and future verification dates cannot certify a submission" {
  let work = order_work()
  let comp = {
    ..order_fixture("new-work"),
    requires_new_work: true,
    allows_existing_works: false,
  }
  let conflicts = detect_conflicts(work, [comp])
  assert_false(
    certify_pack(
      work,
      comp,
      conflicts,
      row_verdict(comp, date_to_days("2026-11-20")),
    ).certifiable,
  )
  assert_false(
    submission_options(work, [comp], date_to_days("2026-11-20"))[0].can_submit,
  )
  let future = submission_options(
      work,
      [{ ..order_fixture("future"), verified_at: "2026-11-21", }],
      date_to_days("2026-11-20"),
    )[0]
  assert_false(future.can_submit)
  assert_true(
    future.reasons.any(reason => reason.contains("核验日期晚于审计日")),
  )
}

///|
test "platform publication changes public status without inventing a competition entry" {
  let work = order_work()
  let platform = {
    ..order_fixture("合成平台"),
    target_kind: "平台上架",
  }
  let first_only = order_fixture("合成首发赛", first=true)
  let options = submission_options(
    work,
    [platform, first_only],
    date_to_days("2026-11-20"),
  )
  assert_eq(options[0].remaining, 1)
  let unpublished = { ..work, first_public_date: "", }
  let new_only = {
    ..order_fixture("合成新作赛"),
    requires_new_work: true,
    allows_existing_works: false,
  }
  let after_platform = submission_options(
    unpublished,
    [platform, new_only],
    date_to_days("2026-11-20"),
  )
  assert_eq(after_platform[0].remaining, 0)
  assert_true(
    after_platform[0].blocked.any(target => {
      target.reasons.any(reason => reason.contains("须新做"))
    }),
  )
  let plan = plan_submission_order(
    unpublished,
    [platform, new_only],
    date_to_days("2026-11-20"),
  )
  assert_eq(plan.steps[0].name, "合成新作赛")
  assert_eq(unpublished.first_public_date, "")
  assert_true(
    (Ok(
      submission_options(
        work,
        [{ ..platform, target_kind: "unknown", }],
        date_to_days("2026-11-20"),
      ),
    ) catch {
      e => Err(e)
    })
    is Err(_),
  )
}

///|
test "ledger digest distinguishes entries containing separators from separate entries" {
  let work = order_work()
  let comp = order_fixture("A")
  assert_not_eq(
    manifest_canonical([comp], [{ ..work, materials_ready: ["a,b"], }]),
    manifest_canonical([comp], [{ ..work, materials_ready: ["a", "b"], }]),
  )
  assert_not_eq(
    manifest_canonical([{ ..comp, prize: "a|b", track: "c", }], [work]),
    manifest_canonical([{ ..comp, prize: "a", track: "b|c", }], [work]),
  )
}

///|
test "first-public review uses recorded dates for platforms and recognizes own entry aliases" {
  let work = order_work()
  let qoder = order_fixture("Qoder 高校创造力大赛", first=true)
  assert_eq(
    first_publish_decision(
      { ..work, submitted_to: ["itch.io 游戏上架"], },
      qoder,
    ).0,
    "通过",
  )
  assert_eq(
    first_publish_decision({ ..work, submitted_to: ["Qoder"], }, qoder).0,
    "通过",
  )
  assert_eq(
    first_publish_decision({ ..work, submitted_to: ["未知比赛"], }, qoder).0,
    "P0",
  )
  let trace = trace_first_publish(
    { ..work, submitted_to: ["itch.io 游戏上架", "Qoder"], },
    qoder,
  )
  assert_eq(trace.level, "通过")
  assert_true(
    trace.steps.any(step => step.contains("未登记其他比赛投稿")),
  )
  let options = submission_options(
    { ..work, submitted_to: ["Qoder"], },
    [qoder],
    date_to_days("2026-11-20"),
  )
  assert_eq(options[0].reasons, ["台账已登记投稿，不重复规划"])
}

///|
test "certification recomputes P0 under the current work and ignores foreign conflicts" {
  let comp = order_fixture("首发赛", first=true)
  let work = order_work()
  let prior = { ..work, submitted_to: ["其他赛"], }
  let row = row_verdict(comp, date_to_days("2026-11-20"))
  let missing = certify_pack(prior, comp, [], row)
  assert_false(missing.certifiable)
  assert_true(missing.blocked)
  assert_true(missing.reasons[0].contains("已投 其他赛"))
  assert_true(generate_pack(prior, comp, []).blocked)
  let unrelated = detect_conflicts({ ..prior, name: "另一件作品", }, [comp])
  assert_true(certify_pack(work, comp, unrelated, row).certifiable)
  assert_false(generate_pack(work, comp, unrelated).blocked)
  let supplied = detect_conflicts(prior, [comp])
  assert_eq(certify_pack(prior, comp, supplied, row).reasons, missing.reasons)
  let restricted = {
    ..comp,
    requires_first_publish: false,
    requires_no_prior_entry: true,
  }
  let entered = {
    ..work,
    submitted_to: ["第二十届全国大学生软件创新大赛"],
  }
  assert_true(certify_pack(entered, restricted, [], row).blocked)
}

///|
test "deadline validation rejects impossible or missing dates except open platforms" {
  let today = date_to_days("2026-11-20")
  let comp = order_fixture("普通赛")
  let work = order_work()
  let platform = { ..comp, target_kind: "平台上架", deadline_date: "", }
  assert_true(row_verdict(platform, today).verified)
  assert_true(validate_data([platform], [work]).is_empty())
  assert_true(
    row_verdict({ ..comp, deadline_date: "2026-11-20", }, today).verified,
  )
  for
    bad in [
      { ..comp, deadline_date: "", },
      { ..comp, deadline_date: "2026-11-31", },
      { ..platform, deadline_date: "2026-11-31", },
    ] {
    let row = row_verdict(bad, today)
    assert_false(row.verified)
    assert_true(row.reason.contains("截止日期"))
    assert_false(
      certify_pack(work, bad, [], row_verdict(comp, today)).certifiable,
    )
    assert_false(certify_pack(work, bad, [], row).certifiable)
    assert_true(
      validate_data([bad], [work]).any(text => text.contains("deadline_date")),
    )
  }
}

///|
test "deadline calendar emits verified dates with escaped and UTF-8-folded text" {
  let sample = order_fixture("日历\\测试,一；二;三\n四")
  let sample = {
    ..sample,
    deadline: "2026-12-01 12:00（报名）/ 18:00（提交）",
  }
  let open = {
    ..order_fixture("长期平台"),
    target_kind: "平台上架",
    deadline_date: "",
  }
  let past = { ..order_fixture("过期"), deadline_date: "2026-11-19", }
  let pending = { ..order_fixture("待核实事项"), deadline: "未核实", }
  let output = deadline_calendar([sample, open, past, pending], "2026-11-20")
  assert_true(output.has_prefix("BEGIN:VCALENDAR\r\n"))
  assert_true(output.has_suffix("END:VCALENDAR\r\n"))
  assert_true(output.contains("DTSTART;VALUE=DATE:20261201"))
  let unfolded = output.replace_all(old="\r\n ", new="")
  assert_true(
    unfolded.contains("SUMMARY:日历\\\\测试\\,一；二\\;三\\n四"),
  )
  assert_true(unfolded.contains("12:00（报名）/ 18:00（提交）"))
  assert_false(output.contains("长期平台"))
  assert_false(output.contains("过期"))
  assert_false(output.contains("待核实事项"))
  for line in output.split("\r\n") {
    assert_true(@utf8.encode(line.to_owned()).length() <= 75)
  }
}

///|
test "calendar keeps a verified later stage after the first deadline passes" {
  let two_days = {
    ..order_fixture("跨日样例"),
    deadline: "2026-12-01 23:59（报名）/ 2026-12-09 23:59（提交） / 2026-12-09 12:00（补充）",
  }
  let same_day = {
    ..order_fixture("同日样例"),
    deadline: "2026-12-01 12:00（报名）/ 18:00（提交）",
  }
  let before = deadline_calendar([two_days, same_day], "2026-11-20")
  assert_eq(before.split("BEGIN:VEVENT").to_array().length(), 4)
  let later = deadline_calendar([two_days, same_day], "2026-12-02")
  assert_false(later.contains("DTSTART;VALUE=DATE:20261201"))
  assert_true(later.contains("DTSTART;VALUE=DATE:20261209"))
  assert_eq(later.split("BEGIN:VEVENT").to_array().length(), 2)
  for
    deadline in [
      "2026-12-01 报名 / 2026-12-09x待定", "2026-12-01 报名 / 2026-12-09（暂定）",
      "2026-12-01X / 2026-12-09（提交）",
    ] {
    assert_false(
      deadline_calendar([{ ..two_days, deadline, }], "2026-12-02").contains(
        "BEGIN:VEVENT",
      ),
    )
  }
}

///|
test "calendar sorts out-of-order entries and later stages by date and name" {
  let staged = {
    ..order_fixture("B"),
    deadline: "2026-12-01 23:59（报名）/ 2026-12-09 23:59（提交）",
  }
  let early = { ..order_fixture("E"), deadline_date: "2026-11-27", }
  let same = order_fixture("A")
  let output = deadline_calendar([staged, early, same], "2026-11-20")
  let summaries = output
    .split("\r\n")
    .map(line => line.to_owned())
    .to_array()
    .filter(line => line.has_prefix("SUMMARY:"))
  assert_eq(summaries, [
    "SUMMARY:E", "SUMMARY:A", "SUMMARY:B", "SUMMARY:B（后续截止）",
  ])
  assert_eq(output, deadline_calendar([same, staged, early], "2026-11-20"))
}
