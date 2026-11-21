///|
test "review sample compares all four budgets on a recorded ledger" {
  guard @lib.work_by_name("小店日结") is Some(work) else {
    abort("missing recorded case")
  }
  let today = @lib.date_to_days("2026-11-20")
  let plans = @lib.material_frontier(work, @lib.all_competitions(), today)
  assert_eq(plans.map(plan => plan.unlocked.length()), [0, 1, 1, 2])
}

///|
test "review sample keeps a prior submission blocker after material completion" {
  guard @lib.work_by_name("第零次黎明") is Some(work) else {
    abort("missing recorded case")
  }
  let targets = @lib.all_competitions()
  let today = @lib.date_to_days("2026-11-20")
  let explained = @lib.material_eligibility(work, targets, today)
  guard explained
    .iter()
    .find_first(row => row.name == "Qoder 高校创造力大赛")
    is Some(qoder) else {
    abort("missing review target")
  }
  assert_true(!qoder.missing.is_empty())
  assert_true(qoder.blockers.any(reason => reason.contains("已登记投稿")))
  assert_true(
    @lib.material_frontier(work, targets, today).all(plan => {
      !plan.unlocked.contains(qoder.name)
    }),
  )
  guard @lib.competition_by_name(qoder.name) is Some(target) else {
    abort("missing review target")
  }
  let route = @lib.plan_exact_shortlist(work, [target], today)
  assert_true(route.steps.is_empty())
  assert_true(
    route.remaining[0].reasons.any(reason => reason.contains("已登记投稿")),
  )
}

///|
fn review_shortlist() -> (@lib.Work, Array[@lib.Competition]) {
  guard @lib.work_by_name("第零次黎明") is Some(base) &&
    @lib.competition_by_name("Qoder 高校创造力大赛") is Some(model) else {
    abort("missing base records")
  }
  let work = {
    ..base,
    name: "合成顺序案例",
    first_public_date: "2026-11-20",
    submitted_to: [],
    materials_ready: ["fixture"],
  }
  let ordinary = {
    ..model,
    name: "A",
    deadline_date: "2026-12-01",
    verified_at: "2026-11-20",
    materials: ["fixture"],
    requires_first_publish: false,
    allows_existing_works: true,
    publish_start: "2026-11-01",
    publish_end: "2026-12-01",
  }
  let first = {
    ..ordinary,
    name: "B",
    requires_first_publish: true,
    allows_existing_works: false,
  }
  let alternative = { ..first, name: "C", }
  let blocked = { ..ordinary, name: "D", materials: ["missing"], }
  (work, [alternative, blocked, ordinary, first])
}

///|
fn review_exact_order() -> @lib.ExactSubmissionOrder raise {
  let (work, choices) = review_shortlist()
  @lib.plan_exact_shortlist(work, choices, @lib.date_to_days("2026-11-20"))
}

///|
test "review distinguishes required and interchangeable targets across optimal orders" {
  let route = review_exact_order()
  assert_eq(route.steps, ["B", "A"])
  assert_eq(route.optimal_order_count, 2)
  assert_eq(route.required_targets, ["A"])
  assert_eq(route.possible_targets, ["A", "B", "C"])
}

///|
test "review compares exact outcomes after committing the first target" {
  let route = review_exact_order()
  assert_eq(
    route.first_choices.map(row => (row.name, row.completed, row.lost_steps)),
    [("A", 1, Some(1)), ("B", 2, Some(0)), ("C", 2, Some(0)), ("D", 0, None)],
  )
  assert_true(
    route.first_choices[3].blockers.any(reason => reason == "材料缺口 1 项"),
  )
}

///|
test "review dropping the platform blocks a second otherwise reachable target" {
  let (base, choices) = review_shortlist()
  let work = { ..base, first_public_date: "", }
  let platform = {
    ..choices[2],
    name: "平台上架",
    target_kind: "平台上架",
  }
  let first = choices[3]
  let route = @lib.plan_exact_shortlist(
    work,
    [first, platform],
    @lib.date_to_days("2026-11-20"),
  )
  assert_eq(route.steps, ["平台上架", "B"])
  assert_eq(
    route.drop_impacts.map(row => (row.name, row.completed, row.lost_steps)),
    [("B", 1, 1), ("平台上架", 0, 2)],
  )
  for row in route.drop_impacts {
    let reduced = [first, platform].filter(target => target.name != row.name)
    let rerun = @lib.plan_exact_shortlist(
      work,
      reduced,
      @lib.date_to_days("2026-11-20"),
    )
    assert_eq(row.completed, rerun.steps.length())
  }
}

///|
test "review requires targets jointly and distinguishes incompatible choices" {
  let (work, choices) = review_shortlist()
  let today = @lib.date_to_days("2026-11-20")
  let forced = @lib.plan_exact_shortlist(work, choices, today, must_include=[
    "C",
  ])
  guard forced.with_required is Some(plan) else {
    abort("expected required-target result")
  }
  assert_eq(plan.steps, ["C", "A"])
  assert_eq(plan.optimal_order_count, 1)
  let incompatible = @lib.plan_exact_shortlist(work, choices, today, must_include=[
    "B", "C",
  ])
  guard incompatible.with_required is Some(none) else {
    abort("expected infeasibility result")
  }
  assert_eq(none.optimal_order_count, 0)
  assert_true(none.steps.is_empty())
  assert_eq(incompatible.steps, ["B", "A"])
}

///|
test "review returns each inclusion-minimal conflict including different sizes" {
  let (work, choices) = review_shortlist()
  let today = @lib.date_to_days("2026-11-20")
  let full = @lib.plan_exact_shortlist(work, choices, today, must_include=[
    "D", "C", "A", "B",
  ])
  guard full.with_required is Some(plan) else {
    abort("expected infeasibility result")
  }
  assert_eq(plan.conflict_cores, [["B", "C"], ["D"]])
  for group in plan.conflict_cores {
    let blocked = @lib.plan_exact_shortlist(
      work,
      choices,
      today,
      must_include=group,
    )
    guard blocked.with_required is Some(reason) else {
      abort("expected conflict")
    }
    assert_eq(reason.optimal_order_count, 0)
    for removed in group {
      let subset = group.filter(name => name != removed)
      let shortened = @lib.plan_exact_shortlist(
        work,
        choices,
        today,
        must_include=subset,
      )
      assert_true(
        shortened.with_required is None ||
        shortened.with_required.unwrap().optimal_order_count > 0,
      )
    }
  }
}

///|
test "review enumerates minimal waivers and checks that every removed requirement matters" {
  let (work, choices) = review_shortlist()
  let today = @lib.date_to_days("2026-11-20")
  let required = ["A", "B", "C", "D"]
  let audit = @lib.plan_exact_shortlist(
    work,
    choices,
    today,
    must_include=required,
  )
  guard audit.with_required is Some(plan) else {
    abort("expected required audit")
  }
  assert_eq(plan.minimal_waivers, [["B", "D"], ["C", "D"]])
  for waived in plan.minimal_waivers {
    let retained = required.filter(name => !waived.contains(name))
    let repaired = @lib.plan_exact_shortlist(
      work,
      choices,
      today,
      must_include=retained,
    )
    assert_true(repaired.with_required.unwrap().optimal_order_count > 0)
    for restored in waived {
      let invalid = @lib.plan_exact_shortlist(
        work,
        choices,
        today,
        must_include=retained + [restored],
      )
      assert_eq(invalid.with_required.unwrap().optimal_order_count, 0)
    }
  }
}

///|
test "review every minimal waiver carries its longest route with stable ties" {
  let (work, choices) = review_shortlist()
  let today = @lib.date_to_days("2026-11-20")
  let required = ["D", "B", "C", "A"]
  let ordinary = { ..choices[2], name: "E", }
  let targets = choices + [ordinary]
  let plan = @lib.plan_exact_shortlist(
    work,
    targets,
    today,
    must_include=required,
  )
  guard plan.with_required is Some(audit) else {
    abort("expected waiver routes")
  }
  assert_eq(audit.waiver_routes.map(item => (item.waived, item.steps)), [
    (["B", "D"], ["C", "A", "E"]),
    (["C", "D"], ["B", "A", "E"]),
  ])
  for item in audit.waiver_routes {
    let retained = required.filter(name => !item.waived.contains(name))
    let checked = @lib.plan_exact_shortlist(
      work,
      targets.rev(),
      today,
      must_include=retained,
    )
    assert_eq(checked.with_required.unwrap().steps, item.steps)
  }
}

///|
test "review replays publication before a first-publish submission and rejects the reverse" {
  let (base, choices) = review_shortlist()
  let work = { ..base, first_public_date: "", }
  let platform = {
    ..choices[2],
    name: "平台上架",
    target_kind: "平台上架",
  }
  let targets = [choices[3], platform, choices[2]]
  let today = @lib.date_to_days("2026-11-20")
  let accepted = @lib.replay_submission_prefix(work, targets, today, [
    "平台上架",
  ])
  assert_eq(accepted.applied[0].published_on, "2026-11-20")
  assert_false(accepted.applied[0].records_entry)
  assert_eq(accepted.continuation.unwrap().steps, ["B", "A"])
  let blocked = @lib.replay_submission_prefix(work, targets, today, [
    "B", "平台上架",
  ])
  assert_true(blocked.applied.is_empty())
  assert_eq(blocked.blocked.unwrap().name, "B")
  assert_true(!blocked.blocked.unwrap().reasons.is_empty())
  assert_true(blocked.continuation is None)
  let repeated = @lib.replay_submission_prefix(work, targets, today, [
    "平台上架", "平台上架", "B",
  ])
  assert_eq(repeated.applied.length(), 1)
  assert_eq(repeated.blocked.unwrap().name, "平台上架")
  assert_true(repeated.continuation is None)
  let finished = @lib.replay_submission_prefix(work, targets, today, [
    "平台上架", "B", "A",
  ])
  assert_eq(finished.applied.map(step => step.records_entry), [
    false, true, true,
  ])
  assert_true(finished.continuation.unwrap().steps.is_empty())
  assert_eq(work.first_public_date, "")
}

///|
test "review materials and valid order are optimized jointly" {
  let (work, choices) = review_shortlist()
  let today = @lib.date_to_days("2026-11-20")
  let c = { ..choices[0], materials: ["fixture", "missing"], }
  let b = { ..choices[3], materials: ["fixture", "missing"], }
  let front = @lib.plan_order_materials(
    work,
    [c, choices[1], choices[2], b],
    today,
    2,
  )
  assert_eq(front.map(row => row.steps.length()), [1, 3, 3])
  assert_eq(front[1].materials, ["missing"])
  assert_eq(front[1].steps, ["B", "A", "D"])
  let unpublished = { ..work, first_public_date: "", }
  let platform = {
    ..choices[2],
    name: "平台",
    target_kind: "平台上架",
    materials: ["missing"],
  }
  let unlocked = @lib.plan_order_materials(
    unpublished,
    [choices[2], b, platform],
    today,
    1,
  )
  assert_eq(unlocked[1].steps, ["平台", "B", "A"])
  assert_eq(unlocked[1].materials, ["missing"])
  assert_eq(work.materials_ready, ["fixture"])
}
