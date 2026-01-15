# 简化版依赖安装（不指定具体版本）
cd C:\PAUL

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "简化版依赖安装" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$mirror = "https://mirrors.aliyun.com/pypi/simple/"

Write-Host "正在安装依赖..." -ForegroundColor Yellow
python -m pip install langchain langchain-openai langgraph fastapi uvicorn python-multipart moviepy opencv-python requests httpx pydantic python-dotenv boto3 coze-coding-dev-sdk coze-coding-utils coze-workload-identity -i $mirror --upgrade --ignore-installed numpy

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "安装完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
