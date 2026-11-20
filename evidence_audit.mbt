///|
pub(all) struct EvidenceIssue {
  kind : String
  subject : String
  detail : String
}

///|
pub(all) struct RuleAudit {
  subject : String
  grade : String
  age : Int32?
  issues : Array[EvidenceIssue]
}

///|
/// Three non-overlapping age bands, with a separate incomplete/future state.
pub fn audit_rule(citation : RuleCitation, today : Int32) -> RuleAudit {
  let issues = []
  for
    (value, kind) in [
      (citation.rule_text, "缺原文"),
      (citation.source, "缺来源"),
      (citation.verified_at, "缺核实日期"),
    ] {
    if value.trim().is_empty() || value == "未收录" {
      issues.push({
        kind,
        subject: citation.rule,
        detail: "规则引用不完整",
      })
    }
  }
  let verified = date_to_days(citation.verified_at)
  let age = if verified < 0 || verified > today {
    None
  } else {
    Some(today - verified)
  }
  let grade = if !issues.is_empty() || age is None {
    "待核对"
  } else if age is Some(days) && days > STALE_DAYS {
    "过期"
  } else if age is Some(days) && days >= STALE_DAYS - 9 {
    "将过期"
  } else {
    "新鲜"
  }
  if age is None && citation.verified_at != "" {
    issues.push({
      kind: "缺核实日期",
      subject: citation.rule,
      detail: "日期无效或晚于审计日",
    })
  }
  { subject: citation.rule, grade, age, issues, }
}

///|
fn contains_fact(evidence : Array[FactEvidence], fact : String) -> Bool {
  evidence.any(item => {
    item.fact == fact &&
    !item.evidence.trim().is_empty() &&
    !item.source.trim().is_empty()
  })
}

///|
/// Limit decision checks to facts read by that rule; the full audit checks all facts.
pub fn fact_evidence_issues(
  work : Work,
  rule~ : String = "",
) -> Array[EvidenceIssue] {
  audit_work_facts(work, evidence_for_work(work), rule)
}

///|
fn audit_work_facts(
  work : Work,
  evidence : WorkEvidence,
  rule : String,
) -> Array[EvidenceIssue] {
  let missing = []
  if (rule == "" || rule == "首次发布" || rule == "须新做") &&
    work.first_public_date != "" {
    match evidence.first_public {
      Some(item) =>
        if item.evidence.trim().is_empty() || item.source.trim().is_empty() {
          missing.push("首次公开")
        }
      None => missing.push("首次公开")
    }
  }
  if rule == "" || rule == "首次发布" || rule == "未参加过其他比赛" {
    for fact in work.submitted_to {
      if !contains_fact(evidence.submitted, fact) {
        missing.push("已投：" + fact)
      }
    }
  }
  if rule == "" || rule == "上架资质" {
    for fact in work.materials_ready {
      if !contains_fact(evidence.submitted, fact) {
        missing.push("材料就绪：" + fact)
      }
    }
  }
  missing.map(fact => {
    kind: "缺事实证据",
    subject: work.name,
    detail: fact,
  })
}

///|
pub(all) struct AuditedDecision {
  work : String
  competition : String
  rule : String
  grade : String
  level : String
  evidence_current : Bool
}

///|
pub fn audit_decision(
  trace : DecisionTrace,
  work : Work,
  today : Int32,
) -> AuditedDecision {
  let citation = audit_rule(trace.rule, today)
  let grade = if trace.rule.rule == "" {
    "无适用规则"
  } else if !fact_evidence_issues(work, rule=trace.rule.rule).is_empty() {
    "待核对"
  } else {
    citation.grade
  }
  let current = grade == "新鲜" ||
    grade == "将过期" ||
    grade == "无适用规则"
  let level = if !current {
    trace.level + "（证据待复核）"
  } else if grade == "将过期" {
    trace.level + "（证据将过期）"
  } else {
    trace.level
  }
  {
    work: trace.work,
    competition: trace.competition,
    rule: trace.rule.rule,
    grade,
    level,
    evidence_current: current,
  }
}

///|
pub(all) struct PendingItem {
  id : String
  competition : String
  issue : String
  owner : String
  noted_at : String
  status : String
  resolved_at : String
}

///|
/// Age starts at the ledger's observation date, not a guessed creation date.
pub fn pending_age(item : PendingItem, today : Int32) -> Int32? {
  let start = date_to_days(item.noted_at)
  let finish = match item.status {
    "待确认" => today
    "已确认" | "已过时" => date_to_days(item.resolved_at)
    _ => -1
  }
  if start < 0 || finish < start || finish > today {
    None
  } else {
    Some(finish - start)
  }
}

///|
pub(all) struct EvidenceAuditReport {
  rules : Array[RuleAudit]
  decisions : Array[AuditedDecision]
  issues : Array[EvidenceIssue]
}

///|
pub fn audit_evidence(
  comps : Array[Competition],
  works : Array[Work],
  today : Int32,
) -> EvidenceAuditReport {
  let rules = []
  let decisions = []
  let issues = []
  let seen = []
  for work in works {
    for issue in fact_evidence_issues(work) {
      issues.push(issue)
    }
    for comp in comps {
      for trace in trace_all_rules(work, comp) {
        decisions.push(audit_decision(trace, work, today))
        let subject = comp.name + " / " + trace.rule.rule
        if trace.rule.rule != "" && !contains_string(seen, subject) {
          seen.push(subject)
          let result = { ..audit_rule(trace.rule, today), subject, }
          rules.push(result)
          for issue in result.issues {
            issues.push({ ..issue, subject, })
          }
        }
      }
    }
  }
  { rules, decisions, issues, }
}
