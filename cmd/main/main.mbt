///|
/// CLI 入口。
/// 无参数：跑整条流水线（台账 → 冲突检测 → 撞期提醒 → 投稿包），
/// 输出与 v0.1.0 保持一致。
/// 带子命令：只做该子命令的事。
///   list                          打印比赛台账
///   conflicts <作品名>            查一件作品对全部比赛的冲突
///   pack <作品名> <比赛名>        生成单个投稿包
///   collisions                    截止撞期提醒
///   benchmark                     实测扫描（比赛数/规则数/冲突数/投稿包数/耗时）
///   help                          显示本帮助
/// 用法：moon run cmd/main [子命令 ...]
/// 作品名、比赛名含空格时请加引号，例如：
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
/// 无参数时的整条流水线：比赛台账 -> 冲突检测 -> 截止撞期提醒 -> 投稿包生成。
/// Run with `moon run cmd/main` from the project root.
fn run_full_pipeline() -> Unit {
  println("== 参赛管家 · MoonBit 版 v0.1.0 ==")
  println(
    "多比赛并行管理 + 游戏投稿支持 + 冲突检测（原创 MoonBit 实现）",
  )
  println("")
  let comps = @lib.all_competitions()
  println("-- 比赛台账（12 个，按截止排序）--")
  for i in 0..<comps.length() {
    let c = comps[i]
    println(
      "\{i + 1}. \{c.name} | 截止 \{c.deadline} | \{c.prize} | 状态：\{c.status}",
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
      println(
        "数据说明：比赛数据来自已核实的《最近要参加的比赛汇总》；魔搭“首次发布”条款来自 AIBetas 转述官方页，官网原文因登录墙未直接读到，12-01 提交前务必在官网或官方群问清。",
      )
    }
    None => println("未找到作品《第零次黎明》")
  }
}

///|
fn print_pack(pack : @lib.SubmissionPack) -> Unit {
  println("作品：\{pack.work} → 比赛：\{pack.competition}")
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
  println("list：打印比赛台账")
  println("conflicts <作品名>：查一件作品对全部比赛的冲突")
  println("pack <作品名> <比赛名>：生成单个投稿包")
  println("collisions：截止撞期提醒")
  println(
    "benchmark：实测扫描（比赛数/规则数/冲突数/投稿包数/耗时）",
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
  println("比赛列表：")
  for i in 0..<comps.length() {
    println("  - \{comps[i].name}")
  }
}

///|
fn cmd_list() -> Unit {
  let comps = @lib.all_competitions()
  println("-- 比赛台账（12 个，按截止排序）--")
  for i in 0..<comps.length() {
    let c = comps[i]
    println(
      "\{i + 1}. \{c.name} | 截止 \{c.deadline} | \{c.prize} | 状态：\{c.status}",
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
    println("用法：pack <作品名> <比赛名>")
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
          println("未找到比赛：\{args[2]}")
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
/// 实测扫描：先跑一轮全量扫描数真实结果（全部作品 × 全部比赛的
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
    // 每件作品 × 每场比赛评估 2 条规则：首次发布 / 须新做
    rule_checks = rule_checks + comps.length() * 2
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
  println("比赛数：\{comps.length()}")
  println("作品数：\{works.length()}")
  println(
    "规则评估：\{rule_checks} 次/轮（每作品 × 每比赛 2 条规则）",
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
