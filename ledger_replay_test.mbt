///|
test "ledger replay admits late discoveries, scheduled rules and corrections by date" {
  let initial = @sai-bu-moonbit.recorded_ledger_at("2026-11-20")
  let anchor = initial.checkpoint
  let work = "验价尺"
  let target = "MoonBit 黑客松"
  let rule = initial.competitions[0]
  let modified = {
    ..rule,
    requires_no_prior_entry: !rule.requires_no_prior_entry,
  }
  let observations : Array[@sai-bu-moonbit.LedgerObservation] = [
    {
      known_on: "2026-11-25",
      effective_on: None,
      source: "test correction",
      change: CorrectSubmission(work, target),
    },
    {
      known_on: "2026-11-23",
      effective_on: Some("2026-11-19"),
      source: "test late discovery",
      change: RecordSubmission(work, target),
    },
    {
      known_on: "2026-11-21",
      effective_on: Some("2026-11-24"),
      source: "test scheduled rule",
      change: UpdateRule(modified),
    },
  ]
  let before = @sai-bu-moonbit.replay_ledger(
    [anchor],
    observations,
    "2026-11-22",
  )
  let known = @sai-bu-moonbit.replay_ledger(
    [anchor],
    observations,
    "2026-11-23",
  )
  let effective = @sai-bu-moonbit.replay_ledger(
    [anchor],
    observations,
    "2026-11-24",
  )
  let corrected = @sai-bu-moonbit.replay_ledger(
    [anchor],
    observations,
    "2026-11-25",
  )
  let i = initial.works.search_by(row => row.name == work).unwrap()
  assert_true(before.works[i].submitted_to.is_empty())
  assert_eq(known.works[i].submitted_to, [target])
  assert_eq(
    known.competitions[0].requires_no_prior_entry,
    rule.requires_no_prior_entry,
  )
  assert_eq(
    effective.competitions[0].requires_no_prior_entry,
    modified.requires_no_prior_entry,
  )
  assert_true(corrected.works[i].submitted_to.is_empty())
  assert_eq(corrected.applied.map(entry => entry.known_on), [
    "2026-11-21", "2026-11-23", "2026-11-25",
  ])
  assert_true(anchor.works[i].submitted_to.is_empty())
}
