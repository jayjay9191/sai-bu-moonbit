///|
fn calendar_text(s : String) -> String {
  s
  .replace_all(old="\\", new="\\\\")
  .replace_all(old="\r\n", new="\n")
  .replace_all(old="\r", new="\n")
  .replace_all(old="\n", new="\\n")
  .replace_all(old=";", new="\\;")
  .replace_all(old=",", new="\\,")
}

///|
/// RFC 5545 folds on UTF-8 character boundaries, counting octets.
fn calendar_line(out : StringBuilder, text : String) -> Unit {
  let mut width = 0
  for ch in text.to_array() {
    let value = ch.to_string()
    let bytes = @utf8.encode(value).length()
    if width + bytes > 75 {
      out.write_string("\r\n ")
      width = 1
    }
    out.write_string(value)
    width += bytes
  }
  out.write_string("\r\n")
}

///|
fn explicit_stage_date(segment : String) -> String? {
  let date = segment.clamped_view(end=10).to_owned()
  let suffix = segment.clamped_view(start=10).to_owned()
  if is_valid_date(date) &&
    !suffix.contains("待定") &&
    !suffix.contains("暂定") &&
    (
      suffix.is_empty() ||
      suffix.has_prefix(" ") ||
      suffix.has_prefix("（") ||
      suffix.has_prefix("(")
    ) {
    Some(date)
  } else {
    None
  }
}

///|
// Times without a full date stay in the source description.
fn recorded_deadline_dates(comp : Competition) -> Array[String] {
  let first = comp.deadline_date
  if !is_valid_date(first) {
    return []
  }
  let dates = [first]
  let parts = comp.deadline
    .split("/")
    .map(part => part.trim().to_owned())
    .to_array()
  if explicit_stage_date(parts[0]) != Some(first) {
    return dates
  }
  for i in 1..<parts.length() {
    if explicit_stage_date(parts[i]) is Some(date) &&
      date > first &&
      !dates.contains(date) {
      dates.push(date)
    }
  }
  dates
}

///|
/// Export an all-day reminder for each verified upcoming stage with a recorded date.
/// Keep the source deadline wording in DESCRIPTION, including staged times.
pub fn deadline_calendar(
  comps : Array[Competition],
  as_of : String,
) -> String raise {
  if !is_valid_date(as_of) || date_to_days(as_of) < 0 {
    fail("calendar date must be YYYY-MM-DD on or after 1970-01-01")
  }
  let today = date_to_days(as_of)
  let stamp = as_of.replace_all(old="-", new="") + "T000000Z"
  let out = StringBuilder()
  for
    line in [
      "BEGIN:VCALENDAR", "VERSION:2.0", "PRODID:-//Sai Bu//Deadline reminders//ZH",
    ] {
    calendar_line(out, line)
  }
  for comp in comps {
    for stage_date in recorded_deadline_dates(comp) {
      if !row_verdict({ ..comp, deadline_date: stage_date, }, today).verified {
        continue
      }
      let later = stage_date != comp.deadline_date
      let date = stage_date.replace_all(old="-", new="")
      let key = if later { comp.name + "\n" + stage_date } else { comp.name }
      let uid = sha256_hex(key) + "@sai-bu.invalid"
      let summary = calendar_text(
        if later {
          comp.name + "（后续截止）"
        } else {
          comp.name
        },
      )
      let details = calendar_text("台账截止原文：" + comp.deadline)
      for
        line in [
          "BEGIN:VEVENT",
          "UID:" + uid,
          "DTSTAMP:" + stamp,
          "DTSTART;VALUE=DATE:" + date,
          "TRANSP:TRANSPARENT",
          "SUMMARY:" + summary,
          "DESCRIPTION:" + details,
          "END:VEVENT",
        ] {
        calendar_line(out, line)
      }
    }
  }
  calendar_line(out, "END:VCALENDAR")
  out.to_string()
}
