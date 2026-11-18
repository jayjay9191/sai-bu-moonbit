///|
/// Checks the entry point and the default size/path limits documented by itch.io.
/// Decimal MB is the conservative interpretation of the documented unit.
pub fn itch_zip_issues(
  count : Int64,
  total : Int64,
  largest : Int64,
  longest : Int64,
  has_index : Bool,
) -> Array[String] {
  let issues = []
  if count <= 0L || largest < 0L || total < largest || longest < 1L {
    issues.push("ZIP 清单无效")
    return issues
  }
  if !has_index {
    issues.push("缺少区分大小写的根目录 index.html")
  }
  if count > 1000L {
    issues.push("文件数超过 1000")
  }
  if total > 500000000L {
    issues.push("解包总大小超过 500 MB")
  }
  if largest > 200000000L {
    issues.push("单文件解包大小超过 200 MB")
  }
  if longest > 240L {
    issues.push("最长相对路径超过 240 字符")
  }
  issues
}
