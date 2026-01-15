# 检查 Python 版本详情
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Python 版本检查" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1] WindowsApps Python:" -ForegroundColor Yellow
& "C:\Users\12187\AppData\Local\Microsoft\WindowsApps\python.exe" --version
Write-Host ""

Write-Host "[2] Local Python:" -ForegroundColor Yellow
& "C:\Users\12187\AppData\Local\Python\bin\python.exe" --version
Write-Host ""

Write-Host "[3] 检查 langchain 在哪个版本中:" -ForegroundColor Yellow
Write-Host "WindowsApps Python:"
& "C:\Users\12187\AppData\Local\Microsoft\WindowsApps\python.exe" -c "import langchain; print('  langchain 已安装')" 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "  langchain 未安装" -ForegroundColor Red
}
Write-Host ""
Write-Host "Local Python:"
& "C:\Users\12187\AppData\Local\Python\bin\python.exe" -c "import langchain; print('  langchain 已安装')" 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "  langchain 未安装" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "检查完成！" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
