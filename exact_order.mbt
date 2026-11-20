///|
#derive(ToJson)
pub(all) struct ExactSubmissionOrder {
  steps : Array[String]
  remaining : Array[BlockedTarget]
}

///|
/// Find a longest valid sequence on one audit date; ties prefer earlier deadlines then names.
/// ponytail: bound the shortlist to seven targets, so no memoization is needed.
pub fn plan_exact_shortlist(
  work : Work,
  comps : Array[Competition],
  today : Int32,
) -> ExactSubmissionOrder raise SequenceError {
  if comps.length() > 7 {
    raise InvalidSequence("精确顺序规划最多接受 7 个目标")
  }
  validate_planning_targets(comps)
  let pending = comps.copy()
  pending.sort_by((a, b) => {
    let a_date = if a.deadline_date == "" {
      "9999-12-31"
    } else {
      a.deadline_date
    }
    let b_date = if b.deadline_date == "" {
      "9999-12-31"
    } else {
      b.deadline_date
    }
    let date_order = a_date.compare(b_date)
    if date_order == 0 {
      a.name.compare(b.name)
    } else {
      date_order
    }
  })
  let path : Array[String] = []
  let mut best : Array[String] = []
  let mut best_state = work
  fn search(current : Work, remaining : Array[Competition]) -> Unit {
    if path.length() > best.length() {
      best = path.copy()
      best_state = current
    }
    if path.length() + remaining.length() <= best.length() {
      return
    }
    for comp in remaining {
      if !sequence_reasons(current, comp, today).is_empty() {
        continue
      }
      path.push(comp.name)
      search(
        simulate_submission(current, comp, today),
        remaining.filter(target => target.name != comp.name),
      )
      ignore(path.pop())
    }
  }
  search(work, pending)
  let remaining = pending
    .filter(comp => !best.contains(comp.name))
    .map(comp => {
      name: comp.name,
      reasons: sequence_reasons(best_state, comp, today),
    })
  { steps: best, remaining, }
}
