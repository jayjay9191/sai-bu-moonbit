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
}
