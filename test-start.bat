@echo off
chcp 65001 >nul
echo ========================================
echo 测试启动服务
echo ========================================
echo.

cd /d C:\PAUL

echo 正在测试 langchain 是否可用...
python -c "import langchain; print('✅ langchain 可用')" 2>nul
if errorlevel 1 (
    echo ❌ langchain 不可用，需要安装
    pause
    exit /b 1
)

echo.
echo 正在测试 langgraph 是否可用...
python -c "import langgraph; print('✅ langgraph 可用')" 2>nul
if errorlevel 1 (
    echo ❌ langgraph 不可用，需要安装
    pause
    exit /b 1
)

echo.
echo 正在测试 fastapi 是否可用...
python -c "import fastapi; print('✅ fastapi 可用')" 2>nul
if errorlevel 1 (
    echo ❌ fastapi 不可用，需要安装
    pause
    exit /b 1
)

echo.
echo 正在测试 moviepy 是否可用...
python -c "import moviepy; print('✅ moviepy 可用')" 2>nul
if errorlevel 1 (
    echo ❌ moviepy 不可用，需要安装
    pause
    exit /b 1
)

echo.
echo ========================================
echo 所有依赖检查通过！
echo ========================================
echo.

echo 正在启动 FastAPI 服务...
echo.
python src\main.py

pause
