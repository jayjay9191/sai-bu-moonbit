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
  let reasons = certify_pack(
    work,
    comp,
    detect_conflicts(work, [comp]),
    row_verdict(comp, today),
  ).reasons.copy()
  // Existing data uses short display names for these two already-submitted events.
  let submitted = work.submitted_to.any(name => {
    name == comp.name ||
    (name == "Qoder" && comp.name == "Qoder 高校创造力大赛") ||
    (name == "AI PLAY" && comp.name == "AI PLAY 72H 创作黑客松")
  })
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
/// Enumerate legal first choices, then simulate the remaining targets on copies.
pub fn submission_options(
  work : Work,
  comps : Array[Competition],
  today : Int32,
) -> Array[FirstSubmission] raise SequenceError {
  let names = []
  for comp in comps {
    if comp.name == "" ||
      contains_string(names, comp.name) ||
      (comp.target_kind != "比赛" && comp.target_kind != "平台上架") ||
      (comp.deadline_date != "" && !is_valid_date(comp.deadline_date)) {
      raise InvalidSequence(
        "目标名重复/为空、目标类型或截止日期无效",
      )
    }
    names.push(comp.name)
  }
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
