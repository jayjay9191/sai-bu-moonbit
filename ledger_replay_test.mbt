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

///|
test "two-date replay includes only retroactive evidence with a known effective date" {
  let anchor = @sai-bu-moonbit.recorded_ledger_at("2026-11-20").checkpoint
  let later = @sai-bu-moonbit.recorded_ledger_at("2026-11-23").checkpoint
  let work = "验价尺"
  let known : @sai-bu-moonbit.LedgerObservation = {
    known_on: "2026-11-23",
    effective_on: Some("2026-11-19"),
    source: "synthetic dated evidence",
    change: RecordSubmission(work, "MoonBit 黑客松"),
  }
  let unknown = {
    ..known,
    effective_on: None,
    change: RecordSubmission(work, "Qoder 高校创造力大赛"),
  }
  let future = {
    ..known,
    effective_on: Some("2026-11-22"),
    change: RecordSubmission(work, "Qoder 高校创造力大赛"),
  }
  let i = anchor.works.search_by(row => row.name == work).unwrap()
  let old = @sai-bu-moonbit.replay_ledger(
    [anchor, later],
    [known, unknown, future],
    "2026-11-20",
  )
  let revised = @sai-bu-moonbit.replay_ledger_as_of(
    [anchor, later],
    [known, unknown, future],
    "2026-11-20",
    "2026-11-23",
  )
  assert_eq(revised.checkpoint.known_on, "2026-11-20")
  assert_true(old.works[i].submitted_to.is_empty())
  assert_eq(revised.works[i].submitted_to, ["MoonBit 黑客松"])
  assert_eq(revised.applied.length(), 1)
  let bad_cutoff = try {
    ignore(
      @sai-bu-moonbit.replay_ledger_as_of(
        [anchor],
        [],
        "2026-11-20",
        "2026-11-19",
      ),
    )
    false
  } catch {
    @sai-bu-moonbit.InvalidLedgerEvidence(_) => true
    _ => false
  }
  assert_true(bad_cutoff)
}
