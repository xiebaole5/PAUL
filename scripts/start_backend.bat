@echo off
REM 天虹紧固件视频生成后端启动脚本 (Windows)

setlocal

echo ========================================
echo   天虹紧固件视频生成后端服务
echo ========================================
echo.

REM 检查 Python
echo [1/5] 检查 Python 版本...
python --version
if errorlevel 1 (
    echo 错误：未找到 Python，请先安装 Python 3.9+
    pause
    exit /b 1
)
echo.

REM 检查依赖
echo [2/5] 检查依赖...
if exist requirements.txt (
    pip show fastapi >nul 2>&1
    if errorlevel 1 (
        echo 依赖未安装，正在安装...
        pip install -r requirements.txt
    )
    echo 依赖检查完成
) else (
    echo 错误：未找到 requirements.txt
    pause
    exit /b 1
)
echo.

REM 检查 API Key
echo [3/5] 检查 API Key 配置...
if "%ARK_API_KEY%"=="" (
    echo 警告：未设置 ARK_API_KEY 环境变量
    echo 请设置 API Key：
    echo   set ARK_API_KEY=your_api_key_here
    echo.
    set /p CONTINUE="是否继续启动？(y/n): "
    if /i not "%CONTINUE%"=="y" (
        exit /b 1
    )
) else (
    echo API Key 已配置
)
echo.

REM 检查配置文件
echo [4/5] 检查配置文件...
if exist "config\agent_llm_config.json" (
    echo Agent 配置文件存在
) else (
    echo 错误：未找到 config\agent_llm_config.json
    pause
    exit /b 1
)

if exist "src\api\app.py" (
    echo API 服务文件存在
) else (
    echo 错误：未找到 src\api\app.py
    pause
    exit /b 1
)
echo.

REM 启动服务
echo [5/5] 启动服务...
echo 服务地址: http://localhost:8000
echo 健康检查: http://localhost:8000/health
echo API 文档: http://localhost:8000/docs
echo.
echo ========================================
echo 服务启动中...
echo ========================================
echo.

cd /d "%~dp0..\"

REM 启动服务
uvicorn src.api.app:app --host 0.0.0.0 --port 8000 --reload

pause
