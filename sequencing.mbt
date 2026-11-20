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
  // Historical preflight keeps its existing contract; new planning enforces an as-of date.
  if date_to_days(comp.verified_at) > today {
    reasons.push("核验日期晚于规划日，须重新确认")
  }
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
      (comp.deadline_date != "" && !is_valid_date(comp.deadline_date)) {
      raise InvalidSequence("目标名重复、为空或截止日期无效")
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
      let entries = work.submitted_to.copy()
      entries.push(first.name)
      let simulated = { ..work, submitted_to: entries, }
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
    let entries = current.submitted_to.copy()
    entries.push(chosen.name)
    current = { ..current, submitted_to: entries, }
    pending = pending.filter(comp => comp.name != chosen.name)
  }
  { steps, unavailable, }
}
