///|
/// CLI 入口。
/// 无参数：跑整条流水线（台账 → 冲突检测 → 撞期提醒 → 投稿包），
/// 输出与 v0.1.0 保持一致。
/// 带子命令：只做该子命令的事。
///   list                          打印投稿目标台账
///   conflicts <作品名>            查一件作品对全部目标的冲突
///   pack <作品名> <目标名>        生成单个投稿包
///   collisions                    截止撞期提醒
///   benchmark                     实测扫描（目标数/规则数/冲突数/投稿包数/耗时）
///   validate                      校验台账数据（名字/日期/材料/标志位），有问题返回码 1
///   preflight                     全链路预检：validate → 逐行核验 → 冲突检测 →
///                                 投稿包认证 → 撞期提醒，输出清单 SHA-256
///   trace <作品名> <目标名>       引用校验追踪：规则适用条件 → 来源证据 → 结论，
///                                 有 P0 时再加一行最短阻断链，
///                                 再加该对作品 × 目标的投稿包认证
///   help                          显示本帮助
/// 用法：moon run cmd/main [子命令 ...]
/// 作品名、目标名含空格时请加引号，例如：
///   moon run cmd/main pack 第零次黎明 "魔搭 AI+∞ 第三期「AI 造游戏」"
fn main {
  let args = user_args()
  if args.length() == 0 {
    run_full_pipeline()
    return
  }
  match args[0] {
    "list" => cmd_list()
    "conflicts" => cmd_conflicts(args)
    "pack" => cmd_pack(args)
    "collisions" => cmd_collisions()
    "benchmark" => cmd_benchmark()
    "validate" => cmd_validate()
    "preflight" => cmd_preflight()
    "trace" => cmd_trace(args)
    "itch-zip" => cmd_itch_zip(args)
    "help" | "-h" | "--help" => print_usage()
    other => {
      println("未知子命令：\{other}")
      print_usage()
    }
  }
}

///|
/// 命令行参数：去掉 argv[0]（程序路径）和可能出现的前导 "--"。
/// `@env.args()` 返回的数组包含程序路径作为第 0 项。
fn user_args() -> Array[String] {
  let raw = @env.args()
  let out : Array[String] = []
  for i in 1..<raw.length() {
    if i == 1 && raw[i] == "--" {
      continue
    }
    out.push(raw[i])
  }
  out
}

///|
/// 无参数时的整条流水线：投稿目标台账 -> 冲突检测 -> 截止撞期提醒 -> 投稿包生成。
/// Run with `moon run cmd/main` from the project root.
fn run_full_pipeline() -> Unit {
  println("== 赛簿 · MoonBit 版 v0.1.0 ==")
  println(
    "多目标并行管理 + 游戏投稿支持 + 冲突检测（原创 MoonBit 实现）",
  )
  println("")
  let comps = @lib.all_competitions()
  let mut comp_count = 0
  let mut plat_count = 0
  for i in 0..<comps.length() {
    if comps[i].target_kind == "平台上架" {
      plat_count = plat_count + 1
    } else {
      comp_count = comp_count + 1
    }
  }
  println(
    "-- 投稿目标台账（\{comps.length()} 个：\{comp_count} 个比赛 + \{plat_count} 个平台上架，按截止排序）--",
  )
  for i in 0..<comps.length() {
    let c = comps[i]
    println(
      "\{i + 1}. \{c.name} | 截止 \{c.deadline} | \{c.prize} | 计划：\{c.plan_status} | 状态：\{c.status}",
    )
  }
  println("")
  match @lib.work_by_name("第零次黎明") {
    Some(dawn) => {
      println("-- 冲突检测：《第零次黎明》 --")
      let conflicts = @lib.detect_conflicts(dawn, comps)
      if conflicts.length() == 0 {
        println("无冲突")
      } else {
        for i in 0..<conflicts.length() {
          let cf = conflicts[i]
          println("[\{cf.level}] \{cf.competition}：\{cf.message}")
        }
      }
      println("")
      println("-- 截止撞期提醒 --")
      let collisions = @lib.collision_conflicts(comps)
      if collisions.length() == 0 {
        println("无撞期")
      } else {
        for i in 0..<collisions.length() {
          println("[\{collisions[i].level}] \{collisions[i].message}")
        }
      }
      println("")
      println("-- 投稿包：黎明 → 魔搭 --")
      match
        @lib.competition_by_name("魔搭 AI+∞ 第三期「AI 造游戏」") {
        Some(moda) => print_pack(@lib.generate_pack(dawn, moda, conflicts))
        None => println("未找到比赛")
      }
      println("")
      println("-- 投稿包：黎明 → 松江 --")
      match @lib.competition_by_name("松江·创世纪 AI 游戏大赛") {
        Some(songjiang) =>
          print_pack(@lib.generate_pack(dawn, songjiang, conflicts))
        None => println("未找到比赛")
      }
      println("")
      println("-- 投稿包：黎明 → TapTap --")
      match @lib.competition_by_name("TapTap 游戏上架") {
        Some(taptap) => print_pack(@lib.generate_pack(dawn, taptap, conflicts))
        None => println("未找到目标")
      }
      println("")
      println(
        "数据说明：目标数据来自已核实的《最近要参加的比赛汇总》与平台官方上架要求；魔搭“首次发布”条款来自 AIBetas 转述官方页，官网原文因登录墙未直接读到，12-01 提交前务必在官网或官方群问清。",
      )
    }
    None => println("未找到作品《第零次黎明》")
  }
}

///|
fn print_pack(pack : @lib.SubmissionPack) -> Unit {
  println("作品：\{pack.work} → 目标：\{pack.competition}")
  println("标题：\{pack.title}")
  println("一句话介绍：\{pack.oneliner}")
  println(
    "材料（共 \{pack.materials.length()} 项）：\{@lib.join_strings(pack.materials, "；")}",
  )
  println(
    "已就绪（\{pack.ready.length()} 项）：\{@lib.join_strings(pack.ready, "；")}",
  )
  println(
    "缺口（\{pack.gaps.length()} 项）：\{@lib.join_strings(pack.gaps, "；")}",
  )
  println("状态：\{pack.note}")
}

///|
fn print_usage() -> Unit {
  println("用法：moon run cmd/main [子命令 ...]")
  println(
    "无参数：跑整条流水线（台账 → 冲突检测 → 撞期提醒 → 投稿包）",
  )
  println("list：打印投稿目标台账")
  println("conflicts <作品名>：查一件作品对全部目标的冲突")
  println("pack <作品名> <目标名>：生成单个投稿包")
  println("collisions：截止撞期提醒")
  println(
    "benchmark：实测扫描（目标数/规则数/冲突数/投稿包数/耗时）",
  )
  println("validate：校验台账数据，有问题返回码 1")
  println(
    "preflight：全链路预检（validate → 逐行核验 → 冲突检测 → 投稿包认证 → 撞期提醒），输出清单 SHA-256",
  )
  println(
    "trace <作品名> <目标名>：引用校验追踪（规则适用条件 → 来源证据 → 结论）+ 该对组合的投稿包认证",
  )
  println(
    "itch-zip：从 ZIP 元数据校验 itch.io HTML5 包体，入口用 scripts/inspect_itch_zip.py",
  )
  println("help：显示本帮助")
}

///|
fn print_work_names() -> Unit {
  let works = @lib.all_works()
  println("作品列表：")
  for i in 0..<works.length() {
    println("  - \{works[i].name}")
  }
}

///|
fn print_competition_names() -> Unit {
  let comps = @lib.all_competitions()
  println("投稿目标列表：")
  for i in 0..<comps.length() {
    println("  - \{comps[i].name}")
  }
}

///|
fn cmd_list() -> Unit {
  let comps = @lib.all_competitions()
  let mut comp_count = 0
  let mut plat_count = 0
  for i in 0..<comps.length() {
    if comps[i].target_kind == "平台上架" {
      plat_count = plat_count + 1
    } else {
      comp_count = comp_count + 1
    }
  }
  println(
    "-- 投稿目标台账（\{comps.length()} 个：\{comp_count} 个比赛 + \{plat_count} 个平台上架，按截止排序）--",
  )
  for i in 0..<comps.length() {
    let c = comps[i]
    println(
      "\{i + 1}. \{c.name} | 截止 \{c.deadline} | \{c.prize} | 计划：\{c.plan_status} | 状态：\{c.status}",
    )
  }
}

///|
fn cmd_conflicts(args : Array[String]) -> Unit {
  if args.length() < 2 {
    println("用法：conflicts <作品名>")
    print_work_names()
    return
  }
  match @lib.work_by_name(args[1]) {
    Some(w) => {
      let conflicts = @lib.detect_conflicts(w, @lib.all_competitions())
      if conflicts.length() == 0 {
        println("《\{w.name}》：无冲突")
      } else {
        println("《\{w.name}》：发现 \{conflicts.length()} 个冲突")
        for i in 0..<conflicts.length() {
          let cf = conflicts[i]
          println("[\{cf.level}] \{cf.competition}：\{cf.message}")
        }
      }
    }
    None => {
      println("未找到作品：\{args[1]}")
      print_work_names()
    }
  }
}

///|
fn cmd_pack(args : Array[String]) -> Unit {
  if args.length() < 3 {
    println("用法：pack <作品名> <目标名>")
    print_work_names()
    print_competition_names()
    return
  }
  match @lib.work_by_name(args[1]) {
    Some(w) =>
      match @lib.competition_by_name(args[2]) {
        Some(comp) => {
          let conflicts = @lib.detect_conflicts(w, @lib.all_competitions())
          print_pack(@lib.generate_pack(w, comp, conflicts))
        }
        None => {
          println("未找到目标：\{args[2]}")
          print_competition_names()
        }
      }
    None => {
      println("未找到作品：\{args[1]}")
      print_work_names()
    }
  }
}

///|
fn cmd_collisions() -> Unit {
  let collisions = @lib.collision_conflicts(@lib.all_competitions())
  if collisions.length() == 0 {
    println("无撞期")
  } else {
    for i in 0..<collisions.length() {
      println("[\{collisions[i].level}] \{collisions[i].message}")
    }
  }
}

///|
/// 数据校验：名字/日期/材料/标志位自洽则打印通过，否则列出问题并返回码 1。
fn cmd_validate() -> Unit {
  let comps = @lib.all_competitions()
  let works = @lib.all_works()
  let issues = @lib.validate_data(comps, works)
  println("== 数据校验 ==")
  println(
    "投稿目标：\{comps.length()} 个，作品：\{works.length()} 件",
  )
  if issues.length() == 0 {
    println("通过：0 个问题")
  } else {
    println("发现 \{issues.length()} 个问题：")
    for i in 0..<issues.length() {
      println("  - \{issues[i]}")
    }
    @env.exit(1)
  }
}

///|
/// 全链路预检：用真实数据一口气跑完 validate → 逐行核验 → 冲突检测 →
/// 投稿包认证 → 撞期提醒，输出可提交的投稿包 + 带 SHA-256 的清单。
/// 学 Auto-Lexmount 的预检纪律（submission.py / workflow.py，代码没抄）：
/// 数据自相矛盾就整单拒绝（返回码 1）；P0 冲突直接标 blocked；
/// 数据未核实或已过期拒绝认证；不自动重试；失败原因逐项写清。
/// 单个包的拒绝是结论，不是进程失败——只在 validate 有问题时返回码 1。
fn cmd_preflight() -> Unit {
  let comps = @lib.all_competitions()
  let works = @lib.all_works()
  let report = @lib.preflight(comps, works, @env.now())
  println("== preflight 全链路预检 ==")
  println("今天：\{report.today}")
  if report.validate_issues.length() > 0 {
    println(
      "数据校验失败：\{report.validate_issues.length()} 个问题：",
    )
    for i in 0..<report.validate_issues.length() {
      println("  - \{report.validate_issues[i]}")
    }
    println(
      "拒绝认证：台账数据自相矛盾，先修数据再跑 preflight。",
    )
    @env.exit(1)
  }
  println("数据校验：通过（0 个问题）")
  let mut verified_rows = 0
  for i in 0..<report.rows.length() {
    if report.rows[i].verified {
      verified_rows = verified_rows + 1
    }
  }
  println(
    "台账核验：\{report.rows.length()} 行，\{verified_rows} 行已核实，\{report.rows.length() - verified_rows} 行未核实/已过期",
  )
  for i in 0..<report.rows.length() {
    let r = report.rows[i]
    if !r.verified {
      println("  - \{r.competition}：\{r.reason}")
    }
  }
  println(
    "投稿包认证：\{report.packs.length()} 个，可提交 \{report.certifiable_count} 个，P0 挡住 \{report.blocked_count} 个",
  )
  println("可提交：")
  for i in 0..<report.packs.length() {
    let p = report.packs[i]
    if p.certifiable {
      println("  - \{p.work} → \{p.competition}")
    }
  }
  println("P0 挡住：")
  for i in 0..<report.packs.length() {
    let p = report.packs[i]
    if p.blocked {
      let mut reason = ""
      for j in 0..<p.reasons.length() {
        if p.reasons[j].contains("P0 冲突") {
          reason = p.reasons[j]
          break
        }
      }
      println("  - \{p.work} → \{p.competition}：\{reason}")
    }
  }
  let mut other = 0
  for i in 0..<report.packs.length() {
    let p = report.packs[i]
    if !p.certifiable && !p.blocked {
      other = other + 1
    }
  }
  println(
    "其余 \{other} 个不可提交：作品类型、材料缺口、资格待核实或台账未通过核验（详情见逐包认证）",
  )
  println("截止撞期：\{report.collisions.length()} 个日期")
  for i in 0..<report.collisions.length() {
    println("  - \{report.collisions[i]}")
  }
  println("清单 SHA-256：\{report.manifest_hash}")
  println(
    "说明：preflight 是纯本地单次运行，不联网、不重试；清单哈希由全部台账数据算出，数据一变哈希就变。",
  )
}

///|
/// 引用校验追踪：打印一件作品对一个目标的全部规则追踪（规则适用条件 →
/// 来源证据 → 结论），有 P0 时再加一行最短阻断链（是哪 1–2 条规则
/// 直接导致不可提交），再加该对组合的投稿包认证。
/// 追踪的判定与 detect_conflicts 用同一条件（标志位 + 台账字段），
/// 这里只补上规则原文引用与事实证据，不另写一套判定。
fn cmd_trace(args : Array[String]) -> Unit {
  if args.length() < 3 {
    println("用法：trace <作品名> <目标名>")
    print_work_names()
    print_competition_names()
    return
  }
  match @lib.work_by_name(args[1]) {
    Some(w) =>
      match @lib.competition_by_name(args[2]) {
        Some(comp) => {
          println("== 引用校验追踪：\{w.name} → \{comp.name} ==")
          let traces = @lib.trace_all_rules(w, comp)
          for i in 0..<traces.length() {
            println(@lib.render_trace(traces[i]))
            println("")
          }
          let chain_line = @lib.render_blocking_chain(
            @lib.shortest_blocking_chain(traces),
          )
          if chain_line != "" {
            println(chain_line)
            println("")
          }
          let conflicts = @lib.detect_conflicts(w, @lib.all_competitions())
          let row = @lib.row_verdict(comp, @lib.today_days(@env.now()))
          let verdict = @lib.certify_pack(w, comp, conflicts, row)
          println("== 投稿包认证 ==")
          print_pack(@lib.generate_pack(w, comp, conflicts))
          if verdict.certifiable {
            println("认证结论：可提交")
          } else {
            println("认证结论：不可提交")
            for i in 0..<verdict.reasons.length() {
              println("  - \{verdict.reasons[i]}")
            }
          }
          println(
            "说明：追踪的每一步都带规则原文引用与事实证据；结论由 MoonBit 当场算出。完整案例见 docs/worked-example-moda-dawn.md。",
          )
        }
        None => {
          println("未找到目标：\{args[2]}")
          print_competition_names()
        }
      }
    None => {
      println("未找到作品：\{args[1]}")
      print_work_names()
    }
  }
}

///|
/// 实测扫描：先跑一轮全量扫描数真实结果（全部作品 × 全部目标的
/// 冲突检测与投稿包生成），再把同样的全量扫描重复 100 轮计时。
/// 所有数字都是当场跑出来的。
fn cmd_benchmark() -> Unit {
  let comps = @lib.all_competitions()
  let works = @lib.all_works()
  let mut total_conflicts = 0
  let mut p0_conflicts = 0
  let mut p1_conflicts = 0
  let mut total_packs = 0
  let mut blocked_packs = 0
  let mut rule_checks = 0
  for wi in 0..<works.length() {
    let w = works[wi]
    let conflicts = @lib.detect_conflicts(w, comps)
    total_conflicts = total_conflicts + conflicts.length()
    // 每件作品 × 每个目标评估规则：比赛 3 条（首次发布 / 须新做 /
    // 未参加过其他比赛），平台上架目标 1 条（上架资质清单）
    for ci in 0..<comps.length() {
      if comps[ci].target_kind == "平台上架" {
        rule_checks = rule_checks + 1
      } else {
        rule_checks = rule_checks + 3
      }
    }
    for i in 0..<conflicts.length() {
      if conflicts[i].level == "P0" {
        p0_conflicts = p0_conflicts + 1
      } else {
        p1_conflicts = p1_conflicts + 1
      }
    }
    for ci in 0..<comps.length() {
      let pack = @lib.generate_pack(w, comps[ci], conflicts)
      total_packs = total_packs + 1
      if pack.blocked {
        blocked_packs = blocked_packs + 1
      }
    }
  }
  let collisions = @lib.collision_conflicts(comps)
  let rounds = 100
  let start = @env.now()
  for _r in 0..<rounds {
    for wi in 0..<works.length() {
      let w = works[wi]
      let conflicts = @lib.detect_conflicts(w, comps)
      for ci in 0..<comps.length() {
        let _pack = @lib.generate_pack(w, comps[ci], conflicts)
      }
    }
    let _c = @lib.collision_conflicts(comps)
  }
  let elapsed_ms = @env.now() - start
  println("== 实测 benchmark（全量扫描 × \{rounds} 轮）==")
  println("投稿目标数：\{comps.length()}")
  println("作品数：\{works.length()}")
  println(
    "规则评估：\{rule_checks} 次/轮（每作品 × 每比赛 3 条规则 + 每平台上架目标 1 条上架资质检查）",
  )
  println(
    "发现冲突：\{total_conflicts} 个（P0 \{p0_conflicts} 个，P1 \{p1_conflicts} 个）",
  )
  println(
    "生成投稿包：\{total_packs} 个，其中 P0 挡住：\{blocked_packs} 个",
  )
  println("截止撞期：\{collisions.length()} 个日期")
  println(
    "\{rounds} 轮总耗时：\{elapsed_ms} 毫秒，平均每轮：\{elapsed_ms * 1000 / 100} 微秒",
  )
}

///|
fn cmd_itch_zip(args : Array[String]) -> Unit {
  if args.length() != 6 || (args[5] != "0" && args[5] != "1") {
    println(
      "用法：itch-zip 文件数 解包字节数 最大文件字节数 最长路径字符数 根目录入口(0/1)",
    )
    @env.exit(2)
  }
  let issues = @lib.itch_zip_issues(
    @string.parse_int64(args[1]),
    @string.parse_int64(args[2]),
    @string.parse_int64(args[3]),
    @string.parse_int64(args[4]),
    args[5] == "1",
  ) catch {
    _ => {
      println("ZIP 指标须为整数")
      @env.exit(2)
    }
  }
  println("规则来源：https://itch.io/docs/creators/html5")
  if issues.length() == 0 {
    println(
      "包体认证通过：HTML5 入口及四项 ZIP 默认上限均通过",
    )
  } else {
    for issue in issues {
      println("  - " + issue)
    }
    println("包体认证失败")
    @env.exit(2)
  }
}
