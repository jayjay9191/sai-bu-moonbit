///|
fn cmd_calendar(args : Array[String]) -> Unit {
  try {
    let has_date = args.length() > 1 && args[1] != "--days"
    let date = if has_date {
      args[1]
    } else {
      @lib.today_string(@env.now() + 28800000UL)
    }
    let next = if has_date { 2 } else { 1 }
    let days = if args.length() == next {
      None
    } else {
      if args.length() != next + 2 || args[next] != "--days" {
        fail("用法：calendar [YYYY-MM-DD] [--days 天数]")
      }
      let raw = args[next + 1]
      if raw.is_empty() || !raw.to_array().iter().all(ch => ch.is_ascii_digit()) {
        fail("--days 须为正整数")
      }
      let value = @string.parse_int64(raw)
      if value <= 0L || value > 2147483647L {
        fail("--days 须为正整数")
      }
      Some(value.to_int())
    }
    let calendar = @lib.deadline_calendar(@lib.all_competitions(), date, days~)
    @async.run_async_main(async fn() {
      @stdio.stdout.write(@utf8.encode(calendar)) catch {
        _ => {
          eprintln("日历输出失败")
          @env.exit(2)
        }
      }
    })
  } catch {
    err => {
      eprintln("日历导出失败：" + err.to_string())
      @env.exit(2)
    }
  }
}
