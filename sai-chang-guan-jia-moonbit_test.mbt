///|
/// 黑盒测试：只测公开 API 的行为，不测实现细节。
/// Run `moon test` to execute and `moon test --update` to refresh snapshots.

///|
test "registry has nineteen competitions" {
  assert_eq(@sai-chang-guan-jia-moonbit.all_competitions().length(), 19)
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
  // 另有软件创新大赛规则 3（原创条款）同样触发 P0，共 2 个冲突。
  match @sai-chang-guan-jia-moonbit.work_by_name("小店日结") {
    Some(w) => {
      let conflicts = @sai-chang-guan-jia-moonbit.detect_conflicts(
        w,
        @sai-chang-guan-jia-moonbit.all_competitions(),
      )
      assert_eq(conflicts.length(), 2)
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
test "exactly three collision dates" {
  let dates = @sai-chang-guan-jia-moonbit.collision_dates(
    @sai-chang-guan-jia-moonbit.all_competitions(),
  )
  assert_eq(dates.length(), 3)
  assert_true(@sai-chang-guan-jia-moonbit.contains_string(dates, "2026-11-30"))
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
  // 4 作品 × 19 比赛，冲突 11 个（P0 7 个，P1 4 个），投稿包 76 个，
  // 其中 P0 挡住 7 个，撞期 3 个日期。
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
  assert_eq(total_conflicts, 11)
  assert_eq(p0, 7)
  assert_eq(p1, 4)
  assert_eq(total_packs, 76)
  assert_eq(blocked_packs, 7)
  assert_eq(@sai-chang-guan-jia-moonbit.collision_dates(comps).length(), 3)
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
      assert_eq(conflicts.length(), 2)
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
  // 台账每行都有最后核实日期：8 行是 2026-11-13 全量核实轮次，
  // 6 行是 2026-11-15（7 个新关注比赛减去 CAAI 青年赛），
  // 5 行是 2026-11-16（同步脚本第三批自动更新：绿联、PAYATHON、
  // 松江、涌现奖、CAAI 青年赛核实通过）。
  let comps = @sai-chang-guan-jia-moonbit.all_competitions()
  let mut count_1113 = 0
  let mut count_1115 = 0
  let mut count_1116 = 0
  for i in 0..<comps.length() {
    let v = comps[i].verified_at
    assert_true(@sai-chang-guan-jia-moonbit.is_valid_date(v))
    if v == "2026-11-13" {
      count_1113 = count_1113 + 1
    } else if v == "2026-11-15" {
      count_1115 = count_1115 + 1
    } else if v == "2026-11-16" {
      count_1116 = count_1116 + 1
    }
  }
  assert_eq(count_1113, 8)
  assert_eq(count_1115, 6)
  assert_eq(count_1116, 5)
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
  // 12 行在途（原计划），7 行关注（本轮新增）。
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
  assert_eq(watching, 7)
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

///|
test "software innovation P0 for submitted works only" {
  // 软件创新大赛原创条款（规则 3）：只看 submitted_to，不看
  // first_public_date。已投过其他比赛的三件作品应报 P0；AI 工具
  // 定价核验只公开、未投过任何比赛，应为 0 个冲突——它是规则 3
  // 不读公开日期的直接证据。参赛管家本身已投 MoonBit，按此条款
  // 同样冲突（它不在作品表里，见该比赛的 note）。
  let comps = @sai-chang-guan-jia-moonbit.all_competitions()
  let works = @sai-chang-guan-jia-moonbit.all_works()
  for wi in 0..<works.length() {
    let conflicts = @sai-chang-guan-jia-moonbit.detect_conflicts(
      works[wi],
      comps,
    )
    let list = @sai-chang-guan-jia-moonbit.conflicts_for_competition(
      conflicts, "第二十届全国大学生软件创新大赛",
    )
    if works[wi].submitted_to.length() > 0 {
      assert_eq(list.length(), 1)
      assert_eq(list[0].level, "P0")
      assert_true(
        list[0].message.contains("未参加过其他国家级公开比赛"),
      )
    } else {
      assert_eq(list.length(), 0)
    }
  }
}

///|
test "zaohua requires new work P1 for dawn" {
  // 造化要求用天工引擎新做体素游戏，黎明已有公开版本，应报 P1。
  match @sai-chang-guan-jia-moonbit.work_by_name("第零次黎明") {
    Some(w) => {
      let conflicts = @sai-chang-guan-jia-moonbit.detect_conflicts(
        w,
        @sai-chang-guan-jia-moonbit.all_competitions(),
      )
      let list = @sai-chang-guan-jia-moonbit.conflicts_for_competition(
        conflicts, "造化首届体素游戏创作大赛",
      )
      assert_eq(list.length(), 1)
      assert_eq(list[0].level, "P1")
    }
    None => assert_true(false)
  }
}

///|
test "synthetic clean work has zero conflicts" {
  // 既没公开、也没投过任何比赛的作品：三条规则都不应触发。
  let base = @sai-chang-guan-jia-moonbit.all_works()[0]
  let clean : @sai-chang-guan-jia-moonbit.Work = {
    name: "干净的新作品",
    kind: base.kind,
    oneliner: "测试用作品",
    first_public_date: "",
    submitted_to: [],
    materials_ready: [],
    note: "",
  }
  let conflicts = @sai-chang-guan-jia-moonbit.detect_conflicts(
    clean,
    @sai-chang-guan-jia-moonbit.all_competitions(),
  )
  assert_eq(conflicts.length(), 0)
}

///|
test "public-only work hits three rules" {
  // 只公开、没投过任何比赛的作品：魔搭 P0（规则 1 公开分支），
  // 知乎 P1 + 造化 P1（规则 2）；规则 3 不触发（只看 submitted_to）。
  let base = @sai-chang-guan-jia-moonbit.all_works()[0]
  let pub_only : @sai-chang-guan-jia-moonbit.Work = {
    name: "只公开未投过",
    kind: base.kind,
    oneliner: "测试用作品",
    first_public_date: "2026-11-01",
    submitted_to: [],
    materials_ready: [],
    note: "",
  }
  let conflicts = @sai-chang-guan-jia-moonbit.detect_conflicts(
    pub_only,
    @sai-chang-guan-jia-moonbit.all_competitions(),
  )
  assert_eq(conflicts.length(), 3)
  assert_eq(
    conflicts[0].competition,
    "魔搭 AI+∞ 第三期「AI 造游戏」",
  )
  assert_eq(conflicts[0].level, "P0")
  assert_eq(conflicts[1].competition, "知乎黑客松 S3")
  assert_eq(conflicts[1].level, "P1")
  assert_eq(conflicts[2].competition, "造化首届体素游戏创作大赛")
  assert_eq(conflicts[2].level, "P1")
}

///|
test "pack dawn to zaohua gaps one not blocked" {
  // 造化是 P1 不是 P0，投稿包不 blocked，但材料缺 1 项（天工引擎新做游戏）。
  match @sai-chang-guan-jia-moonbit.work_by_name("第零次黎明") {
    Some(w) =>
      match
        @sai-chang-guan-jia-moonbit.competition_by_name(
          "造化首届体素游戏创作大赛",
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
          assert_eq(pack.gaps.length(), 1)
          assert_eq(pack.ready.length(), 0)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "pack dawn to software innovation is blocked" {
  match @sai-chang-guan-jia-moonbit.work_by_name("第零次黎明") {
    Some(w) =>
      match
        @sai-chang-guan-jia-moonbit.competition_by_name(
          "第二十届全国大学生软件创新大赛",
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
          assert_eq(pack.gaps.length(), 1)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "pack tools to software innovation are blocked" {
  // 两件工具都已投涌现奖，软件创新大赛原创条款 P0，投稿包挡住。
  for name in ["小店日结", "诉求整理台"] {
    match @sai-chang-guan-jia-moonbit.work_by_name(name) {
      Some(w) =>
        match
          @sai-chang-guan-jia-moonbit.competition_by_name(
            "第二十届全国大学生软件创新大赛",
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
}

///|
test "pack dawn to shifang has two gaps" {
  match @sai-chang-guan-jia-moonbit.work_by_name("第零次黎明") {
    Some(w) =>
      match
        @sai-chang-guan-jia-moonbit.competition_by_name(
          "第二届 AIGC 青年大学生就业创业促进行动",
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
          assert_eq(pack.materials.length(), 2)
          assert_eq(pack.gaps.length(), 2)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "pack title starts with work name in brackets" {
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
          assert_eq(
            pack.title,
            "[第零次黎明] Roguelike 动作构筑游戏：死亡重启、遗物抽取、R 键共鸣爆发",
          )
          assert_eq(pack.oneliner, w.oneliner)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "gapless pack note says ready to submit" {
  // 小店日结→涌现奖：材料齐全、无 P0，note 应为“材料齐全，可以提交”。
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
          assert_eq(pack.note, "材料齐全，可以提交")
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "nov thirty collision lists three names" {
  // 11-30 三赛撞期：Qoder、十方融海、CAAI 青年赛，缺一不可。
  let collisions = @sai-chang-guan-jia-moonbit.collision_conflicts(
    @sai-chang-guan-jia-moonbit.all_competitions(),
  )
  let mut found = false
  for i in 0..<collisions.length() {
    if collisions[i].message.contains("2026-11-30") {
      found = true
      assert_true(collisions[i].message.contains("Qoder 高校创造力大赛"))
      assert_true(
        collisions[i].message.contains(
          "第二届 AIGC 青年大学生就业创业促进行动",
        ),
      )
      assert_true(
        collisions[i].message.contains(
          "第十一届全国青年人工智能创新创业大赛",
        ),
      )
      assert_true(collisions[i].message.contains("共 3 个比赛撞期"))
    }
  }
  assert_true(found)
}

///|
test "collision helpers on custom fixtures" {
  // 两个比赛同一天 → 1 个撞期日期；三个同一天 → 还是 1 个日期；
  // 各自不同天 → 0 个。
  let a = test_competition(
    "测试 A",
    "2026-12-01",
    false,
    false,
    false,
    ["材料 A"],
    "2026-11-15",
    "在途",
    false,
  )
  let b = test_competition(
    "测试 B",
    "2026-12-01",
    false,
    false,
    false,
    ["材料 A"],
    "2026-11-15",
    "在途",
    false,
  )
  let c = test_competition(
    "测试 C",
    "2026-12-01",
    false,
    false,
    false,
    ["材料 A"],
    "2026-11-15",
    "在途",
    false,
  )
  let d = test_competition(
    "测试 D",
    "2026-12-02",
    false,
    false,
    false,
    ["材料 A"],
    "2026-11-15",
    "在途",
    false,
  )
  assert_eq(@sai-chang-guan-jia-moonbit.collision_dates([a, b]).length(), 1)
  assert_eq(@sai-chang-guan-jia-moonbit.collision_dates([a, b, c]).length(), 1)
  assert_eq(@sai-chang-guan-jia-moonbit.collision_dates([a, d]).length(), 0)
  assert_eq(@sai-chang-guan-jia-moonbit.collision_conflicts([a, b]).length(), 1)
}

///|
test "collision dates exclude single dates" {
  // 真实台账 19 个截止对应 15 个不同日期，其中 3 个撞期，其余 12 个日期各只有 1 个比赛。
  let dates = @sai-chang-guan-jia-moonbit.collision_dates(
    @sai-chang-guan-jia-moonbit.all_competitions(),
  )
  assert_true(!@sai-chang-guan-jia-moonbit.contains_string(dates, "2026-11-17"))
  assert_true(!@sai-chang-guan-jia-moonbit.contains_string(dates, "2026-12-15"))
  assert_true(!@sai-chang-guan-jia-moonbit.contains_string(dates, "2027-01-15"))
}

///|
test "is_valid_date feb 29 passes by design" {
  // is_valid_date 只校验格式（月 01–12、日 01–31），不校验每月实际天数；
  // 2026-02-29 通过是已知的设计取舍，写在 validate.mbt 的注释里。
  assert_true(@sai-chang-guan-jia-moonbit.is_valid_date("2026-02-29"))
  assert_true(@sai-chang-guan-jia-moonbit.is_valid_date("2026-02-31"))
}

///|
test "is_valid_date year boundaries" {
  assert_true(@sai-chang-guan-jia-moonbit.is_valid_date("2026-12-31"))
  assert_true(@sai-chang-guan-jia-moonbit.is_valid_date("2027-01-01"))
  assert_true(!@sai-chang-guan-jia-moonbit.is_valid_date("2026-12-31 "))
  assert_true(!@sai-chang-guan-jia-moonbit.is_valid_date(" 2026-12-31"))
}

///|
test "validate flags empty plan_status" {
  let bad = test_competition(
    "测试比赛",
    "2026-12-01",
    false,
    false,
    false,
    ["材料 A"],
    "2026-11-13",
    "",
    false,
  )
  let issues = @sai-chang-guan-jia-moonbit.validate_data(
    [bad],
    @sai-chang-guan-jia-moonbit.all_works(),
  )
  assert_eq(issues.length(), 1)
}

///|
test "join and contains on nonempty lists" {
  assert_eq(
    @sai-chang-guan-jia-moonbit.join_strings(["甲", "乙", "丙"], "、"),
    "甲、乙、丙",
  )
  assert_eq(@sai-chang-guan-jia-moonbit.join_strings(["甲"], "、"), "甲")
  assert_true(
    @sai-chang-guan-jia-moonbit.contains_string(["甲", "乙"], "乙"),
  )
  assert_true(
    !@sai-chang-guan-jia-moonbit.contains_string(["甲", "乙"], "丙"),
  )
}
