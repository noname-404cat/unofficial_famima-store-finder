# snapshot.awk — stores_uniq.tsv から stores.js（同梱スナップショット）を生成
BEGIN {
  FS = "\t"
  printf "window.FAMIMA_DATA={label:\"シクフォニチップスⅡ　うすしお味（7月7日現在・スナップショット）\",stores:["
}
function esc(s) { gsub(/\\/, "\\\\", s); gsub(/"/, "\\\"", s); return s }
{
  printf "%s{\"name\":\"%s\",\"pref\":\"%s\",\"postal\":\"%s\",\"addr\":\"%s\"}", (NR > 1 ? "," : ""), esc($1), esc($2), esc($3), esc($4)
}
END { printf "]};\n" }
