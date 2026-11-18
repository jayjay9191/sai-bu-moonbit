///|
/// 引用校验追踪：把一次规则判定写成“规则适用条件 → 来源证据 → 结论”的
/// 完整链，每一步都能指着来源说话。
/// 背景：2026-11-18 报名初审驳回指出，申报书承诺的引用校验与投稿包认证，
/// 缺少从规则适用条件、来源证据到结论的清晰机制和代表性案例。
/// 这个模块就是那个机制：每条规则收录原文引用与来源，每件作品的每条事实
/// 带证据与来源，结论由 MoonBit 当场算出，不是写死在文档里的断言。
/// 规则原文与核实日期来自台账（competition_data.mbt 的 note /
/// verified_at）；作品事实证据见 work_evidence_for（只收录台账里
/// 已有记录的事实，不编新数据）。

///|
/// 一条规则的引用：规则原文 + 来源 + 核实日期。
/// 没有收录原文引用的规则，trace 会写明“未收录”，不编一条假原文顶上。
pub struct RuleCitation {
  rule : String // 规则名，如 "首次发布"
  rule_text : String // 规则原文引用
  source : String // 来源，如 "魔搭官网《参赛须知》第 1 条"
  source_note : String // 来源说明，如 "AIBetas 转述官方页；官网原文因登录墙未直接读到"
  verified_at : String // 来源核实日期 "YYYY-MM-DD"
}

///|
/// 一件作品某个事实的证据。
pub struct FactEvidence {
  fact : String // 事实名，与台账字段里的写法一致，如 "Qoder"、"涌现奖"
  evidence : String // 证据，如 "天池队伍 奶龙奶龙队，队号 1390261"
  source : String // 证据来源说明，如 "用户 2026-11-15 确认已提交"
}

///|
/// 一件作品的事实证据包：首次公开一条 + 已投比赛各一条。
pub struct WorkEvidence {
  first_public : FactEvidence?
  submitted : Array[FactEvidence]
}

///|
/// 一次规则判定的完整追踪。
pub struct DecisionTrace {
  work : String
  competition : String
  rule : RuleCitation
  violated : Bool // 规则是否触发（违规）；false = 通过或规则不适用
  steps : Array[String] // 逐步记录：适用条件、规则原文、事实与证据、推导、结论
  conclusion : String // 结论，如 "P0 冲突：不得投稿" / "通过：规则不适用"
  level : String // "P0" / "P1" / "通过"
}

///|
/// 按（规则名，比赛名）查规则原文引用。
/// 目前收录全部 4 个带规则标志位的比赛：魔搭（首次发布）、知乎 S3
/// （须新做）、造化（须新做）、软件创新大赛（原创条款）。
/// 查不到的返回空原文引用，trace 会写明“未收录”，不编数据。
pub fn rule_citation_for(rule : String, competition : String) -> RuleCitation {
  if rule == "首次发布" &&
    competition == "魔搭 AI+∞ 第三期「AI 造游戏」" {
    {
      rule,
      rule_text: "参赛作品必须为活动期间首次公开发布的原创作品，不得使用已参加其他比赛或由其他比赛产生的作品、成果参赛",
      source: "魔搭官网《参赛须知》第 1 条",
      source_note: "AIBetas 转述官方页；官网原文因登录墙未直接读到",
      verified_at: "2026-11-13",
    }
  } else if rule == "须新做" && competition == "知乎黑客松 S3" {
    {
      rule,
      rule_text: "48h 新做作品（未公开发布、不得一稿多投）",
      source: "知乎黑客松 S3 官方活动页",
      source_note: "细则全文在登录墙后；收录的是材料清单原文",
      verified_at: "2026-11-13",
    }
  } else if rule == "须新做" &&
    competition == "造化首届体素游戏创作大赛" {
    {
      rule,
      rule_text: "须用天工引擎新做体素游戏",
      source: "造化官网大赛页",
      source_note: "大赛页 https://zaohua.qq.com/activity/voxel-jam-2026",
      verified_at: "2026-11-15",
    }
  } else if rule == "未参加过其他比赛" &&
    competition == "第二十届全国大学生软件创新大赛" {
    {
      rule,
      rule_text: "参赛作品必须为原创且未参加过其他国家级公开比赛的作品；同一作品重复参加比赛，一经查实取消资格和成绩",
      source: "第二十届全国大学生软件创新大赛原创条款原文",
      source_note: "条款原文已收录于台账 note",
      verified_at: "2026-11-15",
    }
  } else {
    {
      rule,
      rule_text: "",
      source: "未收录",
      source_note: "该比赛未收录规则原文引用；结论仅依据台账标志位",
      verified_at: "",
    }
  }
}

///|
/// 按作品名查事实证据。只收录台账里已有记录的事实：
/// 《第零次黎明》首次公开于 2026-11-02 之前、已投 Qoder 与 AI PLAY；
/// 小店日结、诉求整理台已投涌现奖；验价尺 2026-11-16 首次公开、
/// 未投过任何比赛。查不到的作品返回空证据包，trace 只写台账记录。
pub fn work_evidence_for(name : String) -> WorkEvidence {
  if name == "第零次黎明" {
    {
      first_public: Some({
        fact: "首次公开",
        evidence: "Combos 分享页 https://share.combos.game/p/1737054",
        source: "Combos 平台公开记录",
      }),
      submitted: [
        {
          fact: "Qoder",
          evidence: "天池队伍 奶龙奶龙队，队号 1390261",
          source: "用户 2026-11-15 确认已提交",
        },
        {
          fact: "AI PLAY",
          evidence: "提案已提交",
          source: "用户 2026-11-16 确认",
        },
      ],
    }
  } else if name == "小店日结" {
    {
      first_public: None,
      submitted: [
        {
          fact: "涌现奖",
          evidence: "2026-11-13 提交，个人中心显示审核中",
          source: "用户确认",
        },
      ],
    }
  } else if name == "诉求整理台" {
    {
      first_public: None,
      submitted: [
        {
          fact: "涌现奖",
          evidence: "2026-11-13 提交，个人中心显示审核中",
          source: "用户确认",
        },
      ],
    }
  } else if name == "验价尺" {
    {
      first_public: Some({
        fact: "首次公开",
        evidence: "GitHub 公开仓库 https://github.com/jayjay9191/yan-jia-chi-moonbit",
        source: "GitHub 公开记录",
      }),
      submitted: [],
    }
  } else {
    { first_public: None, submitted: [], }
  }
}

///|
/// 在证据包里按事实名找证据；找不到返回“台账记录，未收录单独来源”，
/// 不编一条证据顶上。
fn evidence_for_submitted(ev : WorkEvidence, name : String) -> String {
  for i in 0..<ev.submitted.length() {
    if ev.submitted[i].fact == name {
      return "（证据：" +
        ev.submitted[i].evidence +
        "；" +
        ev.submitted[i].source +
        "）"
    }
  }
  "（台账记录，未收录单独来源）"
}

///|
/// 规则 1（首次发布）追踪：两个分支都要写证据——
/// 活动开始前已公开，或已投过其他比赛；任一命中即 P0。
pub fn trace_first_publish(work : Work, comp : Competition) -> DecisionTrace {
  let citation = rule_citation_for("首次发布", comp.name)
  if !comp.requires_first_publish {
    {
      work: work.name,
      competition: comp.name,
      rule: citation,
      violated: false,
      steps: [
        "适用条件：该比赛不要求“活动期间首次公开发布”（标志位 requires_first_publish = false），规则不适用。",
        "结论：通过——无需检查首次公开与已投记录。",
      ],
      conclusion: "通过：规则不适用",
      level: "通过",
    }
  } else {
    let ev = work_evidence_for(work.name)
    let steps : Array[String] = []
    steps.push(
      "适用条件：比赛要求“活动期间首次公开发布”（标志位 requires_first_publish = true）。",
    )
    steps.push("规则原文：" + citation.rule_text)
    steps.push(
      "来源：" +
      citation.source +
      "（" +
      citation.source_note +
      "；核实于 " +
      citation.verified_at +
      "）。",
    )
    if work.first_public_date == "" {
      steps.push(
        "事实 1：作品未公开（first_public_date 为空）——公开分支不触发。",
      )
    } else {
      let e = match ev.first_public {
        Some(f) => "证据：" + f.evidence + "（" + f.source + "）"
        None => "证据：台账记录，未收录单独来源"
      }
      steps.push(
        "事实 1：作品首次公开于 " + work.first_public_date + "。" + e,
      )
    }
    if work.submitted_to.length() == 0 {
      steps.push(
        "事实 2：作品未投过其他比赛（submitted_to 为空）——已投分支不触发。",
      )
    } else {
      let mut line = "事实 2：作品已投 " +
        join_strings(work.submitted_to, "、") +
        "。"
      for i in 0..<work.submitted_to.length() {
        line = line + evidence_for_submitted(ev, work.submitted_to[i])
      }
      steps.push(line)
    }
    let triggered : Array[String] = []
    if work.first_public_date != "" {
      triggered.push("活动开始前已公开")
    }
    if work.submitted_to.length() > 0 {
      triggered.push("已投 " + join_strings(work.submitted_to, "、"))
    }
    if triggered.length() > 0 {
      steps.push(
        "推导：命中 " +
        join_strings(triggered, "；") +
        "，违反“活动期间首次公开发布、不得使用已参加其他比赛的作品”。",
      )
      steps.push("结论：P0 冲突——不得投稿该比赛。")
      {
        work: work.name,
        competition: comp.name,
        rule: citation,
        violated: true,
        steps,
        conclusion: "P0 冲突：不得投稿",
        level: "P0",
      }
    } else {
      steps.push(
        "推导：两个分支均未命中——未公开且未投过其他比赛。",
      )
      steps.push("结论：通过——满足首次发布要求。")
      {
        work: work.name,
        competition: comp.name,
        rule: citation,
        violated: false,
        steps,
        conclusion: "通过：满足首次发布要求",
        level: "通过",
      }
    }
  }
}

///|
/// 规则 2（须新做）追踪：只读首次公开日期。
pub fn trace_new_work(work : Work, comp : Competition) -> DecisionTrace {
  let citation = rule_citation_for("须新做", comp.name)
  if !comp.requires_new_work {
    {
      work: work.name,
      competition: comp.name,
      rule: citation,
      violated: false,
      steps: [
        "适用条件：该比赛不要求必须新做（标志位 requires_new_work = false），规则不适用。",
        "结论：通过——无需检查首次公开记录。",
      ],
      conclusion: "通过：规则不适用",
      level: "通过",
    }
  } else {
    let ev = work_evidence_for(work.name)
    let steps : Array[String] = []
    steps.push(
      "适用条件：比赛要求必须新做（标志位 requires_new_work = true）。",
    )
    steps.push("规则原文：" + citation.rule_text)
    steps.push(
      "来源：" +
      citation.source +
      "（" +
      citation.source_note +
      "；核实于 " +
      citation.verified_at +
      "）。",
    )
    if work.first_public_date == "" {
      steps.push("事实：作品未公开（first_public_date 为空）。")
      steps.push("推导：没有公开版本，新做要求满足。")
      steps.push("结论：通过——可以新做投稿。")
      {
        work: work.name,
        competition: comp.name,
        rule: citation,
        violated: false,
        steps,
        conclusion: "通过：可以新做投稿",
        level: "通过",
      }
    } else {
      let e = match ev.first_public {
        Some(f) => "证据：" + f.evidence + "（" + f.source + "）"
        None => "证据：台账记录，未收录单独来源"
      }
      steps.push(
        "事实：作品已有公开版本（首次公开于 " +
        work.first_public_date +
        "）。" +
        e,
      )
      steps.push("推导：已有公开版本，不能直接交，须新做。")
      steps.push("结论：P1——须新做，不能直接交。")
      {
        work: work.name,
        competition: comp.name,
        rule: citation,
        violated: true,
        steps,
        conclusion: "P1：须新做，不能直接交",
        level: "P1",
      }
    }
  }
}

///|
/// 规则 3（原创条款）追踪：只读 submitted_to，不读首次公开日期。
/// 这条要单独写清：只公开、没投过任何比赛的作品不违反本规则——
/// 验价尺对软件创新大赛 0 冲突就是直接证据。
pub fn trace_no_prior_entry(work : Work, comp : Competition) -> DecisionTrace {
  let citation = rule_citation_for("未参加过其他比赛", comp.name)
  if !comp.requires_no_prior_entry {
    {
      work: work.name,
      competition: comp.name,
      rule: citation,
      violated: false,
      steps: [
        "适用条件：该比赛无原创条款要求（标志位 requires_no_prior_entry = false），规则不适用。",
        "结论：通过——无需检查已投记录。",
      ],
      conclusion: "通过：规则不适用",
      level: "通过",
    }
  } else {
    let ev = work_evidence_for(work.name)
    let steps : Array[String] = []
    steps.push(
      "适用条件：比赛要求“参赛作品必须为原创且未参加过其他国家级公开比赛”（标志位 requires_no_prior_entry = true）。",
    )
    steps.push("规则原文：" + citation.rule_text)
    steps.push(
      "来源：" +
      citation.source +
      "（" +
      citation.source_note +
      "；核实于 " +
      citation.verified_at +
      "）。",
    )
    steps.push(
      "注意：本规则只读 submitted_to，不读首次公开日期——只公开、没投过比赛不违反。",
    )
    if work.submitted_to.length() == 0 {
      let pub_note = if work.first_public_date == "" {
        "作品未公开。"
      } else {
        "作品虽已公开（首次公开于 " +
        work.first_public_date +
        "），但本规则不读公开日期，不触发。"
      }
      steps.push(
        "事实：作品未投过其他比赛（submitted_to 为空）。" +
        pub_note,
      )
      steps.push("推导：已投记录为空，原创条款满足。")
      steps.push("结论：通过——未参加过其他比赛。")
      {
        work: work.name,
        competition: comp.name,
        rule: citation,
        violated: false,
        steps,
        conclusion: "通过：未参加过其他比赛",
        level: "通过",
      }
    } else {
      let mut line = "事实：作品已投 " +
        join_strings(work.submitted_to, "、") +
        "。"
      for i in 0..<work.submitted_to.length() {
        line = line + evidence_for_submitted(ev, work.submitted_to[i])
      }
      steps.push(line)
      steps.push(
        "推导：已投 " +
        join_strings(work.submitted_to, "、") +
        "，违反“参赛作品必须为原创且未参加过其他国家级公开比赛”。",
      )
      steps.push("结论：P0 冲突——不得投稿该比赛。")
      {
        work: work.name,
        competition: comp.name,
        rule: citation,
        violated: true,
        steps,
        conclusion: "P0 冲突：不得投稿",
        level: "P0",
      }
    }
  }
}

///|
/// 一件作品对一个比赛的全部规则追踪：三个标志位里开着的规则各出一份
/// 追踪；三个都没开，出一份“无适用规则”的通过追踪。
/// 判定本身复用 detect_conflicts 的同一条件（标志位 + 台账字段），
/// 这里只补上规则原文引用与事实证据，不另写一套判定。
pub fn trace_all_rules(work : Work, comp : Competition) -> Array[DecisionTrace] {
  let result : Array[DecisionTrace] = []
  if comp.requires_first_publish {
    result.push(trace_first_publish(work, comp))
  }
  if comp.requires_new_work {
    result.push(trace_new_work(work, comp))
  }
  if comp.requires_no_prior_entry {
    result.push(trace_no_prior_entry(work, comp))
  }
  if result.length() == 0 {
    result.push({
      work: work.name,
      competition: comp.name,
      rule: rule_citation_for("", comp.name),
      violated: false,
      steps: [
        "适用条件：该比赛无首次发布 / 须新做 / 原创条款要求（三个标志位均为 false），无规则需要判定。",
        "结论：通过——规则层面无阻挡。",
      ],
      conclusion: "通过：无适用规则",
      level: "通过",
    })
  }
  result
}

///|
/// 把一份追踪渲染成可读文本：标题 + 规则原文与来源 + 逐步记录 + 结论。
pub fn render_trace(t : DecisionTrace) -> String {
  let header = if t.rule.rule == "" {
    "[无适用规则]"
  } else {
    "[" + t.rule.rule + "]"
  }
  let mut out = header + t.work + " → " + t.competition + "\n"
  if t.rule.rule_text != "" {
    out = out + "规则原文：" + t.rule.rule_text + "\n"
    out = out +
      "来源：" +
      t.rule.source +
      "（" +
      t.rule.source_note +
      "；核实于 " +
      t.rule.verified_at +
      "）\n"
  }
  for i in 0..<t.steps.length() {
    out = out + (i + 1).to_string() + ". " + t.steps[i] + "\n"
  }
  out = out + "结论：" + t.conclusion + "（" + t.level + "）"
  out
}
