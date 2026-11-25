///|
/// 冲突检测引擎：这是赛簿相对 Auto-Lexmount 的核心创新之一。
/// Auto-Lexmount 只做单比赛的流水线，不检查作品跨比赛的规则冲突；
/// 这里一次扫全部 21 个投稿目标（19 个比赛 + 2 个平台上架），规则撞了就报警。

///|
pub struct Conflict {
  level : String // "P0"：提交会被取消资格；"P1"：须调整后才能交
  competition : String
  work : String
  message : String
}

///|
pub fn join_strings(items : Array[String], sep : String) -> String {
  let mut out = ""
  for i in 0..<items.length() {
    if i > 0 {
      out = out + sep
    }
    out = out + items[i]
  }
  out
}

///|
pub fn contains_string(items : Array[String], target : String) -> Bool {
  for i in 0..<items.length() {
    if items[i] == target {
      return true
    }
  }
  false
}

///|
// Old ledger rows contain short aliases for exactly these two competition names.
fn canonical_entry(name : String) -> String {
  match name {
    "Qoder" => "Qoder 高校创造力大赛"
    "AI PLAY" => "AI PLAY 72H 创作黑客松"
    _ => name
  }
}

///|
fn same_entry(left : String, right : String) -> Bool {
  canonical_entry(left) == canonical_entry(right)
}

///|
fn known_platform_entry(name : String) -> Bool {
  name == "itch.io 游戏上架" || name == "TapTap 游戏上架"
}

///|
fn other_competition_entries(work : Work, comp : Competition) -> Array[String] {
  work.submitted_to.filter(name => {
    !same_entry(name, comp.name) && !known_platform_entry(name)
  })
}

///|
/// 明确冲突优先于待核实项。日期窗口按日比较，首尾均包含。
fn first_publish_decision(work : Work, comp : Competition) -> (String, String) {
  let conflicts : Array[String] = []
  let date = work.first_public_date
  let start = comp.publish_start
  let end = comp.publish_end
  let mut pending = ""
  if !is_valid_date(start) || !is_valid_date(end) || start > end {
    pending = "首次发布待核实：活动公开窗口未收录或无效"
  } else if date == "" {
    pending = "首次发布待核实：尚未登记首次公开日期"
  } else if is_valid_date(date) {
    if date < start {
      conflicts.push("活动开始前已公开（" + date + "）")
    } else if date > end {
      conflicts.push("首次公开晚于活动截止日（" + date + "）")
    }
  } else {
    let parts = date.split(" ").collect()
    if parts.length() == 2 &&
      parts[1] == "之前" &&
      is_valid_date(parts[0].to_owned()) &&
      parts[0].to_owned() <= start {
      conflicts.push("活动开始前已公开（" + date + "）")
    } else {
      pending = "首次发布待核实：日期不足以确定是否在活动期间（" +
        date +
        "）"
    }
  }
  let other_entries = other_competition_entries(work, comp)
  if other_entries.length() > 0 {
    conflicts.push("已投 " + join_strings(other_entries, "、"))
  }
  if conflicts.length() > 0 {
    ("P0", "首次发布冲突：" + join_strings(conflicts, "，"))
  } else if pending != "" {
    ("P1", pending)
  } else {
    (
      "通过", "首次公开日期在活动窗口内，未登记其他比赛投稿",
    )
  }
}

///|
/// 只按已核实的赛事层级裁定。其他比赛名保留为待核实。
fn prior_entry_scope(name : String) -> (String, String) {
  match name {
    "第十九届全国大学生软件创新大赛" =>
      ("范围内", "https://aisoft.lnpu.edu.cn/info/1028/12632.htm")
    "第二十届全国大学生软件创新大赛" =>
      ("范围内", "https://ss.dlut.edu.cn/info/1371/35562.htm")
    _ =>
      if known_platform_entry(name) {
        ("范围外", "台账类型为平台上架")
      } else {
        ("待核实", "缺少国家级公开比赛的范围证据")
      }
  }
}

///|
fn no_prior_entry_decision(work : Work, comp : Competition) -> (String, String) {
  let confirmed : Array[String] = []
  let pending : Array[String] = []
  for name in work.submitted_to {
    if !same_entry(name, comp.name) {
      match prior_entry_scope(name).0 {
        "范围内" => confirmed.push(name)
        "待核实" => pending.push(name)
        _ => ()
      }
    }
  }
  if confirmed.length() > 0 {
    (
      "P0",
      "原创条款冲突：已登记参加其他国家级公开比赛 " +
      join_strings(confirmed, "、"),
    )
  } else if pending.length() > 0 {
    (
      "P1",
      "原创条款待核实：请补充赛事级别和公开范围证据（" +
      join_strings(pending, "、") +
      "）",
    )
  } else {
    (
      "通过", "未投过其他比赛，或已登记记录均不属于本条范围",
    )
  }
}

///|
fn new_work_issue(work : Work, comp : Competition) -> String {
  if !comp.requires_new_work {
    return ""
  }
  if !work.first_public_date.trim().is_empty() {
    return "须新做：作品已有公开版本（" +
      work.first_public_date +
      "），不能直接交"
  }
  let citation = rule_citation_for("须新做", comp.name)
  let prior = other_competition_entries(work, comp)
  if prior.is_empty() || !citation.rule_text.contains("不得一稿多投") {
    ""
  } else {
    "须新做：已有其他投稿记录（" +
    join_strings(prior, "、") +
    "），须核实新作资格"
  }
}

///|
/// 逐个目标检查一件作品的规则冲突。
/// 规则 1：窗口外首次公开或另投比赛为 P0，缺日期或窗口为 P1。
/// 规则 2（P1）：已有公开版本，或违反已收录的禁止重复投稿条款，须核实新作资格。
/// 规则 3：其他国家级公开赛事有证据则 P0，缺范围证据则 P1。
/// 规则 4（P1）：平台上架目标要求完成上架资质清单（materials 即清单，
///   如 TapTap 四项资质、itch.io 的 ZIP 包与 AI 披露），但作品有未就
///   绪项。只对 target_kind == "平台上架" 的目标生效；缺口逐项列出，
///   不阻断投稿包认证（缺口本身已让认证拒绝）。
pub fn detect_conflicts(
  work : Work,
  competitions : Array[Competition],
) -> Array[Conflict] {
  let result : Array[Conflict] = []
  for i in 0..<competitions.length() {
    let comp = competitions[i]
    if comp.requires_first_publish {
      let (level, reason) = first_publish_decision(work, comp)
      if level != "通过" {
        result.push({
          level,
          competition: comp.name,
          work: work.name,
          message: reason,
        })
      }
    }
    let new_work = new_work_issue(work, comp)
    if !new_work.is_empty() {
      result.push({
        level: "P1",
        competition: comp.name,
        work: work.name,
        message: new_work,
      })
    }
    if comp.requires_no_prior_entry {
      let (level, message) = no_prior_entry_decision(work, comp)
      if level != "通过" {
        result.push({ level, competition: comp.name, work: work.name, message, })
      }
    }
    if comp.target_kind == "平台上架" {
      let gaps : Array[String] = []
      for j in 0..<comp.materials.length() {
        if !contains_string(work.materials_ready, comp.materials[j]) {
          gaps.push(comp.materials[j])
        }
      }
      if gaps.length() > 0 {
        result.push({
          level: "P1",
          competition: comp.name,
          work: work.name,
          message: "上架资质缺口：缺 " +
          join_strings(gaps, "、") +
          "，须补齐后才能上架",
        })
      }
    }
  }
  result
}

///|
/// 同一天有 2 个及以上截止的日期（按 deadline_date 分组）。
/// 平台上架目标无截止（deadline_date 为空），不参与撞期。
pub fn collision_dates(competitions : Array[Competition]) -> Array[String] {
  let result : Array[String] = []
  let seen : Array[String] = []
  for i in 0..<competitions.length() {
    let date = competitions[i].deadline_date
    if date == "" {
      continue
    }
    if contains_string(seen, date) {
      continue
    }
    seen.push(date)
    let mut count = 0
    for j in 0..<competitions.length() {
      if competitions[j].deadline_date == date {
        count = count + 1
      }
    }
    if count > 1 {
      result.push(date)
    }
  }
  result
}

///|
/// 截止撞期提醒：同一天多个截止，列出当天所有比赛。
pub fn collision_conflicts(
  competitions : Array[Competition],
) -> Array[Conflict] {
  let result : Array[Conflict] = []
  let dates = collision_dates(competitions)
  for d in 0..<dates.length() {
    let date = dates[d]
    let names : Array[String] = []
    for i in 0..<competitions.length() {
      if competitions[i].deadline_date == date {
        names.push(competitions[i].name)
      }
    }
    result.push({
      level: "P1",
      competition: "多比赛",
      work: "",
      message: "截止撞期 " +
      date +
      "：共 " +
      "\{names.length()} 个比赛撞期——" +
      join_strings(names, "、"),
    })
  }
  result
}

///|
pub fn conflicts_for_competition(
  conflicts : Array[Conflict],
  name : String,
) -> Array[Conflict] {
  let result : Array[Conflict] = []
  for i in 0..<conflicts.length() {
    if conflicts[i].competition == name {
      result.push(conflicts[i])
    }
  }
  result
}

///|
pub fn has_p0_conflict(conflicts : Array[Conflict], name : String) -> Bool {
  let list = conflicts_for_competition(conflicts, name)
  for i in 0..<list.length() {
    if list[i].level == "P0" {
      return true
    }
  }
  false
}
