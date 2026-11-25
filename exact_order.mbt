///|
#derive(ToJson)
pub(all) struct ExactFirstChoice {
  name : String
  completed : Int32
  lost_steps : Int32?
  blockers : Array[String]
}

///|
#derive(ToJson)
pub(all) struct ExactDropImpact {
  name : String
  completed : Int32
  lost_steps : Int32
}

///|
#derive(ToJson)
pub(all) struct ExactWaiverRoute {
  waived : Array[String]
  steps : Array[String]
}

///|
priv struct ReachedRoute {
  steps : Array[String]
  discovery : Int32
}

///|
#derive(ToJson)
pub(all) struct ExactRequiredOrder {
  requested : Array[String]
  conflict_cores : Array[Array[String]]
  minimal_waivers : Array[Array[String]]
  waiver_routes : Array[ExactWaiverRoute]
  steps : Array[String]
  optimal_order_count : Int32
}

///|
#derive(ToJson)
pub(all) struct ExactSubmissionOrder {
  steps : Array[String]
  remaining : Array[BlockedTarget]
  optimal_order_count : Int32
  required_targets : Array[String]
  possible_targets : Array[String]
  first_choices : Array[ExactFirstChoice]
  drop_impacts : Array[ExactDropImpact]
  with_required : ExactRequiredOrder?
}

///|
/// Count all longest valid sequences on one audit date, including one empty sequence
/// if no target can be completed. The example prefers earlier deadlines then names.
/// ponytail: enumerate at most seven targets; consider memoization for larger lists.
pub fn plan_exact_shortlist(
  work : Work,
  comps : Array[Competition],
  today : Int32,
  must_include~ : Array[String] = [],
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
  let mut must_mask = 0
  for name in must_include {
    let mut index = -1
    for i, comp in pending {
      if same_entry(name, comp.name) {
        index = i
        break
      }
    }
    if index < 0 {
      raise InvalidSequence("必选目标不在短名单中：" + name)
    }
    let bit = 1 << index
    if (must_mask & bit) != 0 {
      raise InvalidSequence("必选目标重复：" + name)
    }
    must_mask = must_mask | bit
  }
  let routes : Array[ReachedRoute?] = Array::make(1 << pending.length(), None)
  let mut discovery = 0
  let mut best_required : Array[String] = []
  let mut required_count = 0
  let path : Array[String] = []
  let mut best : Array[String] = []
  let mut best_state = work
  let mut optimal_order_count = 0
  let mut required_mask = 0
  let mut possible_mask = 0
  let best_by_first = Array::make(pending.length(), 0)
  let best_without = Array::make(pending.length(), 0)
  let first_blockers = pending.map(comp => sequence_reasons(work, comp, today))
  // On a fixed day, a used set fixes the recorded entrants and whether a
  // platform has supplied the publication date. Order matters for counting
  // routes and for displaying reasons, so only cache eligibility booleans.
  let eligible_by_set : Array[Array[Bool?]] = Array::makei(
    1 << pending.length(),
    _ => Array::make(pending.length(), None),
  )
  fn search(current : Work, used : Int32, first : Int32) -> Unit {
    let eligibility = eligible_by_set[used]
    if first >= 0 && path.length() > best_by_first[first] {
      best_by_first[first] = path.length()
    }
    if must_mask != 0 {
      let projection = used & must_mask
      if routes[projection]
        .map(route => route.steps.length() < path.length())
        .unwrap_or(true) {
        discovery += 1
        routes[projection] = Some({ steps: path.copy(), discovery, })
      }
    }
    if must_mask != 0 && (used & must_mask) == must_mask {
      if path.length() > best_required.length() {
        best_required = path.copy()
        required_count = 0
      }
      if path.length() == best_required.length() {
        required_count += 1
      }
    }
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
      if (used & bit) != 0 {
        continue
      }
      // The current prefix remains valid in any shortlist excluding an unused target.
      if path.length() > best_without[i] {
        best_without[i] = path.length()
      }
      let eligible = if used == 0 {
        first_blockers[i].is_empty()
      } else {
        match eligibility[i] {
          Some(cached) => cached
          None => {
            let allowed = sequence_reasons(current, comp, today).is_empty()
            eligibility[i] = Some(allowed)
            allowed
          }
        }
      }
      if !eligible {
        continue
      }
      path.push(comp.name)
      search(
        simulate_submission(current, comp, today),
        used | bit,
        if first < 0 {
          i
        } else {
          first
        },
      )
      ignore(path.pop())
    }
  }
  search(work, 0, -1)
  let first_choices = Array::makei(pending.length(), i => {
    let completed = best_by_first[i]
    {
      name: pending[i].name,
      completed,
      lost_steps: if completed == 0 {
        None
      } else {
        Some(best.length() - completed)
      },
      blockers: first_blockers[i],
    }
  })
  let drop_impacts = Array::makei(pending.length(), i => {
    let completed = best_without[i]
    { name: pending[i].name, completed, lost_steps: best.length() - completed, }
  })
  let remaining = pending
    .filter(comp => !best.contains(comp.name))
    .map(comp => {
      name: comp.name,
      reasons: sequence_reasons(best_state, comp, today),
    })
  let conflict_cores : Array[Array[String]] = []
  let waiver_routes : Array[ExactWaiverRoute] = []
  if must_mask != 0 && required_count == 0 {
    // A set of required targets is feasible if any reached mask contains it.
    for i in 0..<pending.length() {
      let bit = 1 << i
      for mask in 0..<routes.length() {
        if (mask & bit) != 0 {
          continue
        }
        if routes[mask | bit] is Some(candidate) {
          let better = routes[mask]
            .map(current => {
              candidate.steps.length() > current.steps.length() ||
              (
                candidate.steps.length() == current.steps.length() &&
                candidate.discovery < current.discovery
              )
            })
            .unwrap_or(true)
          if better {
            routes[mask] = Some(candidate)
          }
        }
      }
    }
    for mask in 1..<routes.length() {
      if (mask & must_mask) != mask || routes[mask] is Some(_) {
        continue
      }
      let core = []
      let mut minimal = true
      for i, comp in pending {
        let bit = 1 << i
        if (mask & bit) != 0 {
          if routes[mask ^ bit] is None {
            minimal = false
            break
          }
          core.push(comp.name)
        }
      }
      if minimal {
        conflict_cores.push(core)
      }
    }
    for removed in 1..<routes.length() {
      if (removed & must_mask) != removed {
        continue
      }
      let retained = must_mask ^ removed
      guard routes[retained] is Some(route) else { continue }
      let waiver = []
      let mut minimal = true
      for i, comp in pending {
        let bit = 1 << i
        if (removed & bit) != 0 {
          // Restoring any one waived requirement must make this set infeasible.
          if routes[retained | bit] is Some(_) {
            minimal = false
            break
          }
          waiver.push(comp.name)
        }
      }
      if minimal {
        waiver_routes.push({ waived: waiver, steps: route.steps.copy(), })
      }
    }
  }
  let required_targets = []
  let possible_targets = []
  let requested = []
  for i, comp in pending {
    let bit = 1 << i
    if (required_mask & bit) != 0 {
      required_targets.push(comp.name)
    }
    if (must_mask & bit) != 0 {
      requested.push(comp.name)
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
    first_choices,
    drop_impacts,
    with_required: if requested.is_empty() {
      None
    } else {
      Some({
        requested,
        conflict_cores,
        minimal_waivers: waiver_routes.map(route => route.waived.copy()),
        waiver_routes,
        steps: best_required,
        optimal_order_count: required_count,
      })
    },
  }
}

///|
#derive(ToJson)
pub(all) struct ExactPrefixStep {
  name : String
  published_on : String
  records_entry : Bool
}

///|
#derive(ToJson)
pub(all) struct ExactPrefixReplay {
  applied : Array[ExactPrefixStep]
  blocked : BlockedTarget?
  continuation : ExactSubmissionOrder?
}

///|
/// Replay a fixed prefix and solve only the remaining shortlist. No external submissions are made.
pub fn replay_submission_prefix(
  work : Work,
  targets : Array[Competition],
  today : Int32,
  prefix : Array[String],
) -> ExactPrefixReplay raise SequenceError {
  if targets.length() > 7 || prefix.length() > 7 {
    raise InvalidSequence(
      "精确重放最多接受 7 个目标和 7 个前缀步骤",
    )
  }
  validate_planning_targets(targets)
  let applied : Array[ExactPrefixStep] = []
  let mut remaining = targets.copy()
  let mut current = work
  for name in prefix {
    guard targets.iter().find_first(comp => same_entry(name, comp.name))
      is Some(comp) else {
      raise InvalidSequence("前缀目标不在短名单中：" + name)
    }
    let reasons = if remaining.any(item => item.name == comp.name) {
      sequence_reasons(current, comp, today)
    } else {
      ["前缀已执行该目标"]
    }
    if !reasons.is_empty() {
      return {
        applied,
        blocked: Some({ name: comp.name, reasons, }),
        continuation: None,
      }
    }
    let next = simulate_submission(current, comp, today)
    applied.push({
      name: comp.name,
      published_on: next.first_public_date,
      records_entry: next.submitted_to.length() > current.submitted_to.length(),
    })
    current = next
    remaining = remaining.filter(item => item.name != comp.name)
  }
  {
    applied,
    blocked: None,
    continuation: Some(plan_exact_shortlist(current, remaining, today)),
  }
}
