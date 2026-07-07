param([string]$InFile, [string]$OutFile)
# GSI住所検索APIで住所→座標。追記式で再開可能。
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$done = @{}
if (Test-Path $OutFile) {
  foreach ($l in Get-Content $OutFile -Encoding UTF8) { $k = ($l -split "`t")[0]; $done[$k] = 1 }
}
$sw = New-Object System.IO.StreamWriter($OutFile, $true, (New-Object System.Text.UTF8Encoding($false)))
$sw.AutoFlush = $true
$rows = Get-Content $InFile -Encoding UTF8
$n = 0
foreach ($row in $rows) {
  $f = $row -split "`t"
  $pref = $f[1]; $addr = $f[3]
  $n++
  if ($done.ContainsKey($addr)) { continue }
  # 正規化: 全角数字→半角、ダッシュ類→-
  $q = $addr
  $map = "０1１1２2３3４4５5６6７7８8９9"  # dummy to avoid regex; use char translate below
  $sb = New-Object System.Text.StringBuilder
  foreach ($ch in $q.ToCharArray()) {
    $c = [int]$ch
    if ($c -ge 0xFF10 -and $c -le 0xFF19) { [void]$sb.Append([char]($c - 0xFEE0)) }
    elseif ($ch -eq [char]0x2212 -or $ch -eq [char]0xFF0D -or $ch -eq [char]0x2010 -or $ch -eq [char]0x2015) { [void]$sb.Append("-") }
    else { [void]$sb.Append($ch) }
  }
  $q = $sb.ToString()
  $cands = New-Object System.Collections.Generic.List[string]
  $cands.Add($q)
  if ($q.Contains([char]0x3000)) { $cands.Add(($q -split [char]0x3000)[0]) }
  $lat = ""; $lng = ""
  foreach ($cand in $cands) {
    try {
      $j = Invoke-RestMethod -TimeoutSec 20 ("https://msearch.gsi.go.jp/address-search/AddressSearch?q=" + [uri]::EscapeDataString($cand))
    } catch { $j = $null; Start-Sleep -Milliseconds 500 }
    if ($j -and $j.Count -gt 0) {
      $best = $null
      foreach ($item in $j) { if ($item.properties.title -and $item.properties.title.StartsWith($pref)) { $best = $item; break } }
      if (-not $best) { $best = $j[0] }
      $c = $best.geometry.coordinates
      $lng = $c[0]; $lat = $c[1]
      break
    }
    Start-Sleep -Milliseconds 100
  }
  $sw.WriteLine("$addr`t$lat`t$lng")
  Start-Sleep -Milliseconds 60
}
$sw.Close()
Write-Output "slice done: $InFile"
