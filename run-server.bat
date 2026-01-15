@echo off
chcp 65001 >nul
echo ========================================
echo 启动天虹紧固件视频生成服务
echo ========================================
echo.

cd /d C:\PAUL

echo [1/2] 启动 FastAPI 后端服务...
echo.
C:\Users\12187\AppData\Local\Python\bin\python.exe src\main.py

pause
