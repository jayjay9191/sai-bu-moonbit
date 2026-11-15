///|
/// 冲突检测引擎：这是参赛管家相对 Auto-Lexmount 的核心创新之一。
/// Auto-Lexmount 只做单比赛的流水线，不检查作品跨比赛的规则冲突；
/// 这里一次扫全部 12 个比赛，规则撞了就报警。

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
/// 逐个比赛检查一件作品的规则冲突。
/// 规则 1（P0）：比赛要求“活动期间首次公开发布”，但作品在活动开始前
///   已公开，或已投过其他比赛。
/// 规则 2（P1）：比赛要求“必须新做”，但作品已有公开版本。
pub fn detect_conflicts(
  work : Work,
  competitions : Array[Competition],
) -> Array[Conflict] {
  let result : Array[Conflict] = []
  for i in 0..<competitions.length() {
    let comp = competitions[i]
    if comp.requires_first_publish &&
      (work.first_public_date != "" || work.submitted_to.length() > 0) {
      result.push({
        level: "P0",
        competition: comp.name,
        work: work.name,
        message: "首次发布冲突：作品在活动开始前已公开（" +
        work.first_public_date +
        "），且已投 " +
        join_strings(work.submitted_to, "、") +
        "，违反“活动期间首次公开发布、不得使用已参加其他比赛的作品”",
      })
    }
    if comp.requires_new_work && work.first_public_date != "" {
      result.push({
        level: "P1",
        competition: comp.name,
        work: work.name,
        message: "须新做：作品已有公开版本（" +
        work.first_public_date +
        "），不能直接交",
      })
    }
  }
  result
}

///|
/// 同一天有 2 个及以上截止的日期（按 deadline_date 分组）。
pub fn collision_dates(competitions : Array[Competition]) -> Array[String] {
  let result : Array[String] = []
  let seen : Array[String] = []
  for i in 0..<competitions.length() {
    let date = competitions[i].deadline_date
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
