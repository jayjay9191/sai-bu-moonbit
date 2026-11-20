///|
#derive(ToJson)
pub(all) struct ExactSubmissionOrder {
  steps : Array[String]
  remaining : Array[BlockedTarget]
  optimal_order_count : Int32
  required_targets : Array[String]
  possible_targets : Array[String]
}

///|
/// Count all longest valid sequences on one audit date, including one empty sequence
/// if no target can be completed. The example prefers earlier deadlines then names.
/// ponytail: enumerate at most seven targets; consider memoization for larger lists.
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
  let mut optimal_order_count = 0
  let mut required_mask = 0
  let mut possible_mask = 0
  fn search(current : Work, used : Int32) -> Unit {
    if path.length() > best.length() {
      best = path.copy()
      best_state = current
      optimal_order_count = 0
      required_mask = used
      possible_mask = 0
    }
    if path.length() == best.length() {
      optimal_order_count += 1
      required_mask = required_mask & used
      possible_mask = possible_mask | used
    }
    for i, comp in pending {
      let bit = 1 << i
      if (used & bit) != 0 || !sequence_reasons(current, comp, today).is_empty() {
        continue
      }
      path.push(comp.name)
      search(simulate_submission(current, comp, today), used | bit)
      ignore(path.pop())
    }
  }
  search(work, 0)
  let remaining = pending
    .filter(comp => !best.contains(comp.name))
    .map(comp => {
      name: comp.name,
      reasons: sequence_reasons(best_state, comp, today),
    })
  let required_targets = []
  let possible_targets = []
  for i, comp in pending {
    let bit = 1 << i
    if (required_mask & bit) != 0 {
      required_targets.push(comp.name)
    }
    if (possible_mask & bit) != 0 {
      possible_targets.push(comp.name)
    }
  }
  {
    steps: best,
    remaining,
    optimal_order_count,
    required_targets,
    possible_targets,
  }
}
