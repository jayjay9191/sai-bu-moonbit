///|
fn cmd_calendar(args : Array[String]) -> Unit {
  try {
    if args.length() > 2 {
      fail("用法：calendar [YYYY-MM-DD]")
    }
    let date = if args.length() == 2 {
      args[1]
    } else {
      @lib.today_string(@env.now() + 28800000UL)
    }
    let calendar = @lib.deadline_calendar(@lib.all_competitions(), date)
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
