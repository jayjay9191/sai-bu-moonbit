///|
/// 引用校验追踪的黑盒测试：只测公开 API 的行为。
/// 代表性案例全部用真实台账数据——《第零次黎明》→ 魔搭是 2026-11-18
/// 报名初审驳回时点名要的“从规则适用条件、来源证据到结论”的完整机制
/// 与代表性案例；验价尺 → 软件创新大赛是规则 3 只读 submitted_to
/// 的直接证据。Run `moon test` to execute.

///|
test "trace first publish P0 for dawn to moda" {
  // 《第零次黎明》11-02 前已公开且已投 Qoder / AI PLAY，
  // 魔搭要求活动期间首次发布，追踪必须报 P0，且每一步带证据：
  // 规则原文、Qoder 队号、天池/AI PLAY 的提交证据都要在。
  match @sai-bu-moonbit.work_by_name("第零次黎明") {
    Some(w) =>
      match
        @sai-bu-moonbit.competition_by_name(
          "魔搭 AI+∞ 第三期「AI 造游戏」",
        ) {
        Some(comp) => {
          let t = @sai-bu-moonbit.trace_first_publish(w, comp)
          assert_true(t.violated)
          assert_eq(t.level, "P0")
          assert_eq(t.conclusion, "P0 冲突：不得投稿")
          let text = @sai-bu-moonbit.render_trace(t)
          assert_true(text.contains("不得使用已参加其他比赛"))
          assert_true(text.contains("魔搭官网《参赛须知》第 1 条"))
          assert_true(text.contains("1390261"))
          assert_true(text.contains("Combos 分享页"))
          assert_true(text.contains("AI PLAY"))
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "trace first publish not applicable for dawn to songjiang" {
  // 松江明确已有成品可参赛，不要求首次发布，规则不适用。
  match @sai-bu-moonbit.work_by_name("第零次黎明") {
    Some(w) =>
      match
        @sai-bu-moonbit.competition_by_name("松江·创世纪 AI 游戏大赛") {
        Some(comp) => {
          let t = @sai-bu-moonbit.trace_first_publish(w, comp)
          assert_true(!t.violated)
          assert_eq(t.level, "通过")
          assert_true(@sai-bu-moonbit.render_trace(t).contains("不要求"))
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "trace first publish P0 via submitted only for xiaodianjie" {
  // 小店日结从未公开，但已投过涌现奖：规则 1 的已投分支单独触发 P0，
  // 追踪要写明公开分支不触发、已投分支触发，并带涌现奖的提交证据。
  match @sai-bu-moonbit.work_by_name("小店日结") {
    Some(w) =>
      match
        @sai-bu-moonbit.competition_by_name(
          "魔搭 AI+∞ 第三期「AI 造游戏」",
        ) {
        Some(comp) => {
          let t = @sai-bu-moonbit.trace_first_publish(w, comp)
          assert_true(t.violated)
          assert_eq(t.level, "P0")
          let text = @sai-bu-moonbit.render_trace(t)
          assert_true(text.contains("未公开"))
          assert_true(text.contains("涌现奖"))
          assert_true(text.contains("2026-11-13 提交"))
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "trace no prior entry P0 for dawn to software innovation" {
  // 软件创新大赛原创条款（规则 3）：黎明已投 Qoder / AI PLAY，应报 P0；
  // 追踪必须写明本规则只读 submitted_to，不读首次公开日期。
  match @sai-bu-moonbit.work_by_name("第零次黎明") {
    Some(w) =>
      match
        @sai-bu-moonbit.competition_by_name(
          "第二十届全国大学生软件创新大赛",
        ) {
        Some(comp) => {
          let t = @sai-bu-moonbit.trace_no_prior_entry(w, comp)
          assert_true(t.violated)
          assert_eq(t.level, "P0")
          let text = @sai-bu-moonbit.render_trace(t)
          assert_true(text.contains("只读 submitted_to"))
          assert_true(text.contains("未参加过其他国家级公开比赛"))
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "trace no prior entry passes for yan-jia-chi" {
  // 验价尺只公开、未投过任何比赛：规则 3 不触发——它是“只读
  // submitted_to、不读首次公开日期”的直接证据。
  match @sai-bu-moonbit.work_by_name("验价尺") {
    Some(w) =>
      match
        @sai-bu-moonbit.competition_by_name(
          "第二十届全国大学生软件创新大赛",
        ) {
        Some(comp) => {
          let t = @sai-bu-moonbit.trace_no_prior_entry(w, comp)
          assert_true(!t.violated)
          assert_eq(t.level, "通过")
          let text = @sai-bu-moonbit.render_trace(t)
          assert_true(text.contains("不读公开日期"))
          assert_true(text.contains("未投过其他比赛"))
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "trace new work P1 for dawn to zhihu" {
  // 知乎 S3 要求必须新做，黎明已有公开版本，应报 P1。
  match @sai-bu-moonbit.work_by_name("第零次黎明") {
    Some(w) =>
      match @sai-bu-moonbit.competition_by_name("知乎黑客松 S3") {
        Some(comp) => {
          let t = @sai-bu-moonbit.trace_new_work(w, comp)
          assert_true(t.violated)
          assert_eq(t.level, "P1")
          assert_true(
            @sai-bu-moonbit.render_trace(t).contains("48h 新做作品"),
          )
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "trace new work passes for clean work to zhihu" {
  // 既没公开、也没投过任何比赛的作品：须新做规则通过。
  let base = @sai-bu-moonbit.all_works()[0]
  let clean : @sai-bu-moonbit.Work = {
    name: "干净的新作品",
    kind: base.kind,
    oneliner: "测试用作品",
    first_public_date: "",
    submitted_to: [],
    materials_ready: [],
    note: "",
  }
  match @sai-bu-moonbit.competition_by_name("知乎黑客松 S3") {
    Some(comp) => {
      let t = @sai-bu-moonbit.trace_new_work(clean, comp)
      assert_true(!t.violated)
      assert_eq(t.level, "通过")
    }
    None => assert_true(false)
  }
}

///|
test "trace all rules dawn to moda has one P0" {
  // 魔搭只开规则 1 一个标志位，追踪应恰好 1 份，且为 P0。
  match @sai-bu-moonbit.work_by_name("第零次黎明") {
    Some(w) =>
      match
        @sai-bu-moonbit.competition_by_name(
          "魔搭 AI+∞ 第三期「AI 造游戏」",
        ) {
        Some(comp) => {
          let traces = @sai-bu-moonbit.trace_all_rules(w, comp)
          assert_eq(traces.length(), 1)
          assert_true(traces[0].violated)
          assert_eq(traces[0].level, "P0")
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "trace all rules dawn to songjiang has one pass" {
  // 松江三个标志位全关，追踪应恰好 1 份“无适用规则”，结论通过。
  match @sai-bu-moonbit.work_by_name("第零次黎明") {
    Some(w) =>
      match
        @sai-bu-moonbit.competition_by_name("松江·创世纪 AI 游戏大赛") {
        Some(comp) => {
          let traces = @sai-bu-moonbit.trace_all_rules(w, comp)
          assert_eq(traces.length(), 1)
          assert_true(!traces[0].violated)
          assert_eq(traces[0].level, "通过")
          assert_eq(traces[0].conclusion, "通过：无适用规则")
          assert_true(
            @sai-bu-moonbit.render_trace(traces[0]).contains(
              "[无适用规则]",
            ),
          )
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "rule citation fallback returns empty text" {
  // 没收录原文引用的规则不编假原文：rule_text 为空，trace 会写明未收录。
  let c = @sai-bu-moonbit.rule_citation_for(
    "首次发布", "不存在的比赛",
  )
  assert_eq(c.rule_text, "")
  assert_eq(c.source, "未收录")
}

///|
test "trace falls back to ledger record for unknown work" {
  // 台账里没有的作品：没有单独证据来源，追踪写“台账记录，未收录单独来源”，
  // 不编一条证据顶上；判定本身仍按标志位 + 台账字段算。
  let base = @sai-bu-moonbit.all_works()[0]
  let unknown : @sai-bu-moonbit.Work = {
    name: "未登记的作品",
    kind: base.kind,
    oneliner: "测试用作品",
    first_public_date: "2026-11-01",
    submitted_to: ["不存在的比赛"],
    materials_ready: [],
    note: "",
  }
  match
    @sai-bu-moonbit.competition_by_name(
      "魔搭 AI+∞ 第三期「AI 造游戏」",
    ) {
    Some(comp) => {
      let t = @sai-bu-moonbit.trace_first_publish(unknown, comp)
      assert_true(t.violated)
      assert_true(
        @sai-bu-moonbit.render_trace(t).contains(
          "台账记录，未收录单独来源",
        ),
      )
    }
    None => assert_true(false)
  }
  match @sai-bu-moonbit.competition_by_name("知乎黑客松 S3") {
    Some(comp) => {
      let t = @sai-bu-moonbit.trace_new_work(unknown, comp)
      assert_true(t.violated)
      assert_true(
        @sai-bu-moonbit.render_trace(t).contains(
          "台账记录，未收录单独来源",
        ),
      )
    }
    None => assert_true(false)
  }
}

///|
test "trace agrees with detect_conflicts on all pairs" {
  // 追踪与引擎用同一条件：每对作品 × 比赛，触发的追踪数必须等于
  // detect_conflicts 报的冲突数；否则追踪与判定两张皮。
  let comps = @sai-bu-moonbit.all_competitions()
  let works = @sai-bu-moonbit.all_works()
  for wi in 0..<works.length() {
    let w = works[wi]
    let conflicts = @sai-bu-moonbit.detect_conflicts(w, comps)
    for ci in 0..<comps.length() {
      let traces = @sai-bu-moonbit.trace_all_rules(w, comps[ci])
      let pair = @sai-bu-moonbit.conflicts_for_competition(
        conflicts,
        comps[ci].name,
      )
      let mut violated = 0
      let mut p0_traces = 0
      let mut p1_traces = 0
      for ti in 0..<traces.length() {
        if traces[ti].violated {
          violated = violated + 1
          if traces[ti].level == "P0" {
            p0_traces = p0_traces + 1
          } else {
            p1_traces = p1_traces + 1
          }
        }
      }
      assert_eq(violated, pair.length())
      let mut p0_conflicts = 0
      let mut p1_conflicts = 0
      for i in 0..<pair.length() {
        if pair[i].level == "P0" {
          p0_conflicts = p0_conflicts + 1
        } else {
          p1_conflicts = p1_conflicts + 1
        }
      }
      assert_eq(p0_traces, p0_conflicts)
      assert_eq(p1_traces, p1_conflicts)
    }
  }
}
