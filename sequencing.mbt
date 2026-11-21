///|
#derive(Debug)
pub suberror SequenceError {
  InvalidSequence(String)
}

///|
#derive(ToJson)
pub(all) struct BlockedTarget {
  name : String
  reasons : Array[String]
}

///|
pub(all) struct FirstSubmission {
  name : String
  can_submit : Bool
  reasons : Array[String]
  remaining : Int32
  blocked : Array[BlockedTarget]
  deadline : String
}

///|
fn sequence_reasons(
  work : Work,
  comp : Competition,
  today : Int32,
) -> Array[String] {
  let reasons = certify_pack(work, comp, [], row_verdict(comp, today)).reasons.copy()
  let submitted = work.submitted_to.any(name => same_entry(name, comp.name))
  if submitted {
    reasons.push("台账已登记投稿，不重复规划")
  }
  reasons
}

///|
/// Platform distribution is publication, not competition participation.
fn simulate_submission(
  work : Work,
  target : Competition,
  today : Int32,
) -> Work {
  let entries = work.submitted_to.copy()
  let platform = target.target_kind == "平台上架"
  if !platform {
    entries.push(target.name)
  }
  {
    ..work,
    submitted_to: entries,
    first_public_date: if platform && work.first_public_date == "" {
      today_string(today.to_uint64() * 86400000UL)
    } else {
      work.first_public_date
    },
  }
}

///|
fn validate_planning_targets(
  comps : Array[Competition],
) -> Unit raise SequenceError {
  let names : Array[String] = []
  for comp in comps {
    let name = comp.name.trim().to_owned()
    if name == "" ||
      names.any(previous => {
        same_entry(previous, name) || same_entry(name, previous)
      }) ||
      (comp.target_kind != "比赛" && comp.target_kind != "平台上架") ||
      (comp.deadline_date != "" && !is_valid_date(comp.deadline_date)) {
      raise InvalidSequence(
        "目标名重复/为空、目标类型或截止日期无效",
      )
    }
    names.push(name)
  }
}

///|
/// Enumerate legal first choices, then simulate the remaining targets on copies.
pub fn submission_options(
  work : Work,
  comps : Array[Competition],
  today : Int32,
) -> Array[FirstSubmission] raise SequenceError {
  validate_planning_targets(comps)
  let options = []
  for first in comps {
    let reasons = sequence_reasons(work, first, today)
    let can_submit = reasons.is_empty()
    let blocked = []
    let mut remaining = 0
    if can_submit {
      let simulated = simulate_submission(work, first, today)
      for target in comps {
        if target.name == first.name {
          continue
        }
        let after = sequence_reasons(simulated, target, today)
        if after.is_empty() {
          remaining += 1
        } else {
          blocked.push({ name: target.name, reasons: after, })
        }
      }
    }
    options.push({
      name: first.name,
      can_submit,
      reasons,
      remaining,
      blocked,
      deadline: if first.deadline_date == "" {
        "9999-12-31"
      } else {
        first.deadline_date
      },
    })
  }
  options
}

///|
pub(all) struct SubmissionOrder {
  steps : Array[FirstSubmission]
  unavailable : Array[FirstSubmission]
}

///|
/// Greedy look-ahead maximizes retained legal routes, then takes the earliest deadline.
/// ponytail: O(n^3) certification checks for 21 targets; no permutation search.
pub fn plan_submission_order(
  work : Work,
  comps : Array[Competition],
  today : Int32,
) -> SubmissionOrder raise SequenceError {
  let mut current = work
  let mut pending = comps.copy()
  let steps = []
  let mut unavailable = []
  while !pending.is_empty() {
    let options = submission_options(current, pending, today)
    let eligible = options.filter(option => option.can_submit)
    if eligible.is_empty() {
      unavailable = options
      break
    }
    eligible.sort_by((a, b) => {
      let opportunity = b.remaining.compare(a.remaining)
      let deadline = a.deadline.compare(b.deadline)
      if opportunity != 0 {
        opportunity
      } else if deadline != 0 {
        deadline
      } else {
        a.name.compare(b.name)
      }
    })
    let chosen = eligible[0]
    steps.push(chosen)
    // Names were validated as unique; chosen comes from this pending list.
    let target = pending.filter(target => target.name == chosen.name)[0]
    current = simulate_submission(current, target, today)
    pending = pending.filter(comp => comp.name != chosen.name)
  }
  { steps, unavailable, }
}

///|
#derive(ToJson)
pub(all) struct MaterialPlan {
  materials : Array[String]
  unlocked : Array[String]
  ready : Array[String]
}

///|
/// Maximize newly certifiable targets with up to three reusable materials.
/// Search only unions of complete target gaps: extra items cannot open a route.
pub fn plan_materials(
  work : Work,
  comps : Array[Competition],
  today : Int32,
  budget : Int32,
) -> MaterialPlan raise SequenceError {
  if budget < 0 || budget > 3 {
    raise InvalidSequence("材料预算须为 0 至 3 项")
  }
  search_material_bundles(work, comps, today, budget)[budget].plan
}

///|
/// Return the best independent plan at each budget from zero through three.
pub fn material_frontier(
  work : Work,
  comps : Array[Competition],
  today : Int32,
) -> Array[MaterialPlan] raise SequenceError {
  material_tradeoffs(work, comps, today).map(result => result.plan)
}

///|
pub(all) struct MaterialTradeoff {
  plan : MaterialPlan
  optimal_count : Int32
  required_materials : Array[String]
  possible_materials : Array[String]
}

///|
/// For each budget, count the bundles that maximize coverage then minimize materials.
pub fn material_tradeoffs(
  work : Work,
  comps : Array[Competition],
  today : Int32,
) -> Array[MaterialTradeoff] raise SequenceError {
  search_material_bundles(work, comps, today, 3)
}

///|
#derive(ToJson)
pub(all) struct MaterialEligibility {
  name : String
  missing : Array[String]
  blockers : Array[String]
}

///|
/// Explain every target using the same hypothetical material completion as the planner.
/// Blockers remain after all listed materials have been supplied.
pub fn material_eligibility(
  work : Work,
  comps : Array[Competition],
  today : Int32,
) -> Array[MaterialEligibility] raise SequenceError {
  validate_planning_targets(comps)
  comps.map(comp => {
    let missing = required_material_gaps(work, comp)
    let simulated = { ..work, materials_ready: work.materials_ready + missing, }
    let blockers = sequence_reasons(simulated, comp, today)
    { name: comp.name, missing, blockers, }
  })
}

///|
fn search_material_bundles(
  work : Work,
  comps : Array[Competition],
  today : Int32,
  budget : Int32,
) -> Array[MaterialTradeoff] raise SequenceError {
  let ready : Array[String] = []
  let candidates : Array[(String, Array[String])] = []
  for row in material_eligibility(work, comps, today) {
    if !row.blockers.is_empty() || row.missing.length() > budget {
      continue
    }
    if row.missing.is_empty() {
      ready.push(row.name)
    } else {
      candidates.push((row.name, row.missing))
    }
  }
  let bundles : Array[Array[String]] = [[]]
  let seen : Map[String, Bool] = { "[]": true }
  let mut index = 0
  let best : Array[MaterialTradeoff] = Array::make(budget + 1, {
    plan: { materials: [], unlocked: [], ready: [], },
    optimal_count: 0,
    required_materials: [],
    possible_materials: [],
  })
  while index < bundles.length() {
    let bundle = bundles[index]
    index += 1
    let covered : Array[String] = []
    for (name, gaps) in candidates {
      let extra = gaps.filter(item => !bundle.contains(item))
      if extra.is_empty() {
        covered.push(name)
      } else if bundle.length() + extra.length() <= budget {
        let combined = bundle + extra
        combined.sort()
        let key = Json(combined).stringify()
        if !seen.contains(key) {
          seen[key] = true
          bundles.push(combined)
        }
      }
    }
    let plan = { materials: bundle, unlocked: covered, ready: [], }
    for limit in bundle.length()..<(budget + 1) {
      let previous = best[limit]
      let difference = covered.length() - previous.plan.unlocked.length()
      let extra = bundle.length() - previous.plan.materials.length()
      if previous.optimal_count == 0 ||
        difference > 0 ||
        (difference == 0 && extra < 0) {
        best[limit] = {
          plan,
          optimal_count: 1,
          required_materials: bundle,
          possible_materials: bundle,
        }
      } else if difference == 0 && extra == 0 {
        let representative = if bundle.compare(previous.plan.materials) < 0 {
          plan
        } else {
          previous.plan
        }
        let required = previous.required_materials.filter(item => {
          bundle.contains(item)
        })
        let possible = previous.possible_materials +
          bundle.filter(item => !previous.possible_materials.contains(item))
        best[limit] = {
          plan: representative,
          optimal_count: previous.optimal_count + 1,
          required_materials: required,
          possible_materials: possible,
        }
      }
    }
  }
  ready.sort()
  best.map(entry => {
    let unlocked = entry.plan.unlocked.copy()
    let possible = entry.possible_materials.copy()
    unlocked.sort()
    possible.sort()
    {
      plan: {
        materials: entry.plan.materials.copy(),
        unlocked,
        ready: ready.copy(),
      },
      optimal_count: entry.optimal_count,
      required_materials: entry.required_materials.copy(),
      possible_materials: possible,
    }
  })
}

///|
fn required_material_gaps(work : Work, comp : Competition) -> Array[String] {
  let missing : Array[String] = []
  for material in comp.materials {
    if !work.materials_ready.contains(material) && !missing.contains(material) {
      missing.push(material)
    }
  }
  missing
}

///|
#derive(ToJson)
pub(all) struct MaterialOrderPlan {
  budget : Int32
  materials : Array[String]
  steps : Array[String]
}

///|
/// Optimize route length, then number of new materials, then step names.
/// Any optimal bundle is the union of the gaps on its route.
/// ponytail: exact enumeration is bounded to 7 targets and 3 new materials.
pub fn plan_order_materials(
  work : Work,
  targets : Array[Competition],
  today : Int32,
  max_budget : Int32,
) -> Array[MaterialOrderPlan] raise SequenceError {
  plan_order_materials_after_prefix(work, targets, today, max_budget, []).map(row => {
    row.unwrap()
  })
}

///|
/// Each index is a material budget. None means the entire prefix cannot be
/// carried out within that budget and the current eligibility rules.
pub fn plan_order_materials_after_prefix(
  work : Work,
  targets : Array[Competition],
  today : Int32,
  max_budget : Int32,
  prefix : Array[String],
) -> Array[MaterialOrderPlan?] raise SequenceError {
  if max_budget < 0 ||
    max_budget > 3 ||
    targets.length() > 7 ||
    prefix.length() > targets.length() {
    raise InvalidSequence(
      "联合规划最多 7 个目标，材料预算须为 0 至 3 项，前缀不能超过短名单",
    )
  }
  validate_planning_targets(targets)
  let prefix_indices : Array[Int32] = []
  for name in prefix {
    let mut index = -1
    for i, comp in targets {
      if same_entry(name, comp.name) {
        index = i
        break
      }
    }
    if index < 0 || prefix_indices.contains(index) {
      raise InvalidSequence("前缀目标不在短名单内或重复：" + name)
    }
    prefix_indices.push(index)
  }
  let gaps = targets.map(comp => required_material_gaps(work, comp))
  let best : Array[MaterialOrderPlan?] = Array::make(max_budget + 1, None)
  let path : Array[String] = []
  fn visit(state : Work, used : Int32, bundle : Array[String]) -> Unit {
    let depth = path.length()
    if depth >= prefix_indices.length() {
      for budget in bundle.length()..<(max_budget + 1) {
        if best[budget]
          .map(current => {
            depth > current.steps.length() ||
            (
              depth == current.steps.length() &&
              (
                bundle.length() < current.materials.length() ||
                (
                  bundle.length() == current.materials.length() &&
                  path.compare(current.steps) < 0
                )
              )
            )
          })
          .unwrap_or(true) {
          let sorted = bundle.copy()
          sorted.sort()
          best[budget] = Some({ budget, materials: sorted, steps: path.copy(), })
        }
      }
    }
    for i, comp in targets {
      let bit = 1 << i
      if (used & bit) != 0 ||
        (depth < prefix_indices.length() && i != prefix_indices[depth]) {
        continue
      }
      let extra = gaps[i].filter(item => !bundle.contains(item))
      if bundle.length() + extra.length() > max_budget {
        continue
      }
      let prepared = {
        ..state,
        materials_ready: state.materials_ready + extra,
      }
      if sequence_reasons(prepared, comp, today).is_empty() {
        path.push(comp.name)
        visit(
          simulate_submission(prepared, comp, today),
          used | bit,
          bundle + extra,
        )
        ignore(path.pop())
      }
    }
  }
  visit(work, 0, [])
  best
}
