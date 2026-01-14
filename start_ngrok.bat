@echo off
chcp 65001 >nul
echo ==========================================
echo 启动ngrok隧道 (Windows)
echo ==========================================
echo.

REM 检查ngrok是否安装
where ngrok >nul 2>&1
if %errorlevel% neq 0 (
    echo [X] 错误: ngrok未安装
    echo.
    echo 请先安装ngrok:
    echo   方法1: choco install ngrok (需要Chocolatey)
    echo   方法2: 访问 https://ngrok.com/download 下载Windows版本
    pause
    exit /b 1
)

REM 检查authtoken
ngrok config check >nul 2>&1
if %errorlevel% neq 0 (
    echo [X] 错误: ngrok未配置authtoken
    echo.
    echo 请先配置ngrok:
    echo   1. 访问 https://ngrok.com 注册账号
    echo   2. 获取authtoken
    echo   3. 运行: ngrok config add-authtoken YOUR_AUTH_TOKEN
    pause
    exit /b 1
)

REM 获取端口号
set PORT=%1
if "%PORT%"=="" set PORT=8000

echo 创建ngrok隧道...
echo   本地端口: %PORT%
echo   公网URL: 即将显示
echo.
echo 按 Ctrl+C 停止ngrok
echo.
echo 提示: 打开 http://localhost:4040 查看请求详情
echo.
echo ==========================================
echo.

REM 启动ngrok
ngrok http %PORT%
