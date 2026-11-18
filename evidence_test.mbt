///|
/// 引用校验追踪的黑盒测试：只测公开 API 的行为。
/// 代表性案例全部用真实台账数据——《第零次黎明》→ 魔搭是 2026-11-18
/// 报名初审驳回时点名要的“从规则适用条件、来源证据到结论”的完整机制
/// 与代表性案例；验价尺 → 软件创新大赛是规则 3 只读 submitted_to
/// 的直接证据；黎明 → 知乎 S3 是 P1（须新做、不阻断）的代表性案例。
/// Run `moon test` to execute.

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
test "trace new work P1 for dawn to zhihu renders full chain" {
  // P1 案例的完整链：结论是 P1（须新做，不能直接交），渲染文本里
  // 规则原文、事实证据、来源三样都必须在，缺一样就是链断了。
  match @sai-bu-moonbit.work_by_name("第零次黎明") {
    Some(w) =>
      match @sai-bu-moonbit.competition_by_name("知乎黑客松 S3") {
        Some(comp) => {
          let t = @sai-bu-moonbit.trace_new_work(w, comp)
          assert_true(t.violated)
          assert_eq(t.level, "P1")
          assert_eq(t.conclusion, "P1：须新做，不能直接交")
          let text = @sai-bu-moonbit.render_trace(t)
          assert_true(text.contains("48h 新做作品"))
          assert_true(text.contains("Combos 分享页"))
          assert_true(text.contains("知乎黑客松 S3 官方活动页"))
          assert_true(text.contains("2026-11-02 之前"))
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "trace all rules dawn to zhihu has one P1" {
  // 知乎 S3 只开规则 2 一个标志位，追踪应恰好 1 份，且为 P1。
  match @sai-bu-moonbit.work_by_name("第零次黎明") {
    Some(w) =>
      match @sai-bu-moonbit.competition_by_name("知乎黑客松 S3") {
        Some(comp) => {
          let traces = @sai-bu-moonbit.trace_all_rules(w, comp)
          assert_eq(traces.length(), 1)
          assert_true(traces[0].violated)
          assert_eq(traces[0].level, "P1")
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

///|
test "trace first publish passes for clean work to moda" {
  // 既没公开、也没投过任何比赛的作品：首次发布规则两个分支均未命中，
  // 追踪应报通过（满足首次发布要求），不是 P0。
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
  match
    @sai-bu-moonbit.competition_by_name(
      "魔搭 AI+∞ 第三期「AI 造游戏」",
    ) {
    Some(comp) => {
      let t = @sai-bu-moonbit.trace_first_publish(clean, comp)
      assert_true(!t.violated)
      assert_eq(t.level, "通过")
      assert_eq(t.conclusion, "通过：满足首次发布要求")
      assert_true(
        @sai-bu-moonbit.render_trace(t).contains("两个分支均未命中"),
      )
    }
    None => assert_true(false)
  }
}

///|
test "trace new work not applicable for dawn to songjiang" {
  // 松江明确已有成品可参赛，不要求必须新做，规则不适用。
  match @sai-bu-moonbit.work_by_name("第零次黎明") {
    Some(w) =>
      match
        @sai-bu-moonbit.competition_by_name("松江·创世纪 AI 游戏大赛") {
        Some(comp) => {
          let t = @sai-bu-moonbit.trace_new_work(w, comp)
          assert_true(!t.violated)
          assert_eq(t.level, "通过")
          assert_eq(t.conclusion, "通过：规则不适用")
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "trace no prior entry not applicable for dawn to songjiang" {
  // 松江无原创条款要求，规则不适用。
  match @sai-bu-moonbit.work_by_name("第零次黎明") {
    Some(w) =>
      match
        @sai-bu-moonbit.competition_by_name("松江·创世纪 AI 游戏大赛") {
        Some(comp) => {
          let t = @sai-bu-moonbit.trace_no_prior_entry(w, comp)
          assert_true(!t.violated)
          assert_eq(t.level, "通过")
          assert_eq(t.conclusion, "通过：规则不适用")
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "trace no prior entry passes for unpublished clean work" {
  // 既没公开、也没投过比赛的作品对软件创新大赛：规则 3 通过，
  // 且追踪要写明“作品未公开。”（pub_note 的另一分支）。
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
  match
    @sai-bu-moonbit.competition_by_name(
      "第二十届全国大学生软件创新大赛",
    ) {
    Some(comp) => {
      let t = @sai-bu-moonbit.trace_no_prior_entry(clean, comp)
      assert_true(!t.violated)
      assert_eq(t.level, "通过")
      assert_true(
        @sai-bu-moonbit.render_trace(t).contains("作品未公开。"),
      )
    }
    None => assert_true(false)
  }
}

///|
test "rule citation for taptap qualifications" {
  // TapTap 上架资质引用：四项资质 + H5 包 + 简体中文材料 + 人工审核，
  // 2026-11-16 核实，来源写明是官方上架流程。
  let c = @sai-bu-moonbit.rule_citation_for(
    "上架资质", "TapTap 游戏上架",
  )
  assert_true(c.rule_text.contains("实名认证"))
  assert_true(c.rule_text.contains("AI 接入声明"))
  assert_true(c.rule_text.contains("适龄分级"))
  assert_true(c.rule_text.contains("隐私合规"))
  assert_true(c.rule_text.contains("index.html"))
  assert_eq(c.verified_at, "2026-11-16")
}

///|
test "rule citation for itch qualifications" {
  // itch.io 上架资质引用：ZIP 包 + 限制 + 相对路径 + AI 披露 +
  // Mobile Friendly，2026-11-18 逐字核实官方文档。
  let c = @sai-bu-moonbit.rule_citation_for(
    "上架资质", "itch.io 游戏上架",
  )
  assert_true(c.rule_text.contains("index.html"))
  assert_true(c.rule_text.contains("≤1000 文件"))
  assert_true(c.rule_text.contains("相对路径"))
  assert_true(c.rule_text.contains("AI Disclosure"))
  assert_true(c.rule_text.contains("Mobile Friendly"))
  assert_true(c.source.contains("itch.io"))
  assert_eq(c.verified_at, "2026-11-18")
}

///|
test "trace qualifications P1 for dawn to taptap" {
  // 《第零次黎明》→ TapTap：四项资质全缺 + H5 包缺 + 触屏缺，
  // 共 6 项缺口，报 P1；触屏缺口要带 2026-11-16 的核实证据
  // （PC 端 WASD+鼠标操作、无触屏适配）。
  match @sai-bu-moonbit.work_by_name("第零次黎明") {
    Some(w) =>
      match @sai-bu-moonbit.competition_by_name("TapTap 游戏上架") {
        Some(comp) => {
          let t = @sai-bu-moonbit.trace_qualifications(w, comp)
          assert_true(t.violated)
          assert_eq(t.level, "P1")
          assert_eq(t.conclusion, "P1：须补齐上架资质后才能上架")
          let text = @sai-bu-moonbit.render_trace(t)
          assert_true(text.contains("实名认证"))
          assert_true(text.contains("AI 接入声明"))
          assert_true(text.contains("适龄分级"))
          assert_true(text.contains("隐私合规"))
          assert_true(text.contains("触屏适配"))
          assert_true(text.contains("WASD"))
          assert_true(text.contains("2026-11-16"))
          assert_true(text.contains("缺 6 项"))
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "trace qualifications P1 for dawn to itch" {
  // 《第零次黎明》→ itch.io：6 项资质全缺，报 P1；
  // 追踪要逐字写出 ZIP 限制与 AI Disclosure 要求。
  match @sai-bu-moonbit.work_by_name("第零次黎明") {
    Some(w) =>
      match @sai-bu-moonbit.competition_by_name("itch.io 游戏上架") {
        Some(comp) => {
          let t = @sai-bu-moonbit.trace_qualifications(w, comp)
          assert_true(t.violated)
          assert_eq(t.level, "P1")
          assert_eq(t.conclusion, "P1：须补齐上架资质后才能上架")
          let text = @sai-bu-moonbit.render_trace(t)
          assert_true(text.contains("index.html"))
          assert_true(text.contains("AI Disclosure"))
          assert_true(text.contains("Mobile Friendly"))
          assert_true(text.contains("相对路径"))
          assert_true(text.contains("缺 6 项"))
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "trace qualifications not applicable for dawn to songjiang" {
  // 松江是比赛目标，不是平台上架目标，上架资质规则不适用。
  match @sai-bu-moonbit.work_by_name("第零次黎明") {
    Some(w) =>
      match
        @sai-bu-moonbit.competition_by_name("松江·创世纪 AI 游戏大赛") {
        Some(comp) => {
          let t = @sai-bu-moonbit.trace_qualifications(w, comp)
          assert_true(!t.violated)
          assert_eq(t.level, "通过")
          assert_eq(t.conclusion, "通过：规则不适用")
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "trace qualifications passes for fully ready work" {
  // 材料清单齐全的作品：6 项资质全部就绪，追踪通过。
  // 材料清单直接取目标的清单本身，不硬编码 6 个字符串。
  match @sai-bu-moonbit.competition_by_name("TapTap 游戏上架") {
    Some(comp) => {
      let base = @sai-bu-moonbit.all_works()[0]
      let ready : @sai-bu-moonbit.Work = {
        name: "资质齐全的作品",
        kind: base.kind,
        oneliner: "测试用作品",
        first_public_date: "",
        submitted_to: [],
        materials_ready: comp.materials,
        note: "",
      }
      let t = @sai-bu-moonbit.trace_qualifications(ready, comp)
      assert_true(!t.violated)
      assert_eq(t.level, "通过")
      assert_eq(t.conclusion, "通过：上架资质齐全")
      assert_true(@sai-bu-moonbit.render_trace(t).contains("全部就绪"))
    }
    None => assert_true(false)
  }
}

///|
test "trace all rules dawn to taptap has one P1" {
  // TapTap 未开三个比赛标志位：trace_all_rules 只出 1 份追踪，
  // 就是上架资质（规则 4），与 detect_conflicts 的 1 个 P1 一致。
  match @sai-bu-moonbit.work_by_name("第零次黎明") {
    Some(w) =>
      match @sai-bu-moonbit.competition_by_name("TapTap 游戏上架") {
        Some(comp) => {
          let traces = @sai-bu-moonbit.trace_all_rules(w, comp)
          assert_eq(traces.length(), 1)
          assert_eq(traces[0].level, "P1")
          assert_true(traces[0].violated)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "shortest blocking chain for dawn to moda is first publish" {
  // 黎明 → 魔搭：唯一 P0 是规则 1（首次发布），最短阻断链只有它一条；
  // 渲染行指明是哪条规则直接导致不可提交。
  match @sai-bu-moonbit.work_by_name("第零次黎明") {
    Some(w) =>
      match
        @sai-bu-moonbit.competition_by_name(
          "魔搭 AI+∞ 第三期「AI 造游戏」",
        ) {
        Some(comp) => {
          let traces = @sai-bu-moonbit.trace_all_rules(w, comp)
          let chain = @sai-bu-moonbit.shortest_blocking_chain(traces)
          assert_eq(chain.length(), 1)
          assert_eq(chain[0], "首次发布")
          assert_eq(
            @sai-bu-moonbit.render_blocking_chain(chain),
            "最短阻断链：首次发布 → 不可提交（P0）",
          )
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "shortest blocking chain for dawn to software innovation is no prior entry" {
  // 黎明 → 软件创新大赛：唯一 P0 是规则 3（原创条款），链只有它一条。
  match @sai-bu-moonbit.work_by_name("第零次黎明") {
    Some(w) =>
      match
        @sai-bu-moonbit.competition_by_name(
          "第二十届全国大学生软件创新大赛",
        ) {
        Some(comp) => {
          let traces = @sai-bu-moonbit.trace_all_rules(w, comp)
          let chain = @sai-bu-moonbit.shortest_blocking_chain(traces)
          assert_eq(chain.length(), 1)
          assert_eq(chain[0], "未参加过其他比赛")
          assert_eq(
            @sai-bu-moonbit.render_blocking_chain(chain),
            "最短阻断链：未参加过其他比赛 → 不可提交（P0）",
          )
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "shortest blocking chain empty when rule passes" {
  // 验价尺 → 软件创新大赛：规则 3 通过，无 P0 阻断，链为空、渲染为空串。
  match @sai-bu-moonbit.work_by_name("验价尺") {
    Some(w) =>
      match
        @sai-bu-moonbit.competition_by_name(
          "第二十届全国大学生软件创新大赛",
        ) {
        Some(comp) => {
          let traces = @sai-bu-moonbit.trace_all_rules(w, comp)
          let chain = @sai-bu-moonbit.shortest_blocking_chain(traces)
          assert_eq(chain.length(), 0)
          assert_eq(@sai-bu-moonbit.render_blocking_chain(chain), "")
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "shortest blocking chain empty when no rule applies" {
  // 黎明 → 松江：无适用规则，无 P0 阻断。
  match @sai-bu-moonbit.work_by_name("第零次黎明") {
    Some(w) =>
      match
        @sai-bu-moonbit.competition_by_name("松江·创世纪 AI 游戏大赛") {
        Some(comp) => {
          let traces = @sai-bu-moonbit.trace_all_rules(w, comp)
          let chain = @sai-bu-moonbit.shortest_blocking_chain(traces)
          assert_eq(chain.length(), 0)
          assert_eq(@sai-bu-moonbit.render_blocking_chain(chain), "")
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "shortest blocking chain empty for P1 only" {
  // P1 不是阻断：黎明 → 知乎 S3（须新做）与黎明 → TapTap（上架资质）
  // 都只有 P1，链为空——最短阻断链只收 P0。
  match @sai-bu-moonbit.work_by_name("第零次黎明") {
    Some(w) => {
      match @sai-bu-moonbit.competition_by_name("知乎黑客松 S3") {
        Some(comp) => {
          let traces = @sai-bu-moonbit.trace_all_rules(w, comp)
          assert_eq(@sai-bu-moonbit.shortest_blocking_chain(traces).length(), 0)
        }
        None => assert_true(false)
      }
      match @sai-bu-moonbit.competition_by_name("TapTap 游戏上架") {
        Some(comp) => {
          let traces = @sai-bu-moonbit.trace_all_rules(w, comp)
          assert_eq(@sai-bu-moonbit.shortest_blocking_chain(traces).length(), 0)
        }
        None => assert_true(false)
      }
    }
    None => assert_true(false)
  }
}

///|
test "shortest blocking chain two rules for synthetic double P0" {
  // 合成比赛同时开规则 1 与规则 3，作品两条都触发：链应有两条，
  // 按规则顺序排列，渲染行用 " + " 连接。
  let base = @sai-bu-moonbit.all_works()[0]
  let work : @sai-bu-moonbit.Work = {
    name: "合成作品",
    kind: base.kind,
    oneliner: "测试用作品",
    first_public_date: "2026-11-01",
    submitted_to: ["Qoder"],
    materials_ready: [],
    note: "",
  }
  let comp : @sai-bu-moonbit.Competition = {
    name: "合成双 P0 比赛",
    target_kind: "比赛",
    deadline: "2026-12-31",
    deadline_date: "2026-12-31",
    verified_at: "2026-11-18",
    prize: "无",
    track: "测试",
    status: "未报名",
    plan_status: "关注",
    requires_first_publish: true,
    requires_new_work: false,
    requires_no_prior_entry: true,
    allows_existing_works: false,
    materials: [],
    note: "",
  }
  let traces = @sai-bu-moonbit.trace_all_rules(work, comp)
  let chain = @sai-bu-moonbit.shortest_blocking_chain(traces)
  assert_eq(chain.length(), 2)
  assert_eq(chain[0], "首次发布")
  assert_eq(chain[1], "未参加过其他比赛")
  assert_eq(
    @sai-bu-moonbit.render_blocking_chain(chain),
    "最短阻断链：首次发布 + 未参加过其他比赛 → 不可提交（P0）",
  )
}

///|
test "shortest blocking chain matches engine P0 count on all pairs" {
  // 最短阻断链与引擎用同一判定：每对作品 × 目标，链的长度必须等于
  // detect_conflicts 报的 P0 冲突数；否则链与判定两张皮。
  let comps = @sai-bu-moonbit.all_competitions()
  let works = @sai-bu-moonbit.all_works()
  for wi in 0..<works.length() {
    let w = works[wi]
    let conflicts = @sai-bu-moonbit.detect_conflicts(w, comps)
    for ci in 0..<comps.length() {
      let traces = @sai-bu-moonbit.trace_all_rules(w, comps[ci])
      let chain = @sai-bu-moonbit.shortest_blocking_chain(traces)
      let pair = @sai-bu-moonbit.conflicts_for_competition(
        conflicts,
        comps[ci].name,
      )
      let mut p0_conflicts = 0
      for i in 0..<pair.length() {
        if pair[i].level == "P0" {
          p0_conflicts = p0_conflicts + 1
        }
      }
      assert_eq(chain.length(), p0_conflicts)
    }
  }
}
