# nearest.awk — 各店舗の最寄り駅上位2件を計算し geo.js を出力
# 入力1: stations_flat.tsv (駅名 \t lat \t lng \t 路線名)
# 入力2: geo_final.tsv (住所 \t lat \t lng)
BEGIN { FS = "\t"; PI = 3.14159265358979; RAD = PI / 180 }

function esc(s) { gsub(/\\/, "\\\\", s); gsub(/"/, "\\\"", s); return s }

function havkm(lat1, lng1, lat2, lng2,   dlat, dlng, h) {
  dlat = (lat2 - lat1) * RAD; dlng = (lng2 - lng1) * RAD
  h = sin(dlat/2)^2 + cos(lat1*RAD) * cos(lat2*RAD) * sin(dlng/2)^2
  return 2 * 6371 * atan2(sqrt(h), sqrt(1-h))
}

function fmtdist(km) {
  if (km < 1) return "約" int(km * 1000 / 100 + 0.5) * 100 "m"
  return "約" int(km * 10 + 0.5) / 10 "km"
}

NR == FNR { ns++; sn[ns] = $1; sy[ns] = $2; sx[ns] = $3; sl[ns] = $4; next }

{
  addr = $1; lat = $2 + 0; lng = $3 + 0
  cl = cos(lat * RAD)
  b1 = 1e18; b2 = 1e18; i1 = 0; i2 = 0
  for (i = 1; i <= ns; i++) {
    dy = sy[i] - lat; dx = (sx[i] - lng) * cl
    d = dy*dy + dx*dx
    if (d < b1) { b2 = b1; i2 = i1; b1 = d; i1 = i }
    else if (d < b2) { b2 = d; i2 = i }
  }
  st = ""
  if (i1) {
    km1 = havkm(lat, lng, sy[i1], sx[i1])
    st = sn[i1] "駅" (sl[i1] != "" ? "(" sl[i1] ")" : "") " " fmtdist(km1)
    if (i2) {
      km2 = havkm(lat, lng, sy[i2], sx[i2])
      if (km2 < 3 || km2 < km1 * 2) st = st "／" sn[i2] "駅" (sl[i2] != "" ? "(" sl[i2] ")" : "") " " fmtdist(km2)
    }
  }
  if (!(addr in done)) {
    done[addr] = 1
    order[++n] = addr
    latm[addr] = lat
    lngm[addr] = lng
    stm[addr] = st
  }
}

END {
  printf "window.FAMIMA_GEO={"
  for (i = 1; i <= n; i++) {
    a = order[i]
    printf "%s\"%s\":[%.5f,%.5f,\"%s\"]", (i > 1 ? "," : ""), esc(a), latm[a], lngm[a], esc(stm[a])
  }
  printf "};\n"
}
