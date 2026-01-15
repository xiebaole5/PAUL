# Windows 依赖安装脚本
# 使用方法: 在 PowerShell 中执行: .\install-deps.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "天虹紧固件项目 - 安装核心依赖包" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 使用阿里云镜像加速
$mirror = "https://mirrors.aliyun.com/pypi/simple/"

Write-Host "[1/4] 安装 Web 框架..." -ForegroundColor Yellow
pip install fastapi==0.121.2 uvicorn==0.38.0 python-multipart starlette -i $mirror

Write-Host "[2/4] 安装 AI 框架..." -ForegroundColor Yellow
pip install langchain==1.0.3 langchain-core langchain-openai==1.0.1 langgraph==1.0.2 -i $mirror

Write-Host "[3/4] 安装视频处理..." -ForegroundColor Yellow
pip install moviepy==2.2.1 opencv-python pillow -i $mirror

Write-Host "[4/4] 安装工具库..." -ForegroundColor Yellow
pip install requests httpx pydantic python-dotenv boto3 coze-coding-dev-sdk coze-coding-utils coze-workload-identity -i $mirror

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "依赖安装完成！" -ForegroundColor Green
Write-Host "现在可以运行: python src\main.py" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
