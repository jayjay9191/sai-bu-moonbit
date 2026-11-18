///|
/// 比赛台账的结构定义与按名查找。
/// 数据不在这里：21 个投稿目标（19 个比赛 + 2 个平台上架）+ 4 件作品
/// 的真实数据在 data/competitions.json，
/// 由 scripts/generate_data.py 生成 competition_data.mbt。
/// 改数据只改 JSON，改完跑：python3 scripts/generate_data.py

///|
pub(all) struct Competition {
  name : String
  target_kind : String // "比赛" 或 "平台上架"：台账不只管比赛，也管作品投稿目标
  deadline : String // 人类可读的截止，如 "2026-12-01 12:00（报名）/ 18:00（提交）"；平台上架目标为 "常年开放，无截止"
  deadline_date : String // 机器可比的日期 "YYYY-MM-DD"，用于撞期检测；平台上架目标为空（无截止，不参与撞期）
  publish_start : String // 首次公开窗口起日（含）；空表示未知
  publish_end : String // 首次公开窗口止日（含）；空表示未知
  verified_at : String // 该行截止/奖金最后一次对照官方来源核实的日期 "YYYY-MM-DD"
  prize : String
  track : String
  status : String // 投稿进度，如“未报名”“已投 3 件，均审核中”
  plan_status : String // 计划状态：“在途”（12 个正式计划内）或“关注”（只看、不主动推进）
  requires_first_publish : Bool // 要求活动期间首次公开发布（如魔搭）
  requires_new_work : Bool // 要求必须新做（如知乎 S3）
  requires_no_prior_entry : Bool // 要求未参加过其他国家级公开比赛（如软件创新大赛原创条款）
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
