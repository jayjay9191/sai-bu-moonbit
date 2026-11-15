///|
/// 黑盒测试：只测公开 API 的行为，不测实现细节。
/// Run `moon test` to execute and `moon test --update` to refresh snapshots.

///|
test "registry has twelve competitions" {
  assert_eq(@sai-chang-guan-jia-moonbit.all_competitions().length(), 12)
}

///|
test "registry entries have name and date" {
  let comps = @sai-chang-guan-jia-moonbit.all_competitions()
  for i in 0..<comps.length() {
    assert_true(comps[i].name != "")
    assert_true(comps[i].deadline_date != "")
    assert_true(comps[i].deadline != "")
    assert_true(comps[i].prize != "")
  }
}

///|
test "moda first-publish P0 for dawn" {
  // 《第零次黎明》11-02 前已公开且已投 Qoder/AI PLAY，
  // 魔搭要求活动期间首次发布，必须报 P0。
  match @sai-chang-guan-jia-moonbit.work_by_name("第零次黎明") {
    Some(w) => {
      let conflicts = @sai-chang-guan-jia-moonbit.detect_conflicts(
        w,
        @sai-chang-guan-jia-moonbit.all_competitions(),
      )
      assert_true(
        @sai-chang-guan-jia-moonbit.has_p0_conflict(
          conflicts, "魔搭 AI+∞ 第三期「AI 造游戏」",
        ),
      )
    }
    None => assert_true(false)
  }
}

///|
test "songjiang has no P0 for dawn" {
  // 松江明确已有成品可参赛，黎明投松江不应有 P0。
  match @sai-chang-guan-jia-moonbit.work_by_name("第零次黎明") {
    Some(w) => {
      let conflicts = @sai-chang-guan-jia-moonbit.detect_conflicts(
        w,
        @sai-chang-guan-jia-moonbit.all_competitions(),
      )
      assert_true(
        !@sai-chang-guan-jia-moonbit.has_p0_conflict(
          conflicts, "松江·创世纪 AI 游戏大赛",
        ),
      )
    }
    None => assert_true(false)
  }
}

///|
test "zhihu requires new work P1 for dawn" {
  // 知乎 S3 要求必须新做，黎明已有公开版本，应报 P1。
  match @sai-chang-guan-jia-moonbit.work_by_name("第零次黎明") {
    Some(w) => {
      let conflicts = @sai-chang-guan-jia-moonbit.detect_conflicts(
        w,
        @sai-chang-guan-jia-moonbit.all_competitions(),
      )
      let list = @sai-chang-guan-jia-moonbit.conflicts_for_competition(
        conflicts, "知乎黑客松 S3",
      )
      assert_eq(list.length(), 1)
      assert_eq(list[0].level, "P1")
    }
    None => assert_true(false)
  }
}

///|
test "dec first collision detected" {
  // 12-01 有 3 个截止：魔搭报名 12:00、魔搭提交 18:00、PAYATHON 报名 23:59。
  let dates = @sai-chang-guan-jia-moonbit.collision_dates(
    @sai-chang-guan-jia-moonbit.all_competitions(),
  )
  assert_true(@sai-chang-guan-jia-moonbit.contains_string(dates, "2026-12-01"))
  let collisions = @sai-chang-guan-jia-moonbit.collision_conflicts(
    @sai-chang-guan-jia-moonbit.all_competitions(),
  )
  assert_true(collisions.length() > 0)
}

///|
test "pack dawn to moda is blocked" {
  match @sai-chang-guan-jia-moonbit.work_by_name("第零次黎明") {
    Some(w) =>
      match
        @sai-chang-guan-jia-moonbit.competition_by_name(
          "魔搭 AI+∞ 第三期「AI 造游戏」",
        ) {
        Some(comp) => {
          let conflicts = @sai-chang-guan-jia-moonbit.detect_conflicts(
            w,
            @sai-chang-guan-jia-moonbit.all_competitions(),
          )
          let pack = @sai-chang-guan-jia-moonbit.generate_pack(
            w, comp, conflicts,
          )
          assert_true(pack.blocked)
          assert_true(pack.gaps.length() > 0)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "pack dawn to songjiang is clear" {
  match @sai-chang-guan-jia-moonbit.work_by_name("第零次黎明") {
    Some(w) =>
      match
        @sai-chang-guan-jia-moonbit.competition_by_name(
          "松江·创世纪 AI 游戏大赛",
        ) {
        Some(comp) => {
          let conflicts = @sai-chang-guan-jia-moonbit.detect_conflicts(
            w,
            @sai-chang-guan-jia-moonbit.all_competitions(),
          )
          let pack = @sai-chang-guan-jia-moonbit.generate_pack(
            w, comp, conflicts,
          )
          assert_true(!pack.blocked)
          assert_true(pack.gaps.length() > 0)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "pack tool to emerge is clear" {
  // 未公开过的小店工具投涌现奖，不应有首发冲突。
  match @sai-chang-guan-jia-moonbit.work_by_name("小店日结") {
    Some(w) =>
      match
        @sai-chang-guan-jia-moonbit.competition_by_name(
          "支付宝智能体涌现奖",
        ) {
        Some(comp) => {
          let conflicts = @sai-chang-guan-jia-moonbit.detect_conflicts(
            w,
            @sai-chang-guan-jia-moonbit.all_competitions(),
          )
          let pack = @sai-chang-guan-jia-moonbit.generate_pack(
            w, comp, conflicts,
          )
          assert_true(!pack.blocked)
          assert_eq(pack.gaps.length(), 0)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "unknown work returns none" {
  assert_true(
    @sai-chang-guan-jia-moonbit.work_by_name("不存在的作品") is None,
  )
}

///|
test "unknown competition returns none" {
  assert_true(
    @sai-chang-guan-jia-moonbit.competition_by_name("不存在的比赛")
    is None,
  )
}

///|
test "detect conflicts on empty registry" {
  match @sai-chang-guan-jia-moonbit.work_by_name("第零次黎明") {
    Some(w) => {
      let conflicts = @sai-chang-guan-jia-moonbit.detect_conflicts(w, [])
      assert_eq(conflicts.length(), 0)
    }
    None => assert_true(false)
  }
}

///|
test "collision helpers on empty registry" {
  assert_eq(@sai-chang-guan-jia-moonbit.collision_dates([]).length(), 0)
  assert_eq(@sai-chang-guan-jia-moonbit.collision_conflicts([]).length(), 0)
  assert_eq(
    @sai-chang-guan-jia-moonbit.conflicts_for_competition(
      [],
      "魔搭 AI+∞ 第三期「AI 造游戏」",
    ).length(),
    0,
  )
  assert_true(
    !@sai-chang-guan-jia-moonbit.has_p0_conflict(
      [],
      "魔搭 AI+∞ 第三期「AI 造游戏」",
    ),
  )
}

///|
test "xiaodianjie triggers moda P0 via submitted_to" {
  // 小店日结从未公开（first_public_date 为空），但已投过涌现奖；
  // 规则 1 的第二条分支（已投过其他比赛）仍应触发魔搭 P0。
  match @sai-chang-guan-jia-moonbit.work_by_name("小店日结") {
    Some(w) => {
      let conflicts = @sai-chang-guan-jia-moonbit.detect_conflicts(
        w,
        @sai-chang-guan-jia-moonbit.all_competitions(),
      )
      assert_eq(conflicts.length(), 1)
      assert_eq(conflicts[0].level, "P0")
      assert_eq(
        conflicts[0].competition,
        "魔搭 AI+∞ 第三期「AI 造游戏」",
      )
    }
    None => assert_true(false)
  }
}

///|
test "suqiu has no P1 for zhihu" {
  // 诉求整理台从未公开，知乎“须新做”规则只针对已有公开版本的作品，
  // 所以不应报 P1。
  match @sai-chang-guan-jia-moonbit.work_by_name("诉求整理台") {
    Some(w) => {
      let conflicts = @sai-chang-guan-jia-moonbit.detect_conflicts(
        w,
        @sai-chang-guan-jia-moonbit.all_competitions(),
      )
      let list = @sai-chang-guan-jia-moonbit.conflicts_for_competition(
        conflicts, "知乎黑客松 S3",
      )
      assert_eq(list.length(), 0)
    }
    None => assert_true(false)
  }
}

///|
test "join and contains on empty list" {
  assert_eq(@sai-chang-guan-jia-moonbit.join_strings([], "、"), "")
  assert_true(!@sai-chang-guan-jia-moonbit.contains_string([], "x"))
}

///|
test "exactly two collision dates" {
  let dates = @sai-chang-guan-jia-moonbit.collision_dates(
    @sai-chang-guan-jia-moonbit.all_competitions(),
  )
  assert_eq(dates.length(), 2)
  assert_true(@sai-chang-guan-jia-moonbit.contains_string(dates, "2026-12-01"))
  assert_true(@sai-chang-guan-jia-moonbit.contains_string(dates, "2026-12-06"))
}

///|
test "pack xiaodianjie to moda is blocked" {
  match @sai-chang-guan-jia-moonbit.work_by_name("小店日结") {
    Some(w) =>
      match
        @sai-chang-guan-jia-moonbit.competition_by_name(
          "魔搭 AI+∞ 第三期「AI 造游戏」",
        ) {
        Some(comp) => {
          let conflicts = @sai-chang-guan-jia-moonbit.detect_conflicts(
            w,
            @sai-chang-guan-jia-moonbit.all_competitions(),
          )
          let pack = @sai-chang-guan-jia-moonbit.generate_pack(
            w, comp, conflicts,
          )
          assert_true(pack.blocked)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "benchmark sweep counts" {
  // 全量扫描的计数与 benchmark 子命令打印的数字一致：
  // 3 作品 × 12 比赛，冲突 4 个（P0 3 个，P1 1 个），投稿包 36 个，
  // 其中 P0 挡住 3 个，撞期 2 个日期。
  let comps = @sai-chang-guan-jia-moonbit.all_competitions()
  let works = @sai-chang-guan-jia-moonbit.all_works()
  let mut total_conflicts = 0
  let mut p0 = 0
  let mut p1 = 0
  let mut total_packs = 0
  let mut blocked_packs = 0
  for wi in 0..<works.length() {
    let w = works[wi]
    let conflicts = @sai-chang-guan-jia-moonbit.detect_conflicts(w, comps)
    total_conflicts = total_conflicts + conflicts.length()
    for i in 0..<conflicts.length() {
      if conflicts[i].level == "P0" {
        p0 = p0 + 1
      } else {
        p1 = p1 + 1
      }
    }
    for ci in 0..<comps.length() {
      let pack = @sai-chang-guan-jia-moonbit.generate_pack(
        w,
        comps[ci],
        conflicts,
      )
      total_packs = total_packs + 1
      if pack.blocked {
        blocked_packs = blocked_packs + 1
      }
    }
  }
  assert_eq(total_conflicts, 4)
  assert_eq(p0, 3)
  assert_eq(p1, 1)
  assert_eq(total_packs, 36)
  assert_eq(blocked_packs, 3)
  assert_eq(@sai-chang-guan-jia-moonbit.collision_dates(comps).length(), 2)
}

///|
test "validate real data passes" {
  let issues = @sai-chang-guan-jia-moonbit.validate_data(
    @sai-chang-guan-jia-moonbit.all_competitions(),
    @sai-chang-guan-jia-moonbit.all_works(),
  )
  assert_eq(issues.length(), 0)
}

///|
test "is_valid_date accepts and rejects" {
  assert_true(@sai-chang-guan-jia-moonbit.is_valid_date("2026-12-01"))
  assert_true(@sai-chang-guan-jia-moonbit.is_valid_date("2027-01-28"))
  assert_true(!@sai-chang-guan-jia-moonbit.is_valid_date("2026-13-01"))
  assert_true(!@sai-chang-guan-jia-moonbit.is_valid_date("2026-12-32"))
  assert_true(!@sai-chang-guan-jia-moonbit.is_valid_date("2026/12/01"))
  assert_true(!@sai-chang-guan-jia-moonbit.is_valid_date("2026-12-1"))
  assert_true(!@sai-chang-guan-jia-moonbit.is_valid_date(""))
  assert_true(!@sai-chang-guan-jia-moonbit.is_valid_date("2026-00-10"))
  assert_true(!@sai-chang-guan-jia-moonbit.is_valid_date("2026-12-00"))
}

///|
/// 测试用的比赛夹具：除指定字段外均为合法值。
fn test_competition(
  name : String,
  deadline_date : String,
  allows_existing_works : Bool,
  requires_first_publish : Bool,
  requires_new_work : Bool,
  materials : Array[String],
  verified_at : String,
  plan_status : String,
  requires_no_prior_entry : Bool,
) -> @sai-chang-guan-jia-moonbit.Competition {
  {
    name,
    deadline: "2026-12-01",
    deadline_date,
    verified_at,
    prize: "¥0",
    track: "测试",
    status: "测试",
    plan_status,
    requires_first_publish,
    requires_new_work,
    requires_no_prior_entry,
    allows_existing_works,
    materials,
    note: "",
  }
}

///|
test "validate flags bad date" {
  let bad = test_competition(
    "测试比赛",
    "2026-13-40",
    false,
    false,
    false,
    ["材料 A"],
    "2026-11-13",
    "在途",
    false,
  )
  let issues = @sai-chang-guan-jia-moonbit.validate_data(
    [bad],
    @sai-chang-guan-jia-moonbit.all_works(),
  )
  assert_eq(issues.length(), 1)
}

///|
test "validate flags duplicate competition names" {
  let a = test_competition(
    "测试比赛",
    "2026-12-01",
    false,
    false,
    false,
    ["材料 A"],
    "2026-11-13",
    "在途",
    false,
  )
  let b = test_competition(
    "测试比赛",
    "2026-12-02",
    false,
    false,
    false,
    ["材料 A"],
    "2026-11-13",
    "在途",
    false,
  )
  let issues = @sai-chang-guan-jia-moonbit.validate_data(
    [a, b],
    @sai-chang-guan-jia-moonbit.all_works(),
  )
  assert_eq(issues.length(), 1)
}

///|
test "validate flags empty materials" {
  let empty = test_competition(
    "测试比赛",
    "2026-12-01",
    false,
    false,
    false,
    [],
    "2026-11-13",
    "在途",
    false,
  )
  let issues = @sai-chang-guan-jia-moonbit.validate_data(
    [empty],
    @sai-chang-guan-jia-moonbit.all_works(),
  )
  assert_eq(issues.length(), 1)
}

///|
test "validate flags contradictory flags" {
  let c1 = test_competition(
    "测试比赛 A",
    "2026-12-01",
    true,
    true,
    false,
    ["材料 A"],
    "2026-11-13",
    "在途",
    false,
  )
  let c2 = test_competition(
    "测试比赛 B",
    "2026-12-01",
    true,
    false,
    true,
    ["材料 A"],
    "2026-11-13",
    "在途",
    false,
  )
  let issues = @sai-chang-guan-jia-moonbit.validate_data(
    [c1, c2],
    @sai-chang-guan-jia-moonbit.all_works(),
  )
  assert_eq(issues.length(), 2)
}

///|
test "validate flags unnamed and duplicate works" {
  let base = @sai-chang-guan-jia-moonbit.all_works()[0]
  let unnamed : @sai-chang-guan-jia-moonbit.Work = {
    name: "",
    kind: base.kind,
    oneliner: base.oneliner,
    first_public_date: base.first_public_date,
    submitted_to: base.submitted_to,
    materials_ready: base.materials_ready,
    note: base.note,
  }
  let issues1 = @sai-chang-guan-jia-moonbit.validate_data([], [unnamed])
  assert_eq(issues1.length(), 1)
  let issues2 = @sai-chang-guan-jia-moonbit.validate_data([], [base, base])
  assert_eq(issues2.length(), 1)
}

///|
test "p0 message has no empty parens for xiaodianjie" {
  // 回归测试：2648796 修过的 bug——小店日结从未公开，
  // P0 文案曾显示“已公开（）”。保证不再复发。
  match @sai-chang-guan-jia-moonbit.work_by_name("小店日结") {
    Some(w) => {
      let conflicts = @sai-chang-guan-jia-moonbit.detect_conflicts(
        w,
        @sai-chang-guan-jia-moonbit.all_competitions(),
      )
      assert_eq(conflicts.length(), 1)
      assert_true(!conflicts[0].message.contains("（）"))
      assert_true(conflicts[0].message.contains("已投 涌现奖"))
    }
    None => assert_true(false)
  }
}

///|
test "validate flags unnamed competition" {
  let unnamed = test_competition(
    "",
    "2026-12-01",
    false,
    false,
    false,
    ["材料 A"],
    "2026-11-13",
    "在途",
    false,
  )
  let issues = @sai-chang-guan-jia-moonbit.validate_data(
    [unnamed],
    @sai-chang-guan-jia-moonbit.all_works(),
  )
  assert_eq(issues.length(), 1)
}

///|
test "is_valid_date rejects non-digit in date" {
  // '-' 位置正确但混入非数字：覆盖 is_valid_date 里的逐字符检查分支。
  assert_true(!@sai-chang-guan-jia-moonbit.is_valid_date("2026-1X-01"))
  assert_true(!@sai-chang-guan-jia-moonbit.is_valid_date("202X-12-01"))
}

///|
test "verified_at is valid for all competitions" {
  // 台账每行都有最后核实日期：10 行是 2026-11-13 全量核实轮次，
  // 2 行是 2026-11-15 同步脚本重核过的（绿联、PAYATHON）。
  let comps = @sai-chang-guan-jia-moonbit.all_competitions()
  let mut count_1113 = 0
  let mut count_1115 = 0
  for i in 0..<comps.length() {
    let v = comps[i].verified_at
    assert_true(@sai-chang-guan-jia-moonbit.is_valid_date(v))
    if v == "2026-11-13" {
      count_1113 = count_1113 + 1
    } else if v == "2026-11-15" {
      count_1115 = count_1115 + 1
    }
  }
  assert_eq(count_1113, 10)
  assert_eq(count_1115, 2)
}

///|
test "validate flags bad verified_at" {
  let bad = test_competition(
    "测试比赛",
    "2026-12-01",
    false,
    false,
    false,
    ["材料 A"],
    "2026-13-01",
    "在途",
    false,
  )
  let issues = @sai-chang-guan-jia-moonbit.validate_data(
    [bad],
    @sai-chang-guan-jia-moonbit.all_works(),
  )
  assert_eq(issues.length(), 1)
}

///|
test "plan status counts" {
  // 本轮只加了字段、还没加新比赛：12 行全是在途，关注 0 行。
  // 加 7 个关注比赛后改成 12 / 7。
  let comps = @sai-chang-guan-jia-moonbit.all_competitions()
  let mut in_plan = 0
  let mut watching = 0
  for i in 0..<comps.length() {
    if comps[i].plan_status == "在途" {
      in_plan = in_plan + 1
    } else if comps[i].plan_status == "关注" {
      watching = watching + 1
    }
  }
  assert_eq(in_plan, 12)
  assert_eq(watching, 0)
}

///|
test "validate flags bad plan_status" {
  let bad = test_competition(
    "测试比赛",
    "2026-12-01",
    false,
    false,
    false,
    ["材料 A"],
    "2026-11-13",
    "未知",
    false,
  )
  let issues = @sai-chang-guan-jia-moonbit.validate_data(
    [bad],
    @sai-chang-guan-jia-moonbit.all_works(),
  )
  assert_eq(issues.length(), 1)
}

///|
test "validate flags contradictory no-prior-entry flag" {
  let bad = test_competition(
    "测试比赛",
    "2026-12-01",
    true,
    false,
    false,
    ["材料 A"],
    "2026-11-13",
    "在途",
    true,
  )
  let issues = @sai-chang-guan-jia-moonbit.validate_data(
    [bad],
    @sai-chang-guan-jia-moonbit.all_works(),
  )
  assert_eq(issues.length(), 1)
}

///|
test "no-prior-entry rule fires on submitted_to only" {
  // 规则 3（原创条款）只看 submitted_to，不看 first_public_date：
  // 小店日结从未公开但已投涌现奖，应报 P0；
  // 一件只公开、没投过任何比赛的作品，不应报。
  let comp = test_competition(
    "测试原创条款赛",
    "2026-12-01",
    false,
    false,
    false,
    ["材料 A"],
    "2026-11-15",
    "关注",
    true,
  )
  match @sai-chang-guan-jia-moonbit.work_by_name("小店日结") {
    Some(w) => {
      let conflicts = @sai-chang-guan-jia-moonbit.detect_conflicts(w, [comp])
      assert_eq(conflicts.length(), 1)
      assert_eq(conflicts[0].level, "P0")
      assert_true(
        conflicts[0].message.contains("未参加过其他国家级公开比赛"),
      )
    }
    None => assert_true(false)
  }
  // WorkKind 构造子不对黑盒测试开放，从已有作品借 kind（与现有测试同款做法）。
  let base = @sai-chang-guan-jia-moonbit.all_works()[0]
  let only_public : @sai-chang-guan-jia-moonbit.Work = {
    name: "只公开未投过",
    kind: base.kind,
    oneliner: "测试用作品",
    first_public_date: "2026-11-01",
    submitted_to: [],
    materials_ready: [],
    note: "",
  }
  let conflicts2 = @sai-chang-guan-jia-moonbit.detect_conflicts(only_public, [
    comp,
  ])
  assert_eq(conflicts2.length(), 0)
}
