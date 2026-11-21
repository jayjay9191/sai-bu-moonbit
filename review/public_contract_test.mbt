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
