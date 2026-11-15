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
