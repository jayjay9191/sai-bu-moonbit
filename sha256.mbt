///|
/// SHA-256（FIPS 180-4），纯 MoonBit 实现。
/// MoonBit core 没有 crypto 包（grep 过，无 sha256）；
/// Auto-Lexmount 用 Python hashlib，这里按标准算法自己写，
/// 测试向量用 Python hashlib 对过（见测试）。
/// 输入先按 UTF-8 编码（@encoding/utf8），输出 64 位小写十六进制。
fn rotr32(x : UInt32, n : Int32) -> UInt32 {
  (x >> n) | (x << (32 - n))
}

///|
fn hex8(x : UInt32) -> String {
  let s = x.to_string(radix=16)
  if s.length() >= 8 {
    s
  } else {
    "0".repeat(8 - s.length()) + s
  }
}

///|
/// 对字符串算 SHA-256（UTF-8 编码后），返回 64 位小写十六进制。
/// 空串的摘要是 e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855。
pub fn sha256_hex(input : String) -> String {
  // K 常量表：MoonBit 的 const 只允许原始类型，数组只能放函数里。
  let k : Array[UInt32] = [
    0x428a2f98U, 0x71374491U, 0xb5c0fbcfU, 0xe9b5dba5U, 0x3956c25bU, 0x59f111f1U,
    0x923f82a4U, 0xab1c5ed5U, 0xd807aa98U, 0x12835b01U, 0x243185beU, 0x550c7dc3U,
    0x72be5d74U, 0x80deb1feU, 0x9bdc06a7U, 0xc19bf174U, 0xe49b69c1U, 0xefbe4786U,
    0x0fc19dc6U, 0x240ca1ccU, 0x2de92c6fU, 0x4a7484aaU, 0x5cb0a9dcU, 0x76f988daU,
    0x983e5152U, 0xa831c66dU, 0xb00327c8U, 0xbf597fc7U, 0xc6e00bf3U, 0xd5a79147U,
    0x06ca6351U, 0x14292967U, 0x27b70a85U, 0x2e1b2138U, 0x4d2c6dfcU, 0x53380d13U,
    0x650a7354U, 0x766a0abbU, 0x81c2c92eU, 0x92722c85U, 0xa2bfe8a1U, 0xa81a664bU,
    0xc24b8b70U, 0xc76c51a3U, 0xd192e819U, 0xd6990624U, 0xf40e3585U, 0x106aa070U,
    0x19a4c116U, 0x1e376c08U, 0x2748774cU, 0x34b0bcb5U, 0x391c0cb3U, 0x4ed8aa4aU,
    0x5b9cca4fU, 0x682e6ff3U, 0x748f82eeU, 0x78a5636fU, 0x84c87814U, 0x8cc70208U,
    0x90befffaU, 0xa4506cebU, 0xbef9a3f7U, 0xc67178f2U,
  ]
  let bytes = @utf8.encode(input)
  let len = bytes.length()
  let bitlen_lo : UInt32 = len.reinterpret_as_uint() << 3
  let bitlen_hi : UInt32 = len.reinterpret_as_uint() >> 29
  // 填充后长度：原长 + 0x80（1 字节）+ 8 字节长度，补 0 到 64 的倍数。
  let padded_len = (len + 1 + 8 + 63) / 64 * 64
  let msg : Array[UInt32] = []
  for i in 0..<padded_len {
    if i < len {
      msg.push(bytes[i].to_uint())
    } else if i == len {
      msg.push(0x80U)
    } else if i >= padded_len - 8 {
      let j = i - (padded_len - 8)
      if j < 4 {
        msg.push((bitlen_hi >> ((3 - j) * 8)) & 0xFFU)
      } else {
        msg.push((bitlen_lo >> ((7 - j) * 8)) & 0xFFU)
      }
    } else {
      msg.push(0U)
    }
  }
  let h : Array[UInt32] = [
    0x6a09e667U, 0xbb67ae85U, 0x3c6ef372U, 0xa54ff53aU, 0x510e527fU, 0x9b05688cU,
    0x1f83d9abU, 0x5be0cd19U,
  ]
  let mut chunk_start = 0
  while chunk_start < padded_len {
    let w : Array[UInt32] = []
    for _i in 0..<64 {
      w.push(0U)
    }
    for i in 0..<16 {
      let o = chunk_start + i * 4
      w[i] = (msg[o] << 24) |
        (msg[o + 1] << 16) |
        (msg[o + 2] << 8) |
        msg[o + 3]
    }
    for i in 16..<64 {
      let s0 = rotr32(w[i - 15], 7) ^ rotr32(w[i - 15], 18) ^ (w[i - 15] >> 3)
      let s1 = rotr32(w[i - 2], 17) ^ rotr32(w[i - 2], 19) ^ (w[i - 2] >> 10)
      w[i] = w[i - 16] + s0 + w[i - 7] + s1
    }
    let mut a = h[0]
    let mut b = h[1]
    let mut c = h[2]
    let mut d = h[3]
    let mut e = h[4]
    let mut f = h[5]
    let mut g = h[6]
    let mut hh = h[7]
    for i in 0..<64 {
      let big_s1 = rotr32(e, 6) ^ rotr32(e, 11) ^ rotr32(e, 25)
      let ch = (e & f) ^ ((0xFFFFFFFFU ^ e) & g)
      let temp1 = hh + big_s1 + ch + k[i] + w[i]
      let big_s0 = rotr32(a, 2) ^ rotr32(a, 13) ^ rotr32(a, 22)
      let maj = (a & b) ^ (a & c) ^ (b & c)
      let temp2 = big_s0 + maj
      hh = g
      g = f
      f = e
      e = d + temp1
      d = c
      c = b
      b = a
      a = temp1 + temp2
    }
    h[0] = h[0] + a
    h[1] = h[1] + b
    h[2] = h[2] + c
    h[3] = h[3] + d
    h[4] = h[4] + e
    h[5] = h[5] + f
    h[6] = h[6] + g
    h[7] = h[7] + hh
    chunk_start = chunk_start + 64
  }
  let mut out = ""
  for i in 0..<8 {
    out = out + hex8(h[i])
  }
  out
}
