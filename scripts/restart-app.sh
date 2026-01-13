#!/bin/bash

# 小程序应用重启脚本
# 用于重启 Python 应用以应用代码更新

set -e

COLOR_GREEN='\033[0;32m'
COLOR_RED='\033[0;31m'
COLOR_YELLOW='\033[1;33m'
COLOR_BLUE='\033[0;34m'
COLOR_RESET='\033[0m'

print_success() {
    echo -e "${COLOR_GREEN}✓ $1${COLOR_RESET}"
}

print_error() {
    echo -e "${COLOR_RED}✗ $1${COLOR_RESET}"
}

print_info() {
    echo -e "${COLOR_BLUE}ℹ $1${COLOR_RESET}"
}

print_warning() {
    echo -e "${COLOR_YELLOW}⚠ $1${COLOR_RESET}"
}

print_header() {
    echo ""
    echo -e "${COLOR_BLUE}========================================${COLOR_RESET}"
    echo -e "${COLOR_BLUE}$1${COLOR_RESET}"
    echo -e "${COLOR_BLUE}========================================${COLOR_RESET}"
}

PROJECT_DIR="/root/tnho-video"

print_header "小程序应用重启"
print_info "开始时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# 进入项目目录
cd "$PROJECT_DIR" || exit 1
print_info "进入项目目录: $PROJECT_DIR"

# 1. 拉取最新代码
print_header "1. 拉取最新代码"
if git pull origin main; then
    print_success "代码拉取成功"
else
    print_error "代码拉取失败"
    exit 1
fi

# 2. 检查环境变量
print_header "2. 检查环境变量"
if [ -f .env ]; then
    if grep -q "EXTERNAL_BASE_URL=https://tnho-fasteners.com" .env; then
        print_success "EXTERNAL_BASE_URL 配置正确"
    else
        print_warning "EXTERNAL_BASE_URL 未配置，使用默认值"
    fi
else
    print_error ".env 文件不存在"
    exit 1
fi

# 3. 停止旧进程
print_header "3. 停止旧进程"
PID=$(ps aux | grep "[u]vicorn app:app" | awk '{print $2}')

if [ -n "$PID" ]; then
    print_info "停止旧进程 (PID: $PID)"
    kill $PID
    sleep 2
    print_success "旧进程已停止"
else
    print_info "未找到运行中的进程"
fi

# 4. 启动新进程
print_header "4. 启动新进程"
print_info "启动 Python 应用..."

# 进入虚拟环境
if [ -d "venv" ]; then
    source venv/bin/activate
    print_info "虚拟环境已激活"
else
    print_error "虚拟环境不存在"
    exit 1
fi

# 启动应用（后台运行）
nohup uvicorn app:app --host 0.0.0.0 --port 8000 --workers 1 --log-level info >> logs/app.log 2>&1 &
NEW_PID=$!

sleep 3

# 检查进程是否启动成功
if ps -p $NEW_PID > /dev/null; then
    print_success "应用启动成功 (PID: $NEW_PID)"
else
    print_error "应用启动失败"
    print_info "查看日志: tail -n 50 logs/app.log"
    exit 1
fi

# 5. 测试应用
print_header "5. 测试应用"
print_info "测试健康检查接口..."

sleep 2

if curl -s http://localhost:8000/api/health > /dev/null; then
    print_success "健康检查通过"
else
    print_warning "健康检查失败，请查看日志"
fi

# 6. 显示结果
print_header "重启完成"
print_info "完成时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""
print_success "应用已成功重启"
echo ""
print_info "查看日志："
echo "  tail -f logs/app.log"
echo ""
print_info "查看进程："
echo "  ps aux | grep uvicorn"
echo ""
print_info "测试 API："
echo "  curl https://tnho-fasteners.com/api/health"
