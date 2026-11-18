///|
/// 投稿包生成：选一件作品 + 一个比赛，输出可直接照着交的材料清单。
/// 与 Auto-Lexmount 的区别：它只做单比赛的报告生成；这里是多比赛适配，
/// 同一件作品投不同比赛，标题格式、材料清单、缺口都会跟着变，
/// 且 P0 冲突会直接把投稿包标为“ blocked”，而不是悄悄交上去。

///|
pub struct SubmissionPack {
  work : String
  competition : String
  title : String
  oneliner : String
  materials : Array[String]
  ready : Array[String]
  gaps : Array[String]
  blocked : Bool
  note : String
}

///|
pub fn generate_pack(
  work : Work,
  comp : Competition,
  conflicts : Array[Conflict],
) -> SubmissionPack {
  let ready : Array[String] = []
  let gaps : Array[String] = []
  for i in 0..<comp.materials.length() {
    let m = comp.materials[i]
    if contains_string(work.materials_ready, m) {
      ready.push(m)
    } else {
      gaps.push(m)
    }
  }
  let blocked = has_p0_conflict(conflicts, comp.name)
  let note = if blocked {
    "⛔ 存在 P0 冲突，提交前必须先解决（见冲突检测）"
  } else if gaps.length() > 0 {
    "材料缺口 \{gaps.length()} 项，先补齐再交"
  } else if comp.requires_first_publish &&
    first_publish_decision(work, comp).0 == "P1" {
    "材料齐全，首次发布资格待核实"
  } else {
    "材料齐全，仍需通过预检"
  }
  {
    work: work.name,
    competition: comp.name,
    title: "[" + work.name + "] " + work.oneliner,
    oneliner: work.oneliner,
    materials: comp.materials,
    ready,
    gaps,
    blocked,
    note,
  }
}
