///|
/// 数据校验：检查台账数据本身是否自洽，返回问题列表（空列表表示通过）。
/// 校验项：
/// - 每个比赛有名字；比赛名字不重复
/// - deadline_date 符合 YYYY-MM-DD（月 01–12，日 01–31）
/// - 每个比赛的材料清单非空
/// - 每件作品有名字；作品名字不重复
/// - 标志位不自相矛盾：allows_existing_works 与 requires_first_publish
///   同时为真；allows_existing_works 与 requires_new_work 同时为真

///|
pub fn validate_data(
  comps : Array[Competition],
  works : Array[Work],
) -> Array[String] {
  let issues : Array[String] = []
  let seen_comp_names : Array[String] = []
  for i in 0..<comps.length() {
    let c = comps[i]
    if c.name == "" {
      issues.push("第 \{i + 1} 个比赛没有名字")
    } else if contains_string(seen_comp_names, c.name) {
      issues.push("比赛名字重复：" + c.name)
    } else {
      seen_comp_names.push(c.name)
    }
    if !is_valid_date(c.deadline_date) {
      issues.push(
        "比赛《" +
        c.name +
        "》deadline_date 格式不对：" +
        c.deadline_date +
        "（应为 YYYY-MM-DD）",
      )
    }
    if c.materials.length() == 0 {
      issues.push("比赛《" + c.name + "》材料清单为空")
    }
    if c.allows_existing_works && c.requires_first_publish {
      issues.push(
        "比赛《" +
        c.name +
        "》标志位矛盾：既允许已有成品，又要求首次发布",
      )
    }
    if c.allows_existing_works && c.requires_new_work {
      issues.push(
        "比赛《" +
        c.name +
        "》标志位矛盾：既允许已有成品，又要求必须新做",
      )
    }
  }
  let seen_work_names : Array[String] = []
  for i in 0..<works.length() {
    let w = works[i]
    if w.name == "" {
      issues.push("第 \{i + 1} 件作品没有名字")
    } else if contains_string(seen_work_names, w.name) {
      issues.push("作品名字重复：" + w.name)
    } else {
      seen_work_names.push(w.name)
    }
  }
  issues
}

///|
/// 日期格式 YYYY-MM-DD：长度 10，第 5、8 位为 '-'，其余为数字，
/// 月 01–12，日 01–31（不校验每月实际天数，如 02-31 不拦截）。
pub fn is_valid_date(s : String) -> Bool {
  if s.length() != 10 {
    return false
  }
  let chars = s.to_array()
  if chars[4] != '-' || chars[7] != '-' {
    return false
  }
  for i in [0, 1, 2, 3, 5, 6, 8, 9] {
    if !chars[i].is_ascii_digit() {
      return false
    }
  }
  let month_ok = (chars[5] == '0' && chars[6] >= '1' && chars[6] <= '9') ||
    (chars[5] == '1' && chars[6] >= '0' && chars[6] <= '2')
  let day_ok = (chars[8] == '0' && chars[9] >= '1' && chars[9] <= '9') ||
    ((chars[8] == '1' || chars[8] == '2') && chars[9] >= '0' && chars[9] <= '9') ||
    (chars[8] == '3' && chars[9] >= '0' && chars[9] <= '1')
  month_ok && day_ok
}
