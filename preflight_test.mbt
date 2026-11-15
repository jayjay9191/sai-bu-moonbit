///|
/// preflight / SHA-256 的测试。
/// SHA-256 向量用 Python hashlib 算出（2026-11-15），不是手写的；
/// 日期向量用 Python datetime 对过（2026-11-15 = 自 1970-01-01 起 20772 天）。

///|
/// 测试用比赛夹具：除指定字段外均为合法值。
fn fixture_competition(
  name : String,
  deadline : String,
  deadline_date : String,
  verified_at : String,
  prize : String,
  note : String,
) -> @sai-chang-guan-jia-moonbit.Competition {
  {
    name,
    deadline,
    deadline_date,
    verified_at,
    prize,
    track: "测试",
    status: "测试",
    plan_status: "在途",
    requires_first_publish: false,
    requires_new_work: false,
    requires_no_prior_entry: false,
    allows_existing_works: false,
    materials: ["材料 A"],
    note,
  }
}

///|
/// 测试用作品夹具。WorkKind 构造子不对黑盒测试开放，从已有作品借 kind。
fn fixture_work(
  name : String,
  first_public_date : String,
  submitted_to : Array[String],
  materials_ready : Array[String],
) -> @sai-chang-guan-jia-moonbit.Work {
  let base = @sai-chang-guan-jia-moonbit.all_works()[0]
  {
    name,
    kind: base.kind,
    oneliner: "测试用作品",
    first_public_date,
    submitted_to,
    materials_ready,
    note: "",
  }
}

///|
test "sha256 of empty string" {
  assert_eq(
    @sai-chang-guan-jia-moonbit.sha256_hex(""),
    "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
  )
}

///|
test "sha256 of abc" {
  assert_eq(
    @sai-chang-guan-jia-moonbit.sha256_hex("abc"),
    "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
  )
}

///|
/// 56 字节输入：填充恰好跨一个块边界（56 + 1 + 8 = 65 > 64）。
test "sha256 of 56-byte input" {
  assert_eq(
    @sai-chang-guan-jia-moonbit.sha256_hex(
      "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq",
    ),
    "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1",
  )
}

///|
test "sha256 of quick brown fox" {
  assert_eq(
    @sai-chang-guan-jia-moonbit.sha256_hex(
      "The quick brown fox jumps over the lazy dog",
    ),
    "d7a8fbb307d7809469ca9abcb0082e4f8d5651e46d3cdb762d02d0bf37c9e592",
  )
}

///|
test "sha256 of 64-byte input" {
  assert_eq(
    @sai-chang-guan-jia-moonbit.sha256_hex("a".repeat(64)),
    "ffe054fe7ae0cb6dc65c3af9b61d5209f439851db43d0ba5997337df154668eb",
  )
}

///|
/// 55 字节：填充后恰好一个块。
test "sha256 of 55-byte input" {
  assert_eq(
    @sai-chang-guan-jia-moonbit.sha256_hex("a".repeat(55)),
    "9f4390f8d30c2dd92ec9f095b65e2b9ae9b0a925a5258e241c9f1e910f734318",
  )
}

///|
test "sha256 of 56-byte a input" {
  assert_eq(
    @sai-chang-guan-jia-moonbit.sha256_hex("a".repeat(56)),
    "b35439a4ac6f0948b6d6f9e3c6af0f5f590ce20f1bde7090ef7970686ec6738a",
  )
}

///|
/// 119 字节：跨两个块。
test "sha256 of 119-byte input" {
  assert_eq(
    @sai-chang-guan-jia-moonbit.sha256_hex("a".repeat(119)),
    "31eba51c313a5c08226adf18d4a359cfdfd8d2e816b13f4af952f7ea6584dcfb",
  )
}

///|
test "sha256 output is 64 hex chars and deterministic" {
  let h1 = @sai-chang-guan-jia-moonbit.sha256_hex("参赛管家")
  let h2 = @sai-chang-guan-jia-moonbit.sha256_hex("参赛管家")
  assert_eq(h1.length(), 64)
  assert_eq(h1, h2)
}

///|
test "sha256 differs for different inputs" {
  assert_true(
    @sai-chang-guan-jia-moonbit.sha256_hex("a") !=
    @sai-chang-guan-jia-moonbit.sha256_hex("b"),
  )
}

///|
test "date_to_days vectors" {
  assert_eq(@sai-chang-guan-jia-moonbit.date_to_days("1970-01-01"), 0)
  assert_eq(@sai-chang-guan-jia-moonbit.date_to_days("2000-01-01"), 10957)
  assert_eq(@sai-chang-guan-jia-moonbit.date_to_days("2026-11-13"), 20770)
  assert_eq(@sai-chang-guan-jia-moonbit.date_to_days("2026-11-15"), 20772)
}

///|
test "date_to_days rejects invalid dates" {
  assert_eq(@sai-chang-guan-jia-moonbit.date_to_days("2026-13-01"), -1)
  assert_eq(@sai-chang-guan-jia-moonbit.date_to_days(""), -1)
  assert_eq(@sai-chang-guan-jia-moonbit.date_to_days("2026/12/01"), -1)
}

///|
test "civil_from_days vectors" {
  assert_eq(@sai-chang-guan-jia-moonbit.civil_from_days(0), (1970, 1, 1))
  assert_eq(
    @sai-chang-guan-jia-moonbit.civil_from_days(10957),
    (2000, 1, 1),
  )
  assert_eq(
    @sai-chang-guan-jia-moonbit.civil_from_days(20772),
    (2026, 11, 15),
  )
}

///|
test "date round-trip" {
  let days = @sai-chang-guan-jia-moonbit.date_to_days("2027-01-28")
  assert_eq(@sai-chang-guan-jia-moonbit.civil_from_days(days), (2027, 1, 28))
  let days2 = @sai-chang-guan-jia-moonbit.date_to_days("2026-02-28")
  assert_eq(
    @sai-chang-guan-jia-moonbit.civil_from_days(days2),
    (2026, 2, 28),
  )
}

///|
/// 核验过期边界：距今 30 天不算过期（STALE_DAYS = 30，超过才过期）。
test "row verdict fresh at exactly 30 days" {
  let today = @sai-chang-guan-jia-moonbit.date_to_days("2026-11-15")
  let c = fixture_competition(
    "测试比赛",
    "2026-12-01",
    "2026-12-01",
    "2026-10-16",
    "¥0",
    "",
  )
  let v = @sai-chang-guan-jia-moonbit.row_verdict(c, today)
  assert_true(v.verified)
}

///|
test "row verdict stale at 31 days" {
  let today = @sai-chang-guan-jia-moonbit.date_to_days("2026-11-15")
  let c = fixture_competition(
    "测试比赛",
    "2026-12-01",
    "2026-12-01",
    "2026-10-15",
    "¥0",
    "",
  )
  let v = @sai-chang-guan-jia-moonbit.row_verdict(c, today)
  assert_true(!v.verified)
  assert_true(v.reason.contains("核验过期"))
}

///|
test "row verdict flags unverified marker in note" {
  let today = @sai-chang-guan-jia-moonbit.date_to_days("2026-11-15")
  let c = fixture_competition(
    "测试比赛",
    "2026-12-01",
    "2026-12-01",
    "2026-11-13",
    "¥0",
    "奖金未核实",
  )
  let v = @sai-chang-guan-jia-moonbit.row_verdict(c, today)
  assert_true(!v.verified)
  assert_true(v.reason.contains("未核实"))
}

///|
test "row verdict flags unverified marker in deadline display" {
  let today = @sai-chang-guan-jia-moonbit.date_to_days("2026-11-15")
  let c = fixture_competition(
    "测试比赛",
    "2026-12-01（待核对）",
    "2026-12-01",
    "2026-11-13",
    "¥0",
    "",
  )
  let v = @sai-chang-guan-jia-moonbit.row_verdict(c, today)
  assert_true(!v.verified)
}

///|
test "row verdict flags past deadline" {
  let today = @sai-chang-guan-jia-moonbit.date_to_days("2026-11-15")
  let c = fixture_competition(
    "测试比赛",
    "2026-11-01",
    "2026-11-01",
    "2026-11-13",
    "¥0",
    "",
  )
  let v = @sai-chang-guan-jia-moonbit.row_verdict(c, today)
  assert_true(!v.verified)
  assert_true(v.reason.contains("已过截止"))
}

///|
test "manifest hash is deterministic and 64 chars" {
  let comps = @sai-chang-guan-jia-moonbit.all_competitions()
  let works = @sai-chang-guan-jia-moonbit.all_works()
  let h1 = @sai-chang-guan-jia-moonbit.sha256_hex(
    @sai-chang-guan-jia-moonbit.manifest_canonical(comps, works),
  )
  let h2 = @sai-chang-guan-jia-moonbit.sha256_hex(
    @sai-chang-guan-jia-moonbit.manifest_canonical(comps, works),
  )
  assert_eq(h1.length(), 64)
  assert_eq(h1, h2)
}

///|
test "manifest hash changes when data changes" {
  let c1 = fixture_competition(
    "比赛 A",
    "2026-12-01",
    "2026-12-01",
    "2026-11-13",
    "¥0",
    "",
  )
  let c2 = fixture_competition(
    "比赛 B",
    "2026-12-02",
    "2026-12-02",
    "2026-11-13",
    "¥0",
    "",
  )
  let c2_changed = fixture_competition(
    "比赛 B",
    "2026-12-02",
    "2026-12-02",
    "2026-11-13",
    "¥999",
    "",
  )
  let w = fixture_work("作品 A", "2026-11-01", [], [])
  let h1 = @sai-chang-guan-jia-moonbit.sha256_hex(
    @sai-chang-guan-jia-moonbit.manifest_canonical([c1, c2], [w]),
  )
  let h2 = @sai-chang-guan-jia-moonbit.sha256_hex(
    @sai-chang-guan-jia-moonbit.manifest_canonical([c1, c2_changed], [w]),
  )
  assert_true(h1 != h2)
}

///|
/// 2026-11-15 00:00 UTC = 20772 天 × 86400000 毫秒。
/// 真实数据在这一天的预期：validate 0 个问题；19 行中 11 行已核实；
/// 57 个包可提交 2 个、P0 挡住 6 个；撞期 3 个日期。
test "preflight on real data at 2026-11-15" {
  let report = @sai-chang-guan-jia-moonbit.preflight(
    @sai-chang-guan-jia-moonbit.all_competitions(),
    @sai-chang-guan-jia-moonbit.all_works(),
    1794700800000UL,
  )
  assert_eq(report.today, "2026-11-15")
  assert_eq(report.validate_issues.length(), 0)
  assert_eq(report.rows.length(), 19)
  let mut verified_rows = 0
  for i in 0..<report.rows.length() {
    if report.rows[i].verified {
      verified_rows = verified_rows + 1
    }
  }
  assert_eq(verified_rows, 11)
  assert_eq(report.packs.length(), 57)
  assert_eq(report.certifiable_count, 2)
  assert_eq(report.blocked_count, 6)
  assert_eq(report.collisions.length(), 3)
  assert_eq(report.manifest_hash.length(), 64)
}

///|
test "preflight reports validate issues" {
  let bad = fixture_competition(
    "测试比赛",
    "2026-12-01",
    "2026-13-40",
    "2026-11-13",
    "¥0",
    "",
  )
  let report = @sai-chang-guan-jia-moonbit.preflight(
    [bad],
    @sai-chang-guan-jia-moonbit.all_works(),
    1794700800000UL,
  )
  assert_eq(report.validate_issues.length(), 1)
}

///|
test "certify dawn to moda is blocked with P0 and gaps" {
  match @sai-chang-guan-jia-moonbit.work_by_name("第零次黎明") {
    Some(dawn) =>
      match
        @sai-chang-guan-jia-moonbit.competition_by_name(
          "魔搭 AI+∞ 第三期「AI 造游戏」",
        ) {
        Some(moda) => {
          let conflicts = @sai-chang-guan-jia-moonbit.detect_conflicts(
            dawn,
            @sai-chang-guan-jia-moonbit.all_competitions(),
          )
          let row = @sai-chang-guan-jia-moonbit.row_verdict(
            moda,
            @sai-chang-guan-jia-moonbit.date_to_days("2026-11-15"),
          )
          let v = @sai-chang-guan-jia-moonbit.certify_pack(
            dawn,
            moda,
            conflicts,
            row,
          )
          assert_true(!v.certifiable)
          assert_true(v.blocked)
          assert_eq(v.reasons.length(), 2)
          assert_true(v.reasons[0].contains("P0 冲突"))
          assert_true(v.reasons[1].contains("材料缺口 3 项"))
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "certify xiaodian and suqiu to emerge are submittable" {
  let comps = @sai-chang-guan-jia-moonbit.all_competitions()
  match
    @sai-chang-guan-jia-moonbit.competition_by_name("支付宝智能体涌现奖") {
    Some(emerge) => {
      let row = @sai-chang-guan-jia-moonbit.row_verdict(
        emerge,
        @sai-chang-guan-jia-moonbit.date_to_days("2026-11-15"),
      )
      assert_true(row.verified)
      for name in ["小店日结", "诉求整理台"] {
        match @sai-chang-guan-jia-moonbit.work_by_name(name) {
          Some(w) => {
            let conflicts = @sai-chang-guan-jia-moonbit.detect_conflicts(
              w,
              comps,
            )
            let v = @sai-chang-guan-jia-moonbit.certify_pack(
              w,
              emerge,
              conflicts,
              row,
            )
            assert_true(v.certifiable)
            assert_eq(v.reasons.length(), 0)
          }
          None => assert_true(false)
        }
      }
    }
    None => assert_true(false)
  }
}
