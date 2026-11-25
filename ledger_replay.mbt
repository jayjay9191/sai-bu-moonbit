///|
pub(all) struct LedgerCheckpoint {
  known_on : String
  source : String
  competitions : Array[Competition]
  works : Array[Work]
}

///|
pub(all) enum LedgerChange {
  UpdateRule(Competition)
  RecordSubmission(String, String)
  CorrectSubmission(String, String)
}

///|
/// A correction supersedes incorrect evidence. It does not model a withdrawal
/// from a competition that the work actually entered.
pub(all) struct LedgerObservation {
  known_on : String
  effective_on : String?
  source : String
  change : LedgerChange
}

///|
pub(all) struct LedgerReplay {
  checkpoint : LedgerCheckpoint
  competitions : Array[Competition]
  works : Array[Work]
  applied : Array[LedgerObservation]
}

///|
pub suberror LedgerReplayError {
  InvalidLedgerEvidence(String)
  NoLedgerCheckpoint(String)
}

///|
fn replay_date(date : String) -> Int32 raise LedgerReplayError {
  if !is_valid_date(date) {
    raise InvalidLedgerEvidence("invalid ledger date: " + date)
  }
  date_to_days(date)
}

///|
/// Replay only evidence available by the supplied date. A late observation
/// enters the known state on its recording date, even if the fact is older.
/// When the effective date is unknown, use recording day as the visibility boundary.
pub fn replay_ledger(
  checkpoints : Array[LedgerCheckpoint],
  observations : Array[LedgerObservation],
  audit_on : String,
) -> LedgerReplay raise LedgerReplayError {
  replay_ledger_as_of(checkpoints, observations, audit_on, audit_on)
}

///|
/// Reconstruct a historical audit using evidence recorded by a later date.
/// A checkpoint cannot supply facts from after the audit day. Evidence with
/// no effective date is treated as effective when recorded. For explicit rule
/// versions, use the latest effective date and then the latest receipt date.
pub fn replay_ledger_as_of(
  checkpoints : Array[LedgerCheckpoint],
  observations : Array[LedgerObservation],
  audit_on : String,
  known_on : String,
) -> LedgerReplay raise LedgerReplayError {
  let day = replay_date(audit_on)
  let known_cutoff = replay_date(known_on)
  if known_cutoff < day {
    raise InvalidLedgerEvidence("evidence cutoff precedes audit day")
  }
  let mut selected : LedgerCheckpoint? = None
  let mut selected_day = -2147483648
  let checkpoint_days : Map[Int32, Bool] = Map([])
  for checkpoint in checkpoints {
    let date = replay_date(checkpoint.known_on)
    if checkpoint.source.trim().is_empty() || checkpoint_days.contains(date) {
      raise InvalidLedgerEvidence(
        "checkpoint requires a unique date and a source",
      )
    }
    checkpoint_days[date] = true
    if date <= day && date > selected_day {
      selected = Some(checkpoint)
      selected_day = date
    }
  }
  guard selected is Some(checkpoint) else { raise NoLedgerCheckpoint(audit_on) }

  let comps = checkpoint.competitions.copy()
  let works = checkpoint.works.copy()
  let order : Array[(Int32, Int32, Int32)] = []
  let rule_effective_days : Map[String, Int32] = Map([])
  for i in 0..<observations.length() {
    let event = observations[i]
    let known = replay_date(event.known_on)
    let effective = match event.effective_on {
      Some(value) => replay_date(value)
      None => known
    }
    if event.source.trim().is_empty() {
      raise InvalidLedgerEvidence("ledger observations require a source")
    }
    if known > known_cutoff || effective > day {
      continue
    }
    if known.max(effective) >= selected_day {
      order.push((known, i, effective))
    } else if event.change is UpdateRule(rule) {
      // The checkpoint already incorporates this explicit rule history.
      let previous = rule_effective_days.get(rule.name).unwrap_or(effective)
      rule_effective_days[rule.name] = previous.max(effective)
    }
  }
  order.sort_by((a, b) => {
    let by_date = a.0.compare(b.0)
    if by_date == 0 {
      a.1.compare(b.1)
    } else {
      by_date
    }
  })
  let applied : Array[LedgerObservation] = []
  for item in order {
    let (_, i, effective) = item
    let event = observations[i]
    match event.change {
      UpdateRule(rule) => {
        if rule_effective_days.get(rule.name) is Some(previous) &&
          effective < previous {
          continue
        }
        rule_effective_days[rule.name] = effective
        match comps.search_by(row => row.name == rule.name) {
          Some(index) => comps[index] = rule
          None => comps.push(rule)
        }
      }
      RecordSubmission(work, competition)
      | CorrectSubmission(work, competition) => {
        guard works.search_by(row => row.name == work) is Some(index) else {
          raise InvalidLedgerEvidence("unrecognized work: " + work)
        }
        if competition.trim().is_empty() {
          raise InvalidLedgerEvidence("submission requires a competition")
        }
        let row = works[index]
        let submitted_to = if event.change is RecordSubmission(_, _) {
          if contains_string(row.submitted_to, competition) {
            row.submitted_to.copy()
          } else {
            let submissions = row.submitted_to.copy()
            submissions.push(competition)
            submissions
          }
        } else {
          row.submitted_to.filter(item => item != competition)
        }
        works[index] = { ..row, submitted_to, }
      }
    }
    applied.push(event)
  }
  { checkpoint, competitions: comps, works, applied, }
}

///|
pub fn recorded_ledger_at(day : String) -> LedgerReplay raise LedgerReplayError {
  replay_ledger(ledger_checkpoints(), recorded_ledger_observations(), day)
}

///|
pub fn recorded_ledger_as_of(
  audit_on : String,
  known_on : String,
) -> LedgerReplay raise LedgerReplayError {
  replay_ledger_as_of(
    ledger_checkpoints(),
    recorded_ledger_observations(),
    audit_on,
    known_on,
  )
}
