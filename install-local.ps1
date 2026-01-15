# 使用 Local Python 安装依赖
cd C:\PAUL

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "为 Local Python 安装依赖包" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$pythonPath = "C:\Users\12187\AppData\Local\Python\bin\python.exe"
$mirror = "https://mirrors.aliyun.com/pypi/simple/"

Write-Host "正在安装核心依赖..." -ForegroundColor Yellow
& $pythonPath -m pip install langchain==1.0.3 langchain-core langchain-openai==1.0.1 langgraph==1.0.2 fastapi uvicorn python-multipart moviepy opencv-python requests httpx pydantic python-dotenv boto3 coze-coding-dev-sdk coze-coding-utils coze-workload-identity -i $mirror

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "安装完成！" -ForegroundColor Green
Write-Host "现在可以运行: run-server.bat" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
