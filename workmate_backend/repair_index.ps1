$header = Get-Content "d:\TTTN\workmate_backend\index_header.txt"
$content = Get-Content "d:\TTTN\workmate_backend\index.js"
$rest = $content[91..($content.Length-1)]
$final = $header + $rest
$final | Set-Content "d:\TTTN\workmate_backend\index.js" -Encoding UTF8
