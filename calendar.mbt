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
/// Export one all-day reminder per verified upcoming ledger date.
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
    if comp.deadline_date == "" || !row_verdict(comp, today).verified {
      continue
    }
    let date = comp.deadline_date.replace_all(old="-", new="")
    let uid = sha256_hex(comp.name) + "@sai-bu.invalid"
    let summary = calendar_text(comp.name)
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
  calendar_line(out, "END:VCALENDAR")
  out.to_string()
}
