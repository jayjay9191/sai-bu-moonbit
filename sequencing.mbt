///|
#derive(Debug)
pub suberror SequenceError {
  InvalidSequence(String)
}

///|
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
  let ready : Array[String] = []
  let candidates : Array[(String, Array[String])] = []
  validate_planning_targets(comps)
  for comp in comps {
    let gaps : Array[String] = []
    for material in comp.materials {
      if !work.materials_ready.contains(material) && !gaps.contains(material) {
        gaps.push(material)
      }
    }
    if gaps.length() > budget {
      continue
    }
    let simulated = { ..work, materials_ready: work.materials_ready + gaps, }
    if !sequence_reasons(simulated, comp, today).is_empty() {
      continue
    }
    if gaps.is_empty() {
      ready.push(comp.name)
    } else {
      candidates.push((comp.name, gaps))
    }
  }
  let bundles : Array[Array[String]] = [[]]
  let seen : Map[String, Bool] = { "[]": true }
  let mut index = 0
  let mut best : Array[String] = []
  let mut unlocked : Array[String] = []
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
    if covered.length() > unlocked.length() ||
      (
        covered.length() == unlocked.length() &&
        (
          bundle.length() < best.length() ||
          (bundle.length() == best.length() && bundle.compare(best) < 0)
        )
      ) {
      best = bundle
      unlocked = covered
    }
  }
  unlocked.sort()
  ready.sort()
  { materials: best, unlocked, ready, }
}
