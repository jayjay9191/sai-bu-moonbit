///|
/// 数据校验：检查台账数据本身是否自洽，返回问题列表（空列表表示通过）。
/// 校验项：
/// - 每个目标有名字；目标名字不重复
/// - target_kind 只能是“比赛”或“平台上架”
/// - deadline_date 符合 YYYY-MM-DD（月 01–12，日 01–31）；平台上架目标
///   无截止，deadline_date 为空是合法的（不参与撞期检测）
/// - verified_at 符合 YYYY-MM-DD（同上；表示该行最后核实日期）
/// - plan_status 只能是“在途”或“关注”
/// - 每个目标的材料清单非空
/// - 每件作品有名字；作品名字不重复
/// - 标志位不自相矛盾：allows_existing_works 与 requires_first_publish
///   同时为真；allows_existing_works 与 requires_new_work 同时为真；
///   allows_existing_works 与 requires_no_prior_entry 同时为真

///|
fn valid_target_deadline(comp : Competition) -> Bool {
  is_valid_date(comp.deadline_date) ||
  (comp.target_kind == "平台上架" && comp.deadline_date == "")
}

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
    if c.target_kind != "比赛" && c.target_kind != "平台上架" {
      issues.push(
        "目标《" +
        c.name +
        "》target_kind 只能是“比赛”或“平台上架”，现在是：" +
        c.target_kind,
      )
    }
    if !valid_target_deadline(c) {
      issues.push(
        "比赛《" +
        c.name +
        "》deadline_date 格式不对：" +
        c.deadline_date +
        "（应为 YYYY-MM-DD）",
      )
    }
    if (c.publish_start != "" || c.publish_end != "") &&
      (
        !is_valid_date(c.publish_start) ||
        !is_valid_date(c.publish_end) ||
        c.publish_start > c.publish_end
      ) {
      issues.push("比赛《" + c.name + "》首次公开窗口无效")
    }
    if !is_valid_date(c.verified_at) {
      issues.push(
        "比赛《" +
        c.name +
        "》verified_at 格式不对：" +
        c.verified_at +
        "（应为 YYYY-MM-DD）",
      )
    }
    if c.plan_status != "在途" && c.plan_status != "关注" {
      issues.push(
        "比赛《" +
        c.name +
        "》plan_status 只能是“在途”或“关注”，现在是：" +
        c.plan_status,
      )
    }
    if c.required_work_kind != "" &&
      c.required_work_kind != "game" &&
      c.required_work_kind != "tool" {
      issues.push("目标《" + c.name + "》作品类型限制无效")
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
    if c.allows_existing_works && c.requires_no_prior_entry {
      issues.push(
        "比赛《" +
        c.name +
        "》标志位矛盾：既允许已有成品，又要求未参加过其他比赛",
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
/// 校验实际月长及闰年。
pub fn is_valid_date(s : String) -> Bool {
  if s.length() != 10 {
    return false
  }
  // String length counts UTF-16 code units; date positions index decoded characters.
  let chars = s.to_array()
  if chars.length() != 10 || chars[4] != '-' || chars[7] != '-' {
    return false
  }
  for i in [0, 1, 2, 3, 5, 6, 8, 9] {
    if !chars[i].is_ascii_digit() {
      return false
    }
  }
  let year = digit_value(chars[0]) * 1000 +
    digit_value(chars[1]) * 100 +
    digit_value(chars[2]) * 10 +
    digit_value(chars[3])
  let month = digit_value(chars[5]) * 10 + digit_value(chars[6])
  let day = digit_value(chars[8]) * 10 + digit_value(chars[9])
  if year == 0 || month < 1 || month > 12 || day < 1 {
    return false
  }
  let leap = year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)
  let lengths = [
    31,
    if leap {
      29
    } else {
      28
    },
    31,
    30,
    31,
    30,
    31,
    31,
    30,
    31,
    30,
    31,
  ]
  day <= lengths[month - 1]
}
