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

///|
test "calendar horizon includes the start and excludes the first day outside the window" {
  let staged = {
    ..order_fixture("Demo"),
    deadline: "2026-12-01 12:00（报名） / 2026-12-09 18:00（作品）",
  }
  let short = deadline_calendar([staged], "2026-12-01", days=Some(8))
  assert_true(short.contains("DTSTART;VALUE=DATE:20261201"))
  assert_false(short.contains("DTSTART;VALUE=DATE:20261209"))
  let both = deadline_calendar([staged], "2026-12-01", days=Some(9))
  assert_true(both.contains("DTSTART;VALUE=DATE:20261209"))
  assert_true(
    (Ok(deadline_calendar([staged], "2026-12-01", days=Some(0))) catch {
      e => Err(e)
    })
    is Err(_),
  )
}

///|
test "materials planning finds a shared budget bundle without certifying blocked targets" {
  let date = date_to_days("2026-11-20")
  let work = { ..order_work(), submitted_to: ["曾投稿赛事"], }
  let targets = [
    { ..order_fixture("目标 A"), materials: ["演示", "截图", "截图"], },
    { ..order_fixture("目标 B"), materials: ["演示", "截图"], },
    { ..order_fixture("目标 C"), materials: ["演示", "说明"], },
    { ..order_fixture("目标 D"), materials: ["演示"], },
    { ..order_fixture("首发限制", first=true), materials: ["演示"], },
    {
      ..order_fixture("过期"),
      deadline_date: "2026-11-19",
      materials: ["演示"],
    },
    order_fixture("已就绪"),
  ]
  let plan = plan_materials(work, targets, date, 2)
  assert_eq(plan.materials, ["截图", "演示"])
  assert_eq(plan.unlocked, ["目标 A", "目标 B", "目标 D"])
  assert_eq(plan.ready, ["已就绪"])
  assert_eq(plan_materials(work, targets, date, 1).unlocked, ["目标 D"])
  assert_eq(
    plan_materials(work, targets.rev(), date, 2).unlocked,
    plan.unlocked,
  )
  assert_eq(work.materials_ready, ["fixture"])
}

///|
test "material planning rejects the same invalid rows as ordering" {
  let date = date_to_days("2026-11-20")
  let work = order_work()
  for
    invalid in [
      order_fixture(" "),
      { ..order_fixture("Bad type"), target_kind: "待分类", },
      { ..order_fixture("Bad date"), deadline_date: "2026-02-30", },
    ] {
    let result = Ok(plan_materials(work, [invalid], date, 2)) catch {
      err => Err(err)
    }
    assert_true(result is Err(_))
  }
}

///|
test "registered competition aliases cannot inflate planning target counts" {
  let date = date_to_days("2026-11-20")
  let duplicate = [
    order_fixture("Qoder"),
    order_fixture("Qoder 高校创造力大赛"),
  ]
  let order = Ok(submission_options(order_work(), duplicate, date)) catch {
    err => Err(err)
  }
  let plan = Ok(plan_materials(order_work(), duplicate.rev(), date, 1)) catch {
    err => Err(err)
  }
  assert_true(order is Err(_))
  assert_true(plan is Err(_))
}

///|
test "calendar rejects duplicate emitted identifiers" {
  let comp = order_fixture("重复赛事")
  let result = Ok(deadline_calendar([comp, comp], "2026-11-20")) catch {
    err => Err(err)
  }
  assert_true(result is Err(_))
}

///|
test "material search matches a brute force oracle for every supported budget" {
  let date = date_to_days("2026-11-20")
  let work = order_work()
  let items = ["a", "b", "c", "d"]
  let targets = [
    { ..order_fixture("A"), materials: ["c", "b"], },
    { ..order_fixture("B"), materials: ["c", "a"], },
    { ..order_fixture("C"), materials: ["c", "d"], },
    { ..order_fixture("D"), materials: ["b"], },
    { ..order_fixture("E"), materials: ["d"], },
    { ..order_fixture("F"), materials: ["b", "d"], },
  ]
  let frontier = material_tradeoffs(work, targets.rev(), date)
  for budget in 0..<=3 {
    let optimal : Array[Array[String]] = []
    let mut expected : Array[String] = []
    let mut score = -1
    for mask in 0..<16 {
      let subset : Array[String] = []
      for i in 0..<items.length() {
        if (mask & (1 << i)) != 0 {
          subset.push(items[i])
        }
      }
      if subset.length() > budget {
        continue
      }
      let simulated = {
        ..work,
        materials_ready: work.materials_ready + subset,
      }
      let count = targets
        .filter(comp => {
          certify_pack(simulated, comp, [], row_verdict(comp, date)).certifiable
        })
        .length()
      if count > score ||
        (count == score && subset.length() < expected.length()) {
        score = count
        expected = subset
        optimal.clear()
      }
      if count == score && subset.length() == expected.length() {
        optimal.push(subset)
        if subset.compare(expected) < 0 {
          expected = subset
        }
      }
    }
    let plan = plan_materials(work, targets.rev(), date, budget)
    assert_eq(plan.materials, expected)
    assert_eq(plan.unlocked.length(), score)
    assert_eq(frontier[budget].plan.materials, expected)
    assert_eq(frontier[budget].plan.unlocked.length(), score)
    assert_eq(frontier[budget].optimal_count, optimal.length())
    assert_eq(
      frontier[budget].required_materials,
      items.filter(item => optimal.all(choice => choice.contains(item))),
    )
    assert_eq(
      frontier[budget].possible_materials,
      items.filter(item => optimal.any(choice => choice.contains(item))),
    )
  }
}

///|
test "material frontier reports every preparation budget without changing single-budget results" {
  let work = order_work()
  let date = date_to_days("2026-11-20")
  let targets = [
    order_fixture("Ready"),
    { ..order_fixture("A"), materials: ["demo"], },
    { ..order_fixture("B"), materials: ["demo", "slides"], },
    { ..order_fixture("C"), materials: ["summary"], },
  ]
  let plans = material_frontier(work, targets, date)
  assert_eq(plans.length(), 4)
  assert_eq(plans.map(plan => plan.unlocked.length()), [0, 1, 2, 3])
  for i in 0..<plans.length() {
    let separate = plan_materials(work, targets.rev(), date, i)
    assert_eq(plans[i].materials, separate.materials)
    assert_eq(plans[i].unlocked, separate.unlocked)
    assert_eq(plans[i].ready, ["Ready"])
  }
  plans[0].ready.clear()
  assert_eq(plans[1].ready, ["Ready"])
  assert_eq(work.materials_ready, ["fixture"])
}

///|
test "material explanations keep gaps separate from rules and match frontier eligibility" {
  let date = date_to_days("2026-11-20")
  let work = { ..order_work(), submitted_to: ["Qoder"], }
  let targets = [
    order_fixture("Ready"),
    { ..order_fixture("Material"), materials: ["demo", "demo"], },
    { ..order_fixture("Qoder 高校创造力大赛"), materials: ["slides"], },
    {
      ..order_fixture("Past"),
      deadline_date: "2026-11-19",
      materials: ["demo"],
    },
  ]
  let rows = material_eligibility(work, targets, date)
  assert_eq(rows[0].missing, [])
  assert_eq(rows[0].blockers, [])
  assert_eq(rows[1].missing, ["demo"])
  assert_eq(rows[1].blockers, [])
  assert_eq(rows[2].missing, ["slides"])
  assert_true(
    rows[2].blockers.any(reason => reason.contains("已登记投稿")),
  )
  assert_true(!rows[3].blockers.is_empty())
  assert_eq(material_frontier(work, targets, date)[3].unlocked, ["Material"])
  assert_eq(work.materials_ready, ["fixture"])
}

///|
test "material explanation does not omit targets outside the supported budget" {
  let work = order_work()
  let date = date_to_days("2026-11-20")
  let targets = [{ ..order_fixture("Long"), materials: ["a", "b", "c", "d"], }]
  let rows = material_eligibility(work, targets, date)
  assert_eq(rows[0].missing, ["a", "b", "c", "d"])
  assert_eq(rows[0].blockers, [])
  assert_eq(material_frontier(work, targets, date)[3].unlocked, [])
}

///|
test "material tradeoffs count tied minimum bundles and identify universally required materials" {
  let date = date_to_days("2026-11-20")
  let work = order_work()
  let targets = [
    { ..order_fixture("A"), materials: ["a", "b"], },
    { ..order_fixture("B"), materials: ["a", "c"], },
    {
      ..order_fixture("Expired"),
      deadline_date: "2026-11-19",
      materials: ["a", "c"],
    },
  ]
  let steps = material_tradeoffs(work, targets, date)
  assert_eq(steps[1].optimal_count, 1)
  assert_eq(steps[1].possible_materials, [])
  assert_eq(steps[2].optimal_count, 2)
  assert_eq(steps[2].required_materials, ["a"])
  assert_eq(steps[2].possible_materials, ["a", "b", "c"])
  assert_eq(steps[2].plan.materials, ["a", "b"])
  assert_eq(steps[3].optimal_count, 1)
  assert_eq(steps[3].required_materials, ["a", "b", "c"])
  assert_eq(steps[3].plan.unlocked, ["A", "B"])
}

///|
test "material planning cannot infer new-work eligibility from a missing publication date" {
  guard work_by_name("小店日结") is Some(work) else {
    abort("missing ledger work")
  }
  guard competition_by_name("知乎黑客松 S3") is Some(target) else {
    abort("missing ledger target")
  }
  let today = date_to_days("2026-11-20")
  let complete = {
    ..work,
    materials_ready: work.materials_ready + target.materials,
  }
  let proof = certify_pack(complete, target, [], row_verdict(target, today))
  assert_false(proof.certifiable)
  assert_true(proof.reasons.any(reason => reason.contains("其他投稿")))
  let trace = trace_new_work(work, target)
  assert_eq(trace.level, "P1")
  assert_true(trace.steps.any(step => step.contains("其他投稿记录")))
  assert_true(
    material_tradeoffs(work, [target], today)[3].plan.unlocked.is_empty(),
  )
}

///|
test "exact shortlist order detects mutually exclusive first-public targets" {
  let work = order_work()
  let today = date_to_days("2026-11-20")
  let targets = [
    order_fixture("A"),
    order_fixture("B", first=true),
    order_fixture("C", first=true),
  ]
  assert_true(
    submission_options(work, targets, today).all(option => option.can_submit),
  )
  let best = plan_exact_shortlist(work, targets, today)
  assert_eq(best.steps, ["B", "A"])
  assert_eq(best.remaining.map(row => row.name), ["C"])
  assert_true(
    best.remaining[0].reasons.any(reason => reason.contains("首次发布")),
  )
  assert_eq(plan_exact_shortlist(work, targets.rev(), today).steps, best.steps)
  assert_true(work.submitted_to.is_empty())
}

///|
test "exact shortlist keeps targets that become legal after platform publication" {
  let first = order_fixture("A", first=true)
  let platform = { ..order_fixture("B"), target_kind: "平台上架", }
  let work = { ..order_work(), first_public_date: "", }
  let today = date_to_days("2026-11-20")
  let best = plan_exact_shortlist(work, [first, platform], today)
  assert_eq(best.steps, ["B", "A"])
  assert_eq(best.remaining.length(), 0)
  assert_eq(work.first_public_date, "")
  let oversized = Array::makei(8, i => order_fixture(i.to_string()))
  let result = Ok(plan_exact_shortlist(work, oversized, today)) catch {
    err => Err(err)
  }
  assert_true(result is Err(_))
}

///|
test "exact shortlist counts every permutation at the seven-target boundary" {
  let targets = ["A", "B", "C", "D", "E", "F", "G"]
  let work = order_work()
  let competitions = targets.rev().map(name => order_fixture(name))
  let today = date_to_days("2026-11-20")
  let route = plan_exact_shortlist(work, competitions, today)
  let expected = 7 * 6 * 5 * 4 * 3 * 2
  assert_eq(route.steps, targets)
  assert_eq(route.optimal_order_count, expected)
  assert_eq(route.required_targets, targets)
  assert_eq(route.possible_targets, targets)
  assert_true(route.remaining.is_empty())
  let plans = plan_order_material_choices(work, competitions, today, 3, [])
  assert_true(plans.all(plan => plan.unwrap().optimal_order_count == expected))
  assert_true(plans.all(plan => plan.unwrap().plan.steps == targets))
}

///|
test "exact shortlist matches a mixed seven-target oracle" {
  let archived_platform = "itch.io 游戏上架"
  let names = ["A", "B", "C", "D", "E", "F", archived_platform]
  let work = {
    ..order_work(),
    first_public_date: "",
    submitted_to: [archived_platform],
  }
  let targets = names.map(name => {
    let target = order_fixture(name, first=name == "C" || name == "D")
    if name == "A" || name == "B" || name == archived_platform {
      { ..target, target_kind: "平台上架", }
    } else {
      target
    }
  })
  // Generate prefixes independently. C or D needs a preceding publication
  // and must be the first competition. The archived platform cannot repeat.
  let legal : Array[Array[String]] = []
  fn enumerate(path : Array[String]) -> Unit {
    if path.contains(archived_platform) {
      return
    }
    for i, name in path {
      if (name == "C" || name == "D") &&
        (i == 0 || !path[:i].iter().all(item => item == "A" || item == "B")) {
        return
      }
    }
    legal.push(path)
    for name in names {
      if !path.contains(name) {
        enumerate(path + [name])
      }
    }
  }
  enumerate([])
  let longest = legal.fold(init=0, (acc, row) => acc.max(row.length()))
  let best = legal.filter(row => row.length() == longest)
  best.sort()
  let today = date_to_days("2026-11-20")
  let actual = plan_exact_shortlist(work, targets.rev(), today, must_include=[
    "C", "D", archived_platform,
  ])
  assert_eq(actual.steps, best[0])
  assert_eq(actual.optimal_order_count, best.length())
  assert_eq(
    actual.required_targets,
    names.filter(name => best.all(row => row.contains(name))),
  )
  assert_eq(
    actual.possible_targets,
    names.filter(name => best.any(row => row.contains(name))),
  )
  for i, name in names {
    let first = legal.filter(row => row.get(0) == Some(name))
    let without = legal.filter(row => !row.contains(name))
    assert_eq(
      actual.first_choices[i].completed,
      first.fold(init=0, (acc, row) => acc.max(row.length())),
    )
    assert_eq(
      actual.drop_impacts[i].completed,
      without.fold(init=0, (acc, row) => acc.max(row.length())),
    )
  }
  let required = actual.with_required.unwrap()
  assert_eq(required.conflict_cores, [["C", "D"], [archived_platform]])
  assert_eq(required.minimal_waivers, [
    ["C", archived_platform],
    ["D", archived_platform],
  ])
  for rescue in required.waiver_routes {
    let retained = required.requested.filter(name => {
      !rescue.waived.contains(name)
    })
    let feasible = legal.filter(row => retained.all(name => row.contains(name)))
    let longest = feasible.fold(init=0, (acc, row) => acc.max(row.length()))
    let best = feasible.filter(row => row.length() == longest)
    best.sort()
    assert_eq(rescue.steps, best[0])
  }
}

///|
test "bench exact shortlist with seven compatible targets" (it : @bench.T) {
  let work = order_work()
  let names = ["A", "B", "C", "D", "E", "F", "G"]
  let targets = names.map(name => order_fixture(name))
  let today = date_to_days("2026-11-20")
  it.bench(fn() { it.keep(try! plan_exact_shortlist(work, targets, today)) })
}

///|
test "bench joint planning with shared material and seven targets" (
  it : @bench.T,
) {
  let work = order_work()
  let names = ["A", "B", "C", "D", "E", "F", "G"]
  let targets = names.map(name => {
    ..order_fixture(name),
    materials: ["fixture", "shared material"],
  })
  let today = date_to_days("2026-11-20")
  it.bench(fn() {
    it.keep(try! plan_order_material_choices(work, targets, today, 3, []))
  })
}
