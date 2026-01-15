# 检查 langchain 安装情况
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "检查 langchain 安装位置" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1] WindowsApps Python:" -ForegroundColor Yellow
& "C:\Users\12187\AppData\Local\Microsoft\WindowsApps\python.exe" -c "import langchain; print(f'  langchain 版本: {langchain.__version__}'); print(f'  安装位置: {langchain.__file__}')" 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "  langchain 未安装" -ForegroundColor Red
} else {
    Write-Host "  ✅ langchain 已安装" -ForegroundColor Green
}
Write-Host ""

Write-Host "[2] Local Python:" -ForegroundColor Yellow
& "C:\Users\12187\AppData\Local\Python\bin\python.exe" -c "import langchain; print(f'  langchain 版本: {langchain.__version__}'); print(f'  安装位置: {langchain.__file__}')" 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "  langchain 未安装" -ForegroundColor Red
} else {
    Write-Host "  ✅ langchain 已安装" -ForegroundColor Green
}
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "检查完成！" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
