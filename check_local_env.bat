@echo off
chcp 65001 >nul
echo ==========================================
echo 检查本地开发环境 (Windows)
echo ==========================================
echo.

REM 检查Python
echo 1. 检查Python...
python --version >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=*" %%i in ('python --version') do set PYTHON_VERSION=%%i
    echo    [OK] Python已安装: %PYTHON_VERSION%
) else (
    echo    [X] Python未安装，请先安装Python 3.12+
    echo    下载地址: https://www.python.org/downloads/
    pause
    exit /b 1
)

REM 检查pip
echo.
echo 2. 检查pip...
pip --version >nul 2>&1
if %errorlevel% equ 0 (
    echo    [OK] pip已安装
) else (
    echo    [X] pip未找到
)

REM 检查FastAPI
echo.
echo 3. 检查FastAPI依赖...
python -c "import fastapi" >nul 2>&1
if %errorlevel% equ 0 (
    python -c "import fastapi; print(fastapi.__version__)" >nul 2>&1
    for /f "tokens=*" %%i in ('python -c "import fastapi; print(fastapi.__version__)"') do set FASTAPI_VERSION=%%i
    echo    [OK] FastAPI已安装: v%FASTAPI_VERSION%
) else (
    echo    [X] FastAPI未安装
    echo.
    echo    安装命令:
    echo    pip install fastapi uvicorn pydantic python-dotenv
)

REM 检查Uvicorn
echo.
echo 4. 检查Uvicorn...
python -c "import uvicorn" >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=*" %%i in ('python -c "import uvicorn; print(uvicorn.__version__)"') do set UVICORN_VERSION=%%i
    echo    [OK] Uvicorn已安装: v%UVICORN_VERSION%
) else (
    echo    [X] Uvicorn未安装
)

REM 检查ngrok
echo.
echo 5. 检查ngrok...
where ngrok >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=*" %%i in ('ngrok version') do set NGROK_VERSION=%%i
    echo    [OK] ngrok已安装: %NGROK_VERSION%
    
    REM 检查authtoken
    ngrok config check >nul 2>&1
    if %errorlevel% equ 0 (
        echo    [OK] ngrok已配置authtoken
    ) else (
        echo    [!] ngrok未配置authtoken
        echo.
        echo    配置步骤:
        echo    1. 访问 https://ngrok.com 注册账号
        echo    2. 获取authtoken
        echo    3. 运行: ngrok config add-authtoken YOUR_AUTH_TOKEN
    )
) else (
    echo    [X] ngrok未安装
    echo.
    echo    安装方法:
    echo    方法1: choco install ngrok (需要Chocolatey)
    echo    方法2: 访问 https://ngrok.com/download 下载Windows版本
)

REM 检查端口占用
echo.
echo 6. 检查端口占用...
netstat -ano | findstr ":8000" | findstr "LISTENING" >nul 2>&1
if %errorlevel% equ 0 (
    echo    [!] 8000端口已被占用
    echo    进程信息:
    netstat -ano | findstr ":8000" | findstr "LISTENING"
) else (
    echo    [OK] 8000端口可用
)

netstat -ano | findstr ":4040" | findstr "LISTENING" >nul 2>&1
if %errorlevel% equ 0 (
    echo    [!] 4040端口已被占用 (ngrok面板)
) else (
    echo    [OK] 4040端口可用 (ngrok面板)
)

REM 总结
echo.
echo ==========================================
echo 检查完成
echo ==========================================
echo.
echo 下一步:
echo   1. 如果缺少依赖，请安装
echo   2. 运行: start_local.bat
echo.
pause
