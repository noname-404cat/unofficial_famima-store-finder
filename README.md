# ファミマ キャンペーン店舗ファインダー

ファミリーマートのキャンペーン対象店舗（シクフォニチップスⅡ）を、都道府県・駅名・現在地から探せるダッシュボード。
ローラー作戦用に、店舗ごとの巡回チェック（未確認 → ❌なし → ✅ゲット）を記録できます。

## 使い方

1. **都道府県を選ぶ** → 対象店舗が一覧表示される
2. **駅名か住所を入れて「距離順に表示」**（または「📍現在地から」）→ 近い順に並び、地図にも表示される
3. 各店舗の **🗺 開く** で Googleマップが開く
4. 巡回したら **チェック列をクリック**して記録（ブラウザに保存され、次回も残る）
5. **CSVエクスポート**で一覧を保存できる

列「最寄り駅（候補）」は住所の座標から直線距離で算出した目安です（徒歩経路とは異なります）。

## データの更新方法

店舗一覧は [Googleスプレッドシート](https://docs.google.com/spreadsheets/d/1RL7WpDKXXkp0sSwzw-bJX8XZUFmnlsH811mM4294QMg/edit?gid=0) を**ページを開くたびに直接読み込みます**。

- 新しい店舗一覧をもらったら、**シートに貼り付けるだけ**（列: 店名 / 都道府県 / 郵便番号 / 住所。タイトル行や※注意書きが混ざっていても自動でスキップ）
- 開いているページには「🔄 最新データ再取得」ボタンでも反映できる
- シートの共有設定は「リンクを知っている全員が閲覧可」を維持すること

新store（事前計算にない住所）は表示時に自動で座標・最寄り駅を取得するので、下記の再生成は必須ではありません。

## ファイル構成

| ファイル | 内容 |
|---|---|
| `index.html` | ダッシュボード本体（単一ファイル） |
| `stores.js` | 店舗一覧のスナップショット（シートが読めない時のフォールバック） |
| `geo.js` | 全店舗の座標+最寄り駅の事前計算キャッシュ |
| `serve.ps1` | ローカル確認用の簡易サーバ（`powershell -File serve.ps1` → http://localhost:8765/） |
| `tools/` | データ再生成スクリプト（下記） |

## 事前計算データ（geo.js / stores.js）の再生成

店舗が大幅に入れ替わったときに実行（Git Bash 推奨）:

```bash
# 1. シートをTSV化（店名/都道府県/郵便番号/住所、ヘッダ・重複除去済みの4列TSVを用意）
#    → stores_uniq.tsv

# 2. ジオコーディング（GSI住所検索API・追記式なので中断/再開可）
powershell -File tools/geocode_slice.ps1 -InFile stores_uniq.tsv -OutFile geo_all.tsv

# 3. 最寄り駅を計算して geo.js を生成
LC_ALL=C.UTF-8 awk -f tools/nearest.awk tools/stations_flat.tsv geo_all.tsv > geo.js

# 4. スナップショット stores.js を生成
LC_ALL=C.UTF-8 awk -f tools/snapshot.awk stores_uniq.tsv > stores.js
```

`tools/stations_flat.tsv`（駅名・座標・路線名）の出典は
[open-data-jp-railway-stations](https://github.com/piuccio/open-data-jp-railway-stations) /
[open-data-jp-railway-lines](https://github.com/piuccio/open-data-jp-railway-lines)（ekidata.jp 由来）。

## 利用API・データ（すべて無料枠）

- 住所→座標: [国土地理院 住所検索API](https://msearch.gsi.go.jp/address-search/AddressSearch)
- 駅名検索・現在地の最寄り駅: [HeartRails Express API](https://express.heartrails.com/api.html)
- 地図タイル: [地理院地図](https://maps.gsi.go.jp/development/ichiran.html)
- 地図表示: [Leaflet](https://leafletjs.com/)
