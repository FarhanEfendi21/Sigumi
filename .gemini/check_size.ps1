$totalSize = (Get-ChildItem -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
Write-Host ""
Write-Host "=== TOTAL APPLICATION SIZE ==="
Write-Host ("Total Files: " + (Get-ChildItem -Recurse -File -ErrorAction SilentlyContinue).Count)
Write-Host ("Total Size: {0:N2} MB ({1:N2} GB)" -f ($totalSize/1MB), ($totalSize/1GB))
Write-Host ""
Write-Host "=== SIZE PER FOLDER ==="

foreach ($dir in Get-ChildItem -Directory -ErrorAction SilentlyContinue) {
    $size = (Get-ChildItem $dir.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    $fileCount = (Get-ChildItem $dir.FullName -Recurse -File -ErrorAction SilentlyContinue).Count
    Write-Host ("{0,-30} {1,10:N2} MB   ({2} files)" -f $dir.Name, ($size/1MB), $fileCount)
}
