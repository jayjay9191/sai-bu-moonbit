///|
/// preflight：全链路预检（学 Auto-Lexmount 的 preflight 纪律，自己重写）。
/// Auto-Lexmount 的做法（读过它的 submission.py / workflow.py / release.py，
/// 代码没抄——它是 Python，这里是 MoonBit）：
/// - 分阶段推进，每阶段产物带 SHA-256，改过就拒绝（"Saved artifact changed"）
/// - 提交前逐项检查：演示产物拒绝、清单哈希重算、测试必须通过、
///   真实证据、截止未过期、视觉验收绑定最终页面哈希
/// - 结果未知（超时）标 unknown，禁止自动重试，必须人工去官网核对
/// 这里的对应做法：
/// - 一次跑完 validate → 逐行核验状态 → 冲突检测 → 投稿包 → 撞期提醒 → 截止检查
/// - 单个投稿包只有同时满足：无 P0 冲突、材料无缺口、该比赛行已核实且未过期，
///   才算“可提交”；否则逐项写清拒绝原因
/// - 不自动重试：preflight 是纯本地单次运行，没有任何重试；失败原因直接打印
/// - 清单哈希 = 全部台账数据的规范序列化再算 SHA-256；数据一变哈希就变
/// - 退出码：只有 validate 有问题才返回 1；单个包的拒绝是结论，不是进程失败

///|
/// "YYYY-MM-DD" → 自 1970-01-01 起的天数；格式不对返回 -1。
/// 算法：Howard Hinnant days_from_civil。
pub fn date_to_days(s : String) -> Int32 {
  if !is_valid_date(s) {
    return -1
  }
  let chars = s.to_array()
  let y = digit_value(chars[0]) * 1000 +
    digit_value(chars[1]) * 100 +
    digit_value(chars[2]) * 10 +
    digit_value(chars[3])
  let m = digit_value(chars[5]) * 10 + digit_value(chars[6])
  let d = digit_value(chars[8]) * 10 + digit_value(chars[9])
  days_from_civil(y, m, d)
}

///|
fn digit_value(c : Char) -> Int32 {
  match c {
    '0' => 0
    '1' => 1
    '2' => 2
    '3' => 3
    '4' => 4
    '5' => 5
    '6' => 6
    '7' => 7
    '8' => 8
    '9' => 9
    _ => -1
  }
}

///|
fn days_from_civil(y0 : Int32, m : Int32, d : Int32) -> Int32 {
  let y = if m <= 2 { y0 - 1 } else { y0 }
  let era_num = if y >= 0 { y } else { y - 399 }
  let era = era_num / 400
  let yoe = y - era * 400
  let mp = if m > 2 { m - 3 } else { m + 9 }
  let doy = (153 * mp + 2) / 5 + d - 1
  let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy
  era * 146097 + doe - 719468
}

///|
/// 天数 → (年, 月, 日)。算法：Howard Hinnant civil_from_days。
pub fn civil_from_days(z0 : Int32) -> (Int32, Int32, Int32) {
  let z = z0 + 719468
  let era_num = if z >= 0 { z } else { z - 146096 }
  let era = era_num / 146097
  let doe = z - era * 146097
  let yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365
  let y = yoe + era * 400
  let doy = doe - (365 * yoe + yoe / 4 - yoe / 100)
  let mp = (5 * doy + 2) / 153
  let d = doy - (153 * mp + 2) / 5 + 1
  let m = if mp < 10 { mp + 3 } else { mp - 9 }
  if m <= 2 {
    (y + 1, m, d)
  } else {
    (y, m, d)
  }
}

///|
/// 毫秒时间戳（@env.now()）→ "YYYY-MM-DD"。
pub fn today_string(now_ms : UInt64) -> String {
  let days = (now_ms / 86400000UL).to_int()
  let (y, m, d) = civil_from_days(days)
  y.to_string().pad_start(4, '0') +
  "-" +
  m.to_string().pad_start(2, '0') +
  "-" +
  d.to_string().pad_start(2, '0')
}

///|
/// 毫秒时间戳 → 自 1970-01-01 起的天数。
pub fn today_days(now_ms : UInt64) -> Int32 {
  (now_ms / 86400000UL).to_int()
}

///|
/// 核验过期阈值：verified_at 距今超过 30 天算过期。
/// 30 天是本工具的政策，不是官方规定；写在这里，别藏着。
pub const STALE_DAYS : Int32 = 30

///|
/// 一行台账的核验结论。
pub struct RowVerdict {
  competition : String
  verified : Bool // 已核实且未过期
  reason : String // "" 表示已核实；否则写清原因
}

///|
/// 一个投稿包的认证结论。
pub struct PackVerdict {
  work : String
  competition : String
  certifiable : Bool // 可提交
  blocked : Bool // 被 P0 挡住
  reasons : Array[String] // 拒绝原因；可提交时为空
}

///|
pub struct PreflightReport {
  today : String
  validate_issues : Array[String]
  rows : Array[RowVerdict]
  packs : Array[PackVerdict]
  collisions : Array[String] // 撞期日期
  certifiable_count : Int32
  blocked_count : Int32
  manifest_hash : String
}

///|
/// 未核实标记：deadline、奖金、note 里出现这些词，说明该行有字段没核实过。
/// 逐字匹配，不猜含义；标记本身是数据里的原话。
fn has_unverified_marker(c : Competition) -> Bool {
  let text = c.deadline + "|" + c.prize + "|" + c.note
  let markers = [
    "未核实", "待核对", "未确认", "待确认", "未公布", "打不开",
  ]
  for i in 0..<markers.length() {
    if text.contains(markers[i]) {
      return true
    }
  }
  false
}

///|
fn invalid_deadline_reason(comp : Competition) -> String {
  "截止日期缺失或格式无效：" + comp.deadline_date
}

///|
/// 单行核验：截止格式与有效期 → 未核实标记 → 核验过期。
/// 全过才算已核实。
pub fn row_verdict(c : Competition, today : Int32) -> RowVerdict {
  if !valid_target_deadline(c) {
    return {
      competition: c.name,
      verified: false,
      reason: invalid_deadline_reason(c),
    }
  }
  if c.deadline_date != "" && date_to_days(c.deadline_date) < today {
    return {
      competition: c.name,
      verified: false,
      reason: "已过截止：" + c.deadline_date,
    }
  }
  if has_unverified_marker(c) {
    return {
      competition: c.name,
      verified: false,
      reason: "数据未核实：deadline/奖金/note 里有未核实标记",
    }
  }
  let verified = date_to_days(c.verified_at)
  if verified < 0 {
    return {
      competition: c.name,
      verified: false,
      reason: "核验日期格式不对：" + c.verified_at,
    }
  }
  if verified > today {
    return {
      competition: c.name,
      verified: false,
      reason: "核验日期晚于审计日：" + c.verified_at,
    }
  }
  if today - verified > STALE_DAYS {
    return {
      competition: c.name,
      verified: false,
      reason: "核验过期：verified_at " +
      c.verified_at +
      " 距今 " +
      (today - verified).to_string() +
      " 天（超过 30 天）",
    }
  }
  { competition: c.name, verified: true, reason: "", }
}

///|
/// 单个投稿包认证：无 P0、首次发布资格已核实、材料无缺口、台账已核实且未过期，条件全满足
/// 才算可提交；否则逐项写清拒绝原因。
pub fn certify_pack(
  work : Work,
  comp : Competition,
  conflicts : Array[Conflict],
  row : RowVerdict,
) -> PackVerdict {
  let blockers = pack_blockers(work, comp, conflicts)
  let pack = assemble_pack(work, comp, !blockers.is_empty())
  let reasons : Array[String] = []
  if row.competition != comp.name {
    reasons.push(
      "核验结果与投稿目标不匹配：" +
      row.competition +
      " / " +
      comp.name,
    )
  }
  let scope = scope_issue(work, comp)
  if scope != "" {
    reasons.push(scope)
  }
  for message in blockers {
    reasons.push("P0 冲突：" + message)
  }
  if comp.requires_first_publish {
    let (level, reason) = first_publish_decision(work, comp)
    if level == "P1" {
      reasons.push(reason)
    }
  }
  if comp.requires_no_prior_entry {
    let (level, reason) = no_prior_entry_decision(work, comp)
    if level == "P1" {
      reasons.push(reason)
    }
  }
  if comp.requires_new_work && work.first_public_date != "" {
    reasons.push(
      "须新做：作品已有公开版本，须补齐资格后才能认证",
    )
  }
  if pack.gaps.length() > 0 {
    reasons.push("材料缺口 " + pack.gaps.length().to_string() + " 项")
  }
  if !row.verified {
    reasons.push("数据未核实/已过期，拒绝认证：" + row.reason)
  } else if !valid_target_deadline(comp) {
    reasons.push(invalid_deadline_reason(comp))
  }
  {
    work: work.name,
    competition: comp.name,
    certifiable: reasons.length() == 0,
    blocked: pack.blocked,
    reasons,
  }
}

///|
/// 台账使用固定字段/行序的 JSON，保留字段、列表与条目的边界。
pub fn manifest_canonical(
  comps : Array[Competition],
  works : Array[Work],
) -> String {
  Json([Json("sai-bu-ledger-v2"), Json(comps), Json(works)]).stringify()
}

///|
/// 全链路预检：validate → 逐行核验 → 冲突检测 → 投稿包认证 → 撞期提醒。
/// 只读数据，不写任何东西；不联网；不重试。
pub fn preflight(
  comps : Array[Competition],
  works : Array[Work],
  now_ms : UInt64,
) -> PreflightReport {
  let today = today_days(now_ms)
  let issues = validate_data(comps, works)
  let rows : Array[RowVerdict] = []
  for i in 0..<comps.length() {
    rows.push(row_verdict(comps[i], today))
  }
  let packs : Array[PackVerdict] = []
  let mut certifiable = 0
  let mut blocked = 0
  for wi in 0..<works.length() {
    let w = works[wi]
    for ci in 0..<comps.length() {
      let v = certify_pack(w, comps[ci], [], rows[ci])
      if v.certifiable {
        certifiable = certifiable + 1
      }
      if v.blocked {
        blocked = blocked + 1
      }
      packs.push(v)
    }
  }
  {
    today: today_string(now_ms),
    validate_issues: issues,
    rows,
    packs,
    collisions: collision_dates(comps),
    certifiable_count: certifiable,
    blocked_count: blocked,
    manifest_hash: sha256_hex(manifest_canonical(comps, works)),
  }
}
