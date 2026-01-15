# Python 环境诊断脚本
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Python 环境诊断" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1] Python 版本信息:" -ForegroundColor Yellow
python --version
Write-Host ""

Write-Host "[2] Python 执行路径:" -ForegroundColor Yellow
where python
Write-Host ""

Write-Host "[3] pip 执行路径:" -ForegroundColor Yellow
where pip
Write-Host ""

Write-Host "[4] langchain 安装位置:" -ForegroundColor Yellow
python -c "import langchain; print(langchain.__file__)" 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "  langchain 未找到！" -ForegroundColor Red
}
Write-Host ""

Write-Host "[5] Site-packages 路径:" -ForegroundColor Yellow
python -c "import site; print('\n'.join(site.getsitepackages()))"
Write-Host ""

Write-Host "[6] 用户 Site-packages 路径:" -ForegroundColor Yellow
python -c "import site; print(site.getusersitepackages())"
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "诊断完成！" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
