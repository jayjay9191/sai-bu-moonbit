///|
/// Entry point for the CLI. Runs the whole pipeline and prints results:
/// 比赛台账 -> 冲突检测 -> 截止撞期提醒 -> 投稿包生成。
/// Run with `moon run cmd/main` from the project root.
fn main {
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
