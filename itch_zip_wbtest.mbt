///|
test "itch ZIP thresholds are inclusive and root entry is required" {
  assert_eq(
    itch_zip_issues(1000L, 500000000L, 200000000L, 240L, true).length(),
    0,
  )
  assert_eq(
    itch_zip_issues(1001L, 500000001L, 200000001L, 241L, false).length(),
    5,
  )
  assert_true(
    itch_zip_issues(14L, 889183L, 817816L, 21L, false)[0].contains("index.html"),
  )
}
