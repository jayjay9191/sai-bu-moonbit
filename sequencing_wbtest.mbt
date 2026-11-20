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
    future.reasons.any(reason => reason.contains("核验日期晚于规划日")),
  )
}
