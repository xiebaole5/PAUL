@echo off
chcp 65001 >nul
echo ==========================================
echo 启动本地FastAPI服务 (Windows)
echo ==========================================
echo.

REM 检查是否在正确的目录
if not exist "app.py" (
    echo [X] 错误: 请在项目根目录运行此脚本
    echo    当前目录: %cd%
    echo    应该包含: app.py
    pause
    exit /b 1
)

if not exist "src" (
    echo [X] 错误: 请在项目根目录运行此脚本
    echo    当前目录: %cd%
    echo    应该包含: src\ 目录
    pause
    exit /b 1
)

REM 检查Python
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [X] 错误: Python未安装
    pause
    exit /b 1
)

REM 检查端口占用
netstat -ano | findstr ":8000" | findstr "LISTENING" >nul 2>&1
if %errorlevel% equ 0 (
    echo [!] 警告: 8000端口已被占用
    echo.
    set /p KILL_PROCESS="是否停止占用8000端口的进程? (y/n) "
    if /i "%KILL_PROCESS%"=="y" (
        echo 正在停止进程...
        for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":8000" ^| findstr "LISTENING"') do (
            taskkill /F /PID %%a
        )
        timeout /t 2 >nul
    ) else (
        echo 使用备用端口8001...
        set PORT=8001
    )
)

if "%PORT%"=="" set PORT=8000

echo 启动FastAPI服务...
echo   端口: %PORT%
echo   地址: http://localhost:%PORT%
echo.
echo 按 Ctrl+C 停止服务
echo.
echo ==========================================
echo.

REM 加载环境变量（如果有.env文件）
if exist ".env" (
    echo [OK] 已加载 .env 文件
    for /f "tokens=*" %%a in ('type .env ^| findstr /v "^#"') do set %%a
)

REM 启动服务
python -m uvicorn app:app --host 0.0.0.0 --port %PORT% --reload
