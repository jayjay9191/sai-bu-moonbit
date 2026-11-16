///|
/// 由 scripts/generate_tests.py 生成，不要手改。
/// 期望值来自 docs/manual-baseline-2026-11-15.md（人工手核底稿），
/// 76 格逐格断言：每格的冲突等级 + 投稿包 blocked 状态；
/// 另有 19 行逐行断言（截止/计划状态/核验日期/标志位）
/// 与 4 件作品断言（首次公开/已投比赛）。
/// 改期望先改底稿，再跑：python3 scripts/generate_tests.py

///|
test "cell: 第零次黎明 × AI PLAY 72H 创作黑客松" {
  match @sai-bu-moonbit.work_by_name("第零次黎明") {
    Some(w) =>
      match @sai-bu-moonbit.competition_by_name("AI PLAY 72H 创作黑客松") {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "AI PLAY 72H 创作黑客松",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 第零次黎明 × BayHack 大湾区黑客松" {
  match @sai-bu-moonbit.work_by_name("第零次黎明") {
    Some(w) =>
      match @sai-bu-moonbit.competition_by_name("BayHack 大湾区黑客松") {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "BayHack 大湾区黑客松",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 第零次黎明 × 荣耀·英特尔 AI 智造创新赛" {
  match @sai-bu-moonbit.work_by_name("第零次黎明") {
    Some(w) =>
      match
        @sai-bu-moonbit.competition_by_name(
          "荣耀·英特尔 AI 智造创新赛",
        ) {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "荣耀·英特尔 AI 智造创新赛",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 第零次黎明 × 华为小红书 Skill 创新赛" {
  match @sai-bu-moonbit.work_by_name("第零次黎明") {
    Some(w) =>
      match
        @sai-bu-moonbit.competition_by_name("华为小红书 Skill 创新赛") {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "华为小红书 Skill 创新赛",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 第零次黎明 × DoBe 全球 AI 创客大赛" {
  match @sai-bu-moonbit.work_by_name("第零次黎明") {
    Some(w) =>
      match @sai-bu-moonbit.competition_by_name("DoBe 全球 AI 创客大赛") {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "DoBe 全球 AI 创客大赛",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 第零次黎明 × 兴智杯" {
  match @sai-bu-moonbit.work_by_name("第零次黎明") {
    Some(w) =>
      match @sai-bu-moonbit.competition_by_name("兴智杯") {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "兴智杯",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 第零次黎明 × Qoder 高校创造力大赛" {
  match @sai-bu-moonbit.work_by_name("第零次黎明") {
    Some(w) =>
      match @sai-bu-moonbit.competition_by_name("Qoder 高校创造力大赛") {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "Qoder 高校创造力大赛",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 第零次黎明 × 第二届 AIGC 青年大学生就业创业促进行动" {
  match @sai-bu-moonbit.work_by_name("第零次黎明") {
    Some(w) =>
      match
        @sai-bu-moonbit.competition_by_name(
          "第二届 AIGC 青年大学生就业创业促进行动",
        ) {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "第二届 AIGC 青年大学生就业创业促进行动",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 第零次黎明 × 第十一届全国青年人工智能创新创业大赛" {
  match @sai-bu-moonbit.work_by_name("第零次黎明") {
    Some(w) =>
      match
        @sai-bu-moonbit.competition_by_name(
          "第十一届全国青年人工智能创新创业大赛",
        ) {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "第十一届全国青年人工智能创新创业大赛",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 第零次黎明 × 魔搭 AI+∞ 第三期「AI 造游戏」" {
  match @sai-bu-moonbit.work_by_name("第零次黎明") {
    Some(w) =>
      match
        @sai-bu-moonbit.competition_by_name(
          "魔搭 AI+∞ 第三期「AI 造游戏」",
        ) {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "魔搭 AI+∞ 第三期「AI 造游戏」",
          )
          assert_eq(list.length(), 1)
          assert_eq(list[0].level, "P0")
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, true)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 第零次黎明 × PAYATHON 2026" {
  match @sai-bu-moonbit.work_by_name("第零次黎明") {
    Some(w) =>
      match @sai-bu-moonbit.competition_by_name("PAYATHON 2026") {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "PAYATHON 2026",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 第零次黎明 × 知乎黑客松 S3" {
  match @sai-bu-moonbit.work_by_name("第零次黎明") {
    Some(w) =>
      match @sai-bu-moonbit.competition_by_name("知乎黑客松 S3") {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "知乎黑客松 S3",
          )
          assert_eq(list.length(), 1)
          assert_eq(list[0].level, "P1")
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 第零次黎明 × 松江·创世纪 AI 游戏大赛" {
  match @sai-bu-moonbit.work_by_name("第零次黎明") {
    Some(w) =>
      match
        @sai-bu-moonbit.competition_by_name("松江·创世纪 AI 游戏大赛") {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "松江·创世纪 AI 游戏大赛",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 第零次黎明 × 支付宝智能体涌现奖" {
  match @sai-bu-moonbit.work_by_name("第零次黎明") {
    Some(w) =>
      match @sai-bu-moonbit.competition_by_name("支付宝智能体涌现奖") {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "支付宝智能体涌现奖",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 第零次黎明 × 绿联首届黑客松" {
  match @sai-bu-moonbit.work_by_name("第零次黎明") {
    Some(w) =>
      match @sai-bu-moonbit.competition_by_name("绿联首届黑客松") {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "绿联首届黑客松",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 第零次黎明 × 中小企业 AI 应用产品大赛" {
  match @sai-bu-moonbit.work_by_name("第零次黎明") {
    Some(w) =>
      match
        @sai-bu-moonbit.competition_by_name(
          "中小企业 AI 应用产品大赛",
        ) {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "中小企业 AI 应用产品大赛",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 第零次黎明 × 造化首届体素游戏创作大赛" {
  match @sai-bu-moonbit.work_by_name("第零次黎明") {
    Some(w) =>
      match
        @sai-bu-moonbit.competition_by_name(
          "造化首届体素游戏创作大赛",
        ) {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "造化首届体素游戏创作大赛",
          )
          assert_eq(list.length(), 1)
          assert_eq(list[0].level, "P1")
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 第零次黎明 × 第二十届全国大学生软件创新大赛" {
  match @sai-bu-moonbit.work_by_name("第零次黎明") {
    Some(w) =>
      match
        @sai-bu-moonbit.competition_by_name(
          "第二十届全国大学生软件创新大赛",
        ) {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "第二十届全国大学生软件创新大赛",
          )
          assert_eq(list.length(), 1)
          assert_eq(list[0].level, "P0")
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, true)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 第零次黎明 × Rokid Spatial Joy 2026" {
  match @sai-bu-moonbit.work_by_name("第零次黎明") {
    Some(w) =>
      match @sai-bu-moonbit.competition_by_name("Rokid Spatial Joy 2026") {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "Rokid Spatial Joy 2026",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 小店日结 × AI PLAY 72H 创作黑客松" {
  match @sai-bu-moonbit.work_by_name("小店日结") {
    Some(w) =>
      match @sai-bu-moonbit.competition_by_name("AI PLAY 72H 创作黑客松") {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "AI PLAY 72H 创作黑客松",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 小店日结 × BayHack 大湾区黑客松" {
  match @sai-bu-moonbit.work_by_name("小店日结") {
    Some(w) =>
      match @sai-bu-moonbit.competition_by_name("BayHack 大湾区黑客松") {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "BayHack 大湾区黑客松",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 小店日结 × 荣耀·英特尔 AI 智造创新赛" {
  match @sai-bu-moonbit.work_by_name("小店日结") {
    Some(w) =>
      match
        @sai-bu-moonbit.competition_by_name(
          "荣耀·英特尔 AI 智造创新赛",
        ) {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "荣耀·英特尔 AI 智造创新赛",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 小店日结 × 华为小红书 Skill 创新赛" {
  match @sai-bu-moonbit.work_by_name("小店日结") {
    Some(w) =>
      match
        @sai-bu-moonbit.competition_by_name("华为小红书 Skill 创新赛") {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "华为小红书 Skill 创新赛",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 小店日结 × DoBe 全球 AI 创客大赛" {
  match @sai-bu-moonbit.work_by_name("小店日结") {
    Some(w) =>
      match @sai-bu-moonbit.competition_by_name("DoBe 全球 AI 创客大赛") {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "DoBe 全球 AI 创客大赛",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 小店日结 × 兴智杯" {
  match @sai-bu-moonbit.work_by_name("小店日结") {
    Some(w) =>
      match @sai-bu-moonbit.competition_by_name("兴智杯") {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "兴智杯",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 小店日结 × Qoder 高校创造力大赛" {
  match @sai-bu-moonbit.work_by_name("小店日结") {
    Some(w) =>
      match @sai-bu-moonbit.competition_by_name("Qoder 高校创造力大赛") {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "Qoder 高校创造力大赛",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 小店日结 × 第二届 AIGC 青年大学生就业创业促进行动" {
  match @sai-bu-moonbit.work_by_name("小店日结") {
    Some(w) =>
      match
        @sai-bu-moonbit.competition_by_name(
          "第二届 AIGC 青年大学生就业创业促进行动",
        ) {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "第二届 AIGC 青年大学生就业创业促进行动",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 小店日结 × 第十一届全国青年人工智能创新创业大赛" {
  match @sai-bu-moonbit.work_by_name("小店日结") {
    Some(w) =>
      match
        @sai-bu-moonbit.competition_by_name(
          "第十一届全国青年人工智能创新创业大赛",
        ) {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "第十一届全国青年人工智能创新创业大赛",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 小店日结 × 魔搭 AI+∞ 第三期「AI 造游戏」" {
  match @sai-bu-moonbit.work_by_name("小店日结") {
    Some(w) =>
      match
        @sai-bu-moonbit.competition_by_name(
          "魔搭 AI+∞ 第三期「AI 造游戏」",
        ) {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "魔搭 AI+∞ 第三期「AI 造游戏」",
          )
          assert_eq(list.length(), 1)
          assert_eq(list[0].level, "P0")
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, true)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 小店日结 × PAYATHON 2026" {
  match @sai-bu-moonbit.work_by_name("小店日结") {
    Some(w) =>
      match @sai-bu-moonbit.competition_by_name("PAYATHON 2026") {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "PAYATHON 2026",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 小店日结 × 知乎黑客松 S3" {
  match @sai-bu-moonbit.work_by_name("小店日结") {
    Some(w) =>
      match @sai-bu-moonbit.competition_by_name("知乎黑客松 S3") {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "知乎黑客松 S3",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 小店日结 × 松江·创世纪 AI 游戏大赛" {
  match @sai-bu-moonbit.work_by_name("小店日结") {
    Some(w) =>
      match
        @sai-bu-moonbit.competition_by_name("松江·创世纪 AI 游戏大赛") {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "松江·创世纪 AI 游戏大赛",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 小店日结 × 支付宝智能体涌现奖" {
  match @sai-bu-moonbit.work_by_name("小店日结") {
    Some(w) =>
      match @sai-bu-moonbit.competition_by_name("支付宝智能体涌现奖") {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "支付宝智能体涌现奖",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 小店日结 × 绿联首届黑客松" {
  match @sai-bu-moonbit.work_by_name("小店日结") {
    Some(w) =>
      match @sai-bu-moonbit.competition_by_name("绿联首届黑客松") {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "绿联首届黑客松",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 小店日结 × 中小企业 AI 应用产品大赛" {
  match @sai-bu-moonbit.work_by_name("小店日结") {
    Some(w) =>
      match
        @sai-bu-moonbit.competition_by_name(
          "中小企业 AI 应用产品大赛",
        ) {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "中小企业 AI 应用产品大赛",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 小店日结 × 造化首届体素游戏创作大赛" {
  match @sai-bu-moonbit.work_by_name("小店日结") {
    Some(w) =>
      match
        @sai-bu-moonbit.competition_by_name(
          "造化首届体素游戏创作大赛",
        ) {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "造化首届体素游戏创作大赛",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 小店日结 × 第二十届全国大学生软件创新大赛" {
  match @sai-bu-moonbit.work_by_name("小店日结") {
    Some(w) =>
      match
        @sai-bu-moonbit.competition_by_name(
          "第二十届全国大学生软件创新大赛",
        ) {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "第二十届全国大学生软件创新大赛",
          )
          assert_eq(list.length(), 1)
          assert_eq(list[0].level, "P0")
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, true)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 小店日结 × Rokid Spatial Joy 2026" {
  match @sai-bu-moonbit.work_by_name("小店日结") {
    Some(w) =>
      match @sai-bu-moonbit.competition_by_name("Rokid Spatial Joy 2026") {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "Rokid Spatial Joy 2026",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 诉求整理台 × AI PLAY 72H 创作黑客松" {
  match @sai-bu-moonbit.work_by_name("诉求整理台") {
    Some(w) =>
      match @sai-bu-moonbit.competition_by_name("AI PLAY 72H 创作黑客松") {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "AI PLAY 72H 创作黑客松",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 诉求整理台 × BayHack 大湾区黑客松" {
  match @sai-bu-moonbit.work_by_name("诉求整理台") {
    Some(w) =>
      match @sai-bu-moonbit.competition_by_name("BayHack 大湾区黑客松") {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "BayHack 大湾区黑客松",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 诉求整理台 × 荣耀·英特尔 AI 智造创新赛" {
  match @sai-bu-moonbit.work_by_name("诉求整理台") {
    Some(w) =>
      match
        @sai-bu-moonbit.competition_by_name(
          "荣耀·英特尔 AI 智造创新赛",
        ) {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "荣耀·英特尔 AI 智造创新赛",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 诉求整理台 × 华为小红书 Skill 创新赛" {
  match @sai-bu-moonbit.work_by_name("诉求整理台") {
    Some(w) =>
      match
        @sai-bu-moonbit.competition_by_name("华为小红书 Skill 创新赛") {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "华为小红书 Skill 创新赛",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 诉求整理台 × DoBe 全球 AI 创客大赛" {
  match @sai-bu-moonbit.work_by_name("诉求整理台") {
    Some(w) =>
      match @sai-bu-moonbit.competition_by_name("DoBe 全球 AI 创客大赛") {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "DoBe 全球 AI 创客大赛",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 诉求整理台 × 兴智杯" {
  match @sai-bu-moonbit.work_by_name("诉求整理台") {
    Some(w) =>
      match @sai-bu-moonbit.competition_by_name("兴智杯") {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "兴智杯",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 诉求整理台 × Qoder 高校创造力大赛" {
  match @sai-bu-moonbit.work_by_name("诉求整理台") {
    Some(w) =>
      match @sai-bu-moonbit.competition_by_name("Qoder 高校创造力大赛") {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "Qoder 高校创造力大赛",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 诉求整理台 × 第二届 AIGC 青年大学生就业创业促进行动" {
  match @sai-bu-moonbit.work_by_name("诉求整理台") {
    Some(w) =>
      match
        @sai-bu-moonbit.competition_by_name(
          "第二届 AIGC 青年大学生就业创业促进行动",
        ) {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "第二届 AIGC 青年大学生就业创业促进行动",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 诉求整理台 × 第十一届全国青年人工智能创新创业大赛" {
  match @sai-bu-moonbit.work_by_name("诉求整理台") {
    Some(w) =>
      match
        @sai-bu-moonbit.competition_by_name(
          "第十一届全国青年人工智能创新创业大赛",
        ) {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "第十一届全国青年人工智能创新创业大赛",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 诉求整理台 × 魔搭 AI+∞ 第三期「AI 造游戏」" {
  match @sai-bu-moonbit.work_by_name("诉求整理台") {
    Some(w) =>
      match
        @sai-bu-moonbit.competition_by_name(
          "魔搭 AI+∞ 第三期「AI 造游戏」",
        ) {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "魔搭 AI+∞ 第三期「AI 造游戏」",
          )
          assert_eq(list.length(), 1)
          assert_eq(list[0].level, "P0")
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, true)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 诉求整理台 × PAYATHON 2026" {
  match @sai-bu-moonbit.work_by_name("诉求整理台") {
    Some(w) =>
      match @sai-bu-moonbit.competition_by_name("PAYATHON 2026") {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "PAYATHON 2026",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 诉求整理台 × 知乎黑客松 S3" {
  match @sai-bu-moonbit.work_by_name("诉求整理台") {
    Some(w) =>
      match @sai-bu-moonbit.competition_by_name("知乎黑客松 S3") {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "知乎黑客松 S3",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 诉求整理台 × 松江·创世纪 AI 游戏大赛" {
  match @sai-bu-moonbit.work_by_name("诉求整理台") {
    Some(w) =>
      match
        @sai-bu-moonbit.competition_by_name("松江·创世纪 AI 游戏大赛") {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "松江·创世纪 AI 游戏大赛",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 诉求整理台 × 支付宝智能体涌现奖" {
  match @sai-bu-moonbit.work_by_name("诉求整理台") {
    Some(w) =>
      match @sai-bu-moonbit.competition_by_name("支付宝智能体涌现奖") {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "支付宝智能体涌现奖",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 诉求整理台 × 绿联首届黑客松" {
  match @sai-bu-moonbit.work_by_name("诉求整理台") {
    Some(w) =>
      match @sai-bu-moonbit.competition_by_name("绿联首届黑客松") {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "绿联首届黑客松",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 诉求整理台 × 中小企业 AI 应用产品大赛" {
  match @sai-bu-moonbit.work_by_name("诉求整理台") {
    Some(w) =>
      match
        @sai-bu-moonbit.competition_by_name(
          "中小企业 AI 应用产品大赛",
        ) {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "中小企业 AI 应用产品大赛",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 诉求整理台 × 造化首届体素游戏创作大赛" {
  match @sai-bu-moonbit.work_by_name("诉求整理台") {
    Some(w) =>
      match
        @sai-bu-moonbit.competition_by_name(
          "造化首届体素游戏创作大赛",
        ) {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "造化首届体素游戏创作大赛",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 诉求整理台 × 第二十届全国大学生软件创新大赛" {
  match @sai-bu-moonbit.work_by_name("诉求整理台") {
    Some(w) =>
      match
        @sai-bu-moonbit.competition_by_name(
          "第二十届全国大学生软件创新大赛",
        ) {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "第二十届全国大学生软件创新大赛",
          )
          assert_eq(list.length(), 1)
          assert_eq(list[0].level, "P0")
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, true)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 诉求整理台 × Rokid Spatial Joy 2026" {
  match @sai-bu-moonbit.work_by_name("诉求整理台") {
    Some(w) =>
      match @sai-bu-moonbit.competition_by_name("Rokid Spatial Joy 2026") {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "Rokid Spatial Joy 2026",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 验价尺 × AI PLAY 72H 创作黑客松" {
  match @sai-bu-moonbit.work_by_name("验价尺") {
    Some(w) =>
      match @sai-bu-moonbit.competition_by_name("AI PLAY 72H 创作黑客松") {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "AI PLAY 72H 创作黑客松",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 验价尺 × BayHack 大湾区黑客松" {
  match @sai-bu-moonbit.work_by_name("验价尺") {
    Some(w) =>
      match @sai-bu-moonbit.competition_by_name("BayHack 大湾区黑客松") {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "BayHack 大湾区黑客松",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 验价尺 × 荣耀·英特尔 AI 智造创新赛" {
  match @sai-bu-moonbit.work_by_name("验价尺") {
    Some(w) =>
      match
        @sai-bu-moonbit.competition_by_name(
          "荣耀·英特尔 AI 智造创新赛",
        ) {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "荣耀·英特尔 AI 智造创新赛",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 验价尺 × 华为小红书 Skill 创新赛" {
  match @sai-bu-moonbit.work_by_name("验价尺") {
    Some(w) =>
      match
        @sai-bu-moonbit.competition_by_name("华为小红书 Skill 创新赛") {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "华为小红书 Skill 创新赛",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 验价尺 × DoBe 全球 AI 创客大赛" {
  match @sai-bu-moonbit.work_by_name("验价尺") {
    Some(w) =>
      match @sai-bu-moonbit.competition_by_name("DoBe 全球 AI 创客大赛") {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "DoBe 全球 AI 创客大赛",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 验价尺 × 兴智杯" {
  match @sai-bu-moonbit.work_by_name("验价尺") {
    Some(w) =>
      match @sai-bu-moonbit.competition_by_name("兴智杯") {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "兴智杯",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 验价尺 × Qoder 高校创造力大赛" {
  match @sai-bu-moonbit.work_by_name("验价尺") {
    Some(w) =>
      match @sai-bu-moonbit.competition_by_name("Qoder 高校创造力大赛") {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "Qoder 高校创造力大赛",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 验价尺 × 第二届 AIGC 青年大学生就业创业促进行动" {
  match @sai-bu-moonbit.work_by_name("验价尺") {
    Some(w) =>
      match
        @sai-bu-moonbit.competition_by_name(
          "第二届 AIGC 青年大学生就业创业促进行动",
        ) {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "第二届 AIGC 青年大学生就业创业促进行动",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 验价尺 × 第十一届全国青年人工智能创新创业大赛" {
  match @sai-bu-moonbit.work_by_name("验价尺") {
    Some(w) =>
      match
        @sai-bu-moonbit.competition_by_name(
          "第十一届全国青年人工智能创新创业大赛",
        ) {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "第十一届全国青年人工智能创新创业大赛",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 验价尺 × 魔搭 AI+∞ 第三期「AI 造游戏」" {
  match @sai-bu-moonbit.work_by_name("验价尺") {
    Some(w) =>
      match
        @sai-bu-moonbit.competition_by_name(
          "魔搭 AI+∞ 第三期「AI 造游戏」",
        ) {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "魔搭 AI+∞ 第三期「AI 造游戏」",
          )
          assert_eq(list.length(), 1)
          assert_eq(list[0].level, "P0")
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, true)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 验价尺 × PAYATHON 2026" {
  match @sai-bu-moonbit.work_by_name("验价尺") {
    Some(w) =>
      match @sai-bu-moonbit.competition_by_name("PAYATHON 2026") {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "PAYATHON 2026",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 验价尺 × 知乎黑客松 S3" {
  match @sai-bu-moonbit.work_by_name("验价尺") {
    Some(w) =>
      match @sai-bu-moonbit.competition_by_name("知乎黑客松 S3") {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "知乎黑客松 S3",
          )
          assert_eq(list.length(), 1)
          assert_eq(list[0].level, "P1")
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 验价尺 × 松江·创世纪 AI 游戏大赛" {
  match @sai-bu-moonbit.work_by_name("验价尺") {
    Some(w) =>
      match
        @sai-bu-moonbit.competition_by_name("松江·创世纪 AI 游戏大赛") {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "松江·创世纪 AI 游戏大赛",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 验价尺 × 支付宝智能体涌现奖" {
  match @sai-bu-moonbit.work_by_name("验价尺") {
    Some(w) =>
      match @sai-bu-moonbit.competition_by_name("支付宝智能体涌现奖") {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "支付宝智能体涌现奖",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 验价尺 × 绿联首届黑客松" {
  match @sai-bu-moonbit.work_by_name("验价尺") {
    Some(w) =>
      match @sai-bu-moonbit.competition_by_name("绿联首届黑客松") {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "绿联首届黑客松",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 验价尺 × 中小企业 AI 应用产品大赛" {
  match @sai-bu-moonbit.work_by_name("验价尺") {
    Some(w) =>
      match
        @sai-bu-moonbit.competition_by_name(
          "中小企业 AI 应用产品大赛",
        ) {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "中小企业 AI 应用产品大赛",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 验价尺 × 造化首届体素游戏创作大赛" {
  match @sai-bu-moonbit.work_by_name("验价尺") {
    Some(w) =>
      match
        @sai-bu-moonbit.competition_by_name(
          "造化首届体素游戏创作大赛",
        ) {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "造化首届体素游戏创作大赛",
          )
          assert_eq(list.length(), 1)
          assert_eq(list[0].level, "P1")
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 验价尺 × 第二十届全国大学生软件创新大赛" {
  match @sai-bu-moonbit.work_by_name("验价尺") {
    Some(w) =>
      match
        @sai-bu-moonbit.competition_by_name(
          "第二十届全国大学生软件创新大赛",
        ) {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "第二十届全国大学生软件创新大赛",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "cell: 验价尺 × Rokid Spatial Joy 2026" {
  match @sai-bu-moonbit.work_by_name("验价尺") {
    Some(w) =>
      match @sai-bu-moonbit.competition_by_name("Rokid Spatial Joy 2026") {
        Some(c) => {
          let conflicts = @sai-bu-moonbit.detect_conflicts(
            w,
            @sai-bu-moonbit.all_competitions(),
          )
          let list = @sai-bu-moonbit.conflicts_for_competition(
            conflicts, "Rokid Spatial Joy 2026",
          )
          assert_eq(list.length(), 0)
          let pack = @sai-bu-moonbit.generate_pack(w, c, conflicts)
          assert_eq(pack.blocked, false)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "row: AI PLAY 72H 创作黑客松" {
  match @sai-bu-moonbit.competition_by_name("AI PLAY 72H 创作黑客松") {
    Some(c) => {
      assert_eq(c.deadline_date, "2026-11-17")
      assert_eq(c.plan_status, "在途")
      assert_eq(c.verified_at, "2026-11-13")
      assert_eq(c.requires_first_publish, false)
      assert_eq(c.requires_new_work, false)
      assert_eq(c.requires_no_prior_entry, false)
      assert_eq(c.allows_existing_works, true)
      assert_true(c.name != "")
      assert_true(c.deadline != "")
      assert_true(c.prize != "")
      assert_true(c.materials.length() > 0)
    }
    None => assert_true(false)
  }
}

///|
test "row: BayHack 大湾区黑客松" {
  match @sai-bu-moonbit.competition_by_name("BayHack 大湾区黑客松") {
    Some(c) => {
      assert_eq(c.deadline_date, "2026-11-18")
      assert_eq(c.plan_status, "在途")
      assert_eq(c.verified_at, "2026-11-13")
      assert_eq(c.requires_first_publish, false)
      assert_eq(c.requires_new_work, false)
      assert_eq(c.requires_no_prior_entry, false)
      assert_eq(c.allows_existing_works, false)
      assert_true(c.name != "")
      assert_true(c.deadline != "")
      assert_true(c.prize != "")
      assert_true(c.materials.length() > 0)
    }
    None => assert_true(false)
  }
}

///|
test "row: 荣耀·英特尔 AI 智造创新赛" {
  match
    @sai-bu-moonbit.competition_by_name("荣耀·英特尔 AI 智造创新赛") {
    Some(c) => {
      assert_eq(c.deadline_date, "2026-11-22")
      assert_eq(c.plan_status, "在途")
      assert_eq(c.verified_at, "2026-11-13")
      assert_eq(c.requires_first_publish, false)
      assert_eq(c.requires_new_work, false)
      assert_eq(c.requires_no_prior_entry, false)
      assert_eq(c.allows_existing_works, true)
      assert_true(c.name != "")
      assert_true(c.deadline != "")
      assert_true(c.prize != "")
      assert_true(c.materials.length() > 0)
    }
    None => assert_true(false)
  }
}

///|
test "row: 华为小红书 Skill 创新赛" {
  match @sai-bu-moonbit.competition_by_name("华为小红书 Skill 创新赛") {
    Some(c) => {
      assert_eq(c.deadline_date, "2026-11-24")
      assert_eq(c.plan_status, "在途")
      assert_eq(c.verified_at, "2026-11-13")
      assert_eq(c.requires_first_publish, false)
      assert_eq(c.requires_new_work, false)
      assert_eq(c.requires_no_prior_entry, false)
      assert_eq(c.allows_existing_works, true)
      assert_true(c.name != "")
      assert_true(c.deadline != "")
      assert_true(c.prize != "")
      assert_true(c.materials.length() > 0)
    }
    None => assert_true(false)
  }
}

///|
test "row: DoBe 全球 AI 创客大赛" {
  match @sai-bu-moonbit.competition_by_name("DoBe 全球 AI 创客大赛") {
    Some(c) => {
      assert_eq(c.deadline_date, "2026-11-27")
      assert_eq(c.plan_status, "关注")
      assert_eq(c.verified_at, "2026-11-15")
      assert_eq(c.requires_first_publish, false)
      assert_eq(c.requires_new_work, false)
      assert_eq(c.requires_no_prior_entry, false)
      assert_eq(c.allows_existing_works, false)
      assert_true(c.name != "")
      assert_true(c.deadline != "")
      assert_true(c.prize != "")
      assert_true(c.materials.length() > 0)
    }
    None => assert_true(false)
  }
}

///|
test "row: 兴智杯" {
  match @sai-bu-moonbit.competition_by_name("兴智杯") {
    Some(c) => {
      assert_eq(c.deadline_date, "2026-11-28")
      assert_eq(c.plan_status, "关注")
      assert_eq(c.verified_at, "2026-11-15")
      assert_eq(c.requires_first_publish, false)
      assert_eq(c.requires_new_work, false)
      assert_eq(c.requires_no_prior_entry, false)
      assert_eq(c.allows_existing_works, false)
      assert_true(c.name != "")
      assert_true(c.deadline != "")
      assert_true(c.prize != "")
      assert_true(c.materials.length() > 0)
    }
    None => assert_true(false)
  }
}

///|
test "row: Qoder 高校创造力大赛" {
  match @sai-bu-moonbit.competition_by_name("Qoder 高校创造力大赛") {
    Some(c) => {
      assert_eq(c.deadline_date, "2026-11-30")
      assert_eq(c.plan_status, "在途")
      assert_eq(c.verified_at, "2026-11-13")
      assert_eq(c.requires_first_publish, false)
      assert_eq(c.requires_new_work, false)
      assert_eq(c.requires_no_prior_entry, false)
      assert_eq(c.allows_existing_works, true)
      assert_true(c.name != "")
      assert_true(c.deadline != "")
      assert_true(c.prize != "")
      assert_true(c.materials.length() > 0)
    }
    None => assert_true(false)
  }
}

///|
test "row: 第二届 AIGC 青年大学生就业创业促进行动" {
  match
    @sai-bu-moonbit.competition_by_name(
      "第二届 AIGC 青年大学生就业创业促进行动",
    ) {
    Some(c) => {
      assert_eq(c.deadline_date, "2026-11-30")
      assert_eq(c.plan_status, "关注")
      assert_eq(c.verified_at, "2026-11-15")
      assert_eq(c.requires_first_publish, false)
      assert_eq(c.requires_new_work, false)
      assert_eq(c.requires_no_prior_entry, false)
      assert_eq(c.allows_existing_works, false)
      assert_true(c.name != "")
      assert_true(c.deadline != "")
      assert_true(c.prize != "")
      assert_true(c.materials.length() > 0)
    }
    None => assert_true(false)
  }
}

///|
test "row: 第十一届全国青年人工智能创新创业大赛" {
  match
    @sai-bu-moonbit.competition_by_name(
      "第十一届全国青年人工智能创新创业大赛",
    ) {
    Some(c) => {
      assert_eq(c.deadline_date, "2026-11-30")
      assert_eq(c.plan_status, "关注")
      assert_eq(c.verified_at, "2026-11-16")
      assert_eq(c.requires_first_publish, false)
      assert_eq(c.requires_new_work, false)
      assert_eq(c.requires_no_prior_entry, false)
      assert_eq(c.allows_existing_works, false)
      assert_true(c.name != "")
      assert_true(c.deadline != "")
      assert_true(c.prize != "")
      assert_true(c.materials.length() > 0)
    }
    None => assert_true(false)
  }
}

///|
test "row: 魔搭 AI+∞ 第三期「AI 造游戏」" {
  match
    @sai-bu-moonbit.competition_by_name(
      "魔搭 AI+∞ 第三期「AI 造游戏」",
    ) {
    Some(c) => {
      assert_eq(c.deadline_date, "2026-12-01")
      assert_eq(c.plan_status, "在途")
      assert_eq(c.verified_at, "2026-11-13")
      assert_eq(c.requires_first_publish, true)
      assert_eq(c.requires_new_work, false)
      assert_eq(c.requires_no_prior_entry, false)
      assert_eq(c.allows_existing_works, false)
      assert_true(c.name != "")
      assert_true(c.deadline != "")
      assert_true(c.prize != "")
      assert_true(c.materials.length() > 0)
    }
    None => assert_true(false)
  }
}

///|
test "row: PAYATHON 2026" {
  match @sai-bu-moonbit.competition_by_name("PAYATHON 2026") {
    Some(c) => {
      assert_eq(c.deadline_date, "2026-12-01")
      assert_eq(c.plan_status, "在途")
      assert_eq(c.verified_at, "2026-11-16")
      assert_eq(c.requires_first_publish, false)
      assert_eq(c.requires_new_work, false)
      assert_eq(c.requires_no_prior_entry, false)
      assert_eq(c.allows_existing_works, false)
      assert_true(c.name != "")
      assert_true(c.deadline != "")
      assert_true(c.prize != "")
      assert_true(c.materials.length() > 0)
    }
    None => assert_true(false)
  }
}

///|
test "row: 知乎黑客松 S3" {
  match @sai-bu-moonbit.competition_by_name("知乎黑客松 S3") {
    Some(c) => {
      assert_eq(c.deadline_date, "2026-12-04")
      assert_eq(c.plan_status, "在途")
      assert_eq(c.verified_at, "2026-11-13")
      assert_eq(c.requires_first_publish, false)
      assert_eq(c.requires_new_work, true)
      assert_eq(c.requires_no_prior_entry, false)
      assert_eq(c.allows_existing_works, false)
      assert_true(c.name != "")
      assert_true(c.deadline != "")
      assert_true(c.prize != "")
      assert_true(c.materials.length() > 0)
    }
    None => assert_true(false)
  }
}

///|
test "row: 松江·创世纪 AI 游戏大赛" {
  match
    @sai-bu-moonbit.competition_by_name("松江·创世纪 AI 游戏大赛") {
    Some(c) => {
      assert_eq(c.deadline_date, "2026-12-06")
      assert_eq(c.plan_status, "在途")
      assert_eq(c.verified_at, "2026-11-16")
      assert_eq(c.requires_first_publish, false)
      assert_eq(c.requires_new_work, false)
      assert_eq(c.requires_no_prior_entry, false)
      assert_eq(c.allows_existing_works, true)
      assert_true(c.name != "")
      assert_true(c.deadline != "")
      assert_true(c.prize != "")
      assert_true(c.materials.length() > 0)
    }
    None => assert_true(false)
  }
}

///|
test "row: 支付宝智能体涌现奖" {
  match @sai-bu-moonbit.competition_by_name("支付宝智能体涌现奖") {
    Some(c) => {
      assert_eq(c.deadline_date, "2026-12-06")
      assert_eq(c.plan_status, "在途")
      assert_eq(c.verified_at, "2026-11-16")
      assert_eq(c.requires_first_publish, false)
      assert_eq(c.requires_new_work, false)
      assert_eq(c.requires_no_prior_entry, false)
      assert_eq(c.allows_existing_works, true)
      assert_true(c.name != "")
      assert_true(c.deadline != "")
      assert_true(c.prize != "")
      assert_true(c.materials.length() > 0)
    }
    None => assert_true(false)
  }
}

///|
test "row: 绿联首届黑客松" {
  match @sai-bu-moonbit.competition_by_name("绿联首届黑客松") {
    Some(c) => {
      assert_eq(c.deadline_date, "2026-12-07")
      assert_eq(c.plan_status, "在途")
      assert_eq(c.verified_at, "2026-11-16")
      assert_eq(c.requires_first_publish, false)
      assert_eq(c.requires_new_work, false)
      assert_eq(c.requires_no_prior_entry, false)
      assert_eq(c.allows_existing_works, false)
      assert_true(c.name != "")
      assert_true(c.deadline != "")
      assert_true(c.prize != "")
      assert_true(c.materials.length() > 0)
    }
    None => assert_true(false)
  }
}

///|
test "row: 中小企业 AI 应用产品大赛" {
  match
    @sai-bu-moonbit.competition_by_name("中小企业 AI 应用产品大赛") {
    Some(c) => {
      assert_eq(c.deadline_date, "2026-12-10")
      assert_eq(c.plan_status, "关注")
      assert_eq(c.verified_at, "2026-11-15")
      assert_eq(c.requires_first_publish, false)
      assert_eq(c.requires_new_work, false)
      assert_eq(c.requires_no_prior_entry, false)
      assert_eq(c.allows_existing_works, false)
      assert_true(c.name != "")
      assert_true(c.deadline != "")
      assert_true(c.prize != "")
      assert_true(c.materials.length() > 0)
    }
    None => assert_true(false)
  }
}

///|
test "row: 造化首届体素游戏创作大赛" {
  match
    @sai-bu-moonbit.competition_by_name("造化首届体素游戏创作大赛") {
    Some(c) => {
      assert_eq(c.deadline_date, "2026-12-15")
      assert_eq(c.plan_status, "关注")
      assert_eq(c.verified_at, "2026-11-15")
      assert_eq(c.requires_first_publish, false)
      assert_eq(c.requires_new_work, true)
      assert_eq(c.requires_no_prior_entry, false)
      assert_eq(c.allows_existing_works, false)
      assert_true(c.name != "")
      assert_true(c.deadline != "")
      assert_true(c.prize != "")
      assert_true(c.materials.length() > 0)
    }
    None => assert_true(false)
  }
}

///|
test "row: 第二十届全国大学生软件创新大赛" {
  match
    @sai-bu-moonbit.competition_by_name(
      "第二十届全国大学生软件创新大赛",
    ) {
    Some(c) => {
      assert_eq(c.deadline_date, "2027-01-15")
      assert_eq(c.plan_status, "关注")
      assert_eq(c.verified_at, "2026-11-15")
      assert_eq(c.requires_first_publish, false)
      assert_eq(c.requires_new_work, false)
      assert_eq(c.requires_no_prior_entry, true)
      assert_eq(c.allows_existing_works, false)
      assert_true(c.name != "")
      assert_true(c.deadline != "")
      assert_true(c.prize != "")
      assert_true(c.materials.length() > 0)
    }
    None => assert_true(false)
  }
}

///|
test "row: Rokid Spatial Joy 2026" {
  match @sai-bu-moonbit.competition_by_name("Rokid Spatial Joy 2026") {
    Some(c) => {
      assert_eq(c.deadline_date, "2027-01-28")
      assert_eq(c.plan_status, "在途")
      assert_eq(c.verified_at, "2026-11-13")
      assert_eq(c.requires_first_publish, false)
      assert_eq(c.requires_new_work, false)
      assert_eq(c.requires_no_prior_entry, false)
      assert_eq(c.allows_existing_works, false)
      assert_true(c.name != "")
      assert_true(c.deadline != "")
      assert_true(c.prize != "")
      assert_true(c.materials.length() > 0)
    }
    None => assert_true(false)
  }
}

///|
test "work: 第零次黎明" {
  match @sai-bu-moonbit.work_by_name("第零次黎明") {
    Some(w) => {
      assert_eq(w.first_public_date, "2026-11-02 之前")
      assert_eq(w.submitted_to.length(), 2)
      assert_true(@sai-bu-moonbit.contains_string(w.submitted_to, "Qoder"))
      assert_true(@sai-bu-moonbit.contains_string(w.submitted_to, "AI PLAY"))
      assert_true(w.oneliner != "")
      assert_true(w.materials_ready.length() > 0)
    }
    None => assert_true(false)
  }
}

///|
test "work: 小店日结" {
  match @sai-bu-moonbit.work_by_name("小店日结") {
    Some(w) => {
      assert_eq(w.first_public_date, "")
      assert_eq(w.submitted_to.length(), 1)
      assert_true(@sai-bu-moonbit.contains_string(w.submitted_to, "涌现奖"))
      assert_true(w.oneliner != "")
      assert_true(w.materials_ready.length() > 0)
    }
    None => assert_true(false)
  }
}

///|
test "work: 诉求整理台" {
  match @sai-bu-moonbit.work_by_name("诉求整理台") {
    Some(w) => {
      assert_eq(w.first_public_date, "")
      assert_eq(w.submitted_to.length(), 1)
      assert_true(@sai-bu-moonbit.contains_string(w.submitted_to, "涌现奖"))
      assert_true(w.oneliner != "")
      assert_true(w.materials_ready.length() > 0)
    }
    None => assert_true(false)
  }
}

///|
test "work: 验价尺" {
  match @sai-bu-moonbit.work_by_name("验价尺") {
    Some(w) => {
      assert_eq(w.first_public_date, "2026-11-16")
      assert_eq(w.submitted_to.length(), 0)
      assert_true(w.oneliner != "")
      assert_true(w.materials_ready.length() > 0)
    }
    None => assert_true(false)
  }
}
