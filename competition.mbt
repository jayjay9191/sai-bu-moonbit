///|
/// 比赛台账的结构定义与按名查找。
/// 数据不在这里：12 个比赛 + 3 件作品的真实数据在 data/competitions.json，
/// 由 scripts/generate_data.py 生成 competition_data.mbt。
/// 改数据只改 JSON，改完跑：python3 scripts/generate_data.py

///|
pub(all) struct Competition {
  name : String
  deadline : String // 人类可读的截止，如 "2026-12-01 12:00（报名）/ 18:00（提交）"
  deadline_date : String // 机器可比的日期 "YYYY-MM-DD"，用于撞期检测
  prize : String
  track : String
  status : String
  requires_first_publish : Bool // 要求活动期间首次公开发布（如魔搭）
  requires_new_work : Bool // 要求必须新做（如知乎 S3）
  allows_existing_works : Bool // 明确已有成品可参赛（如松江）
  materials : Array[String] // 投稿需要的材料清单
  note : String // 核实状态与备注
}

///|
pub enum WorkKind {
  Game
  Tool
}

///|
pub(all) struct Work {
  name : String
  kind : WorkKind
  oneliner : String
  first_public_date : String // 首次公开时间；"" 表示未公开
  submitted_to : Array[String] // 已投过的比赛
  materials_ready : Array[String] // 已就绪的材料
  note : String
}

///|
pub fn work_by_name(name : String) -> Work? {
  let works = all_works()
  for i in 0..<works.length() {
    if works[i].name == name {
      return Some(works[i])
    }
  }
  None
}

///|
pub fn competition_by_name(name : String) -> Competition? {
  let comps = all_competitions()
  for i in 0..<comps.length() {
    if comps[i].name == name {
      return Some(comps[i])
    }
  }
  None
}
