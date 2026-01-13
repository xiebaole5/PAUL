#!/bin/bash

# 小程序创建任务失败快速修复脚本

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

print_header "小程序创建任务失败快速修复"
print_info "开始时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# 1. 拉取最新代码
print_header "1. 拉取最新代码"
cd "$PROJECT_DIR" || exit 1

if git pull origin main; then
    print_success "代码拉取成功"
else
    print_error "代码拉取失败"
    exit 1
fi

# 2. 检查环境变量文件
print_header "2. 检查环境变量文件"
if [ -f .env ]; then
    print_success ".env 文件存在"

    if grep -q "PGDATABASE_URL" .env; then
        print_success "PGDATABASE_URL 已配置"
        grep "PGDATABASE_URL" .env | sed 's/=.*/=***/'
    else
        print_warning "PGDATABASE_URL 未配置"
    fi

    if grep -q "EXTERNAL_BASE_URL" .env; then
        print_success "EXTERNAL_BASE_URL 已配置"
        grep "EXTERNAL_BASE_URL" .env
    else
        print_warning "EXTERNAL_BASE_URL 未配置，将使用默认值"
    fi
else
    print_error ".env 文件不存在，需要创建"
    print_info "请参考以下内容创建 .env 文件："
    echo ""
    echo "PGDATABASE_URL=postgresql://tnho_user:your_password@localhost:5432/tnho_video"
    echo "EXTERNAL_BASE_URL=https://tnho-fasteners.com"
    echo "ARK_API_KEY=your_api_key"
    exit 1
fi

# 3. 重启应用
print_header "3. 重启应用"
print_info "停止旧进程..."
PID=$(ps aux | grep "[u]vicorn app:app" | awk '{print $2}')

if [ -n "$PID" ]; then
    print_info "停止旧进程 (PID: $PID)"
    kill $PID
    sleep 2
    print_success "旧进程已停止"
else
    print_info "未找到运行中的进程"
fi

print_info "启动新进程..."
source venv/bin/activate

# 启动应用（后台运行）
nohup uvicorn app:app --host 0.0.0.0 --port 8000 --workers 1 --log-level info >> logs/app.log 2>&1 &
NEW_PID=$!

sleep 3

if ps -p $NEW_PID > /dev/null; then
    print_success "应用启动成功 (PID: $NEW_PID)"
else
    print_error "应用启动失败"
    print_info "查看日志: tail -n 50 logs/app.log"
    exit 1
fi

# 4. 验证服务
print_header "4. 验证服务"
print_info "测试健康检查接口..."
sleep 2

if curl -s http://localhost:8000/api/health > /dev/null; then
    print_success "健康检查通过"
else
    print_warning "健康检查失败"
fi

if curl -s https://tnho-fasteners.com/api/health > /dev/null; then
    print_success "HTTPS 访问正常"
else
    print_warning "HTTPS 访问异常"
fi

# 5. 测试数据库连接
print_header "5. 测试数据库连接"
print_info "测试数据库连接..."

if source venv/bin/activate && python -c "from storage.database.db import get_session; db = get_session(); print('✓ 数据库连接成功'); db.close()" 2>&1 | grep -q "数据库连接成功"; then
    print_success "数据库连接正常"
else
    print_error "数据库连接失败"
    print_info "请检查 .env 文件中的 PGDATABASE_URL 配置"
fi

# 6. 测试任务创建
print_header "6. 测试任务创建"
print_info "创建测试任务..."

TEST_RESPONSE=$(curl -s -X POST https://tnho-fasteners.com/api/generate-video \
  -H "Content-Type: application/json" \
  -d '{"product_name":"测试产品","theme":"品质保证","duration":20,"type":"video"}')

if echo "$TEST_RESPONSE" | python -m json.tool | grep -q '"success": true'; then
    print_success "任务创建成功"
    echo "$TEST_RESPONSE" | python -m json.tool | head -n 10
else
    print_error "任务创建失败"
    echo "$TEST_RESPONSE" | python -m json.tool
fi

# 7. 显示结果
print_header "修复完成"
print_info "完成时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""
print_success "修复已完成，请测试小程序"
echo ""
print_info "查看日志："
echo "  tail -f logs/app.log"
echo ""
print_info "测试 API："
echo "  curl https://tnho-fasteners.com/api/health"
echo ""
print_info "创建任务："
echo "  curl -X POST https://tnho-fasteners.com/api/generate-video \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"product_name\":\"测试\",\"theme\":\"品质保证\",\"duration\":20,\"type\":\"video\"}'"
echo ""
print_warning "如果问题仍然存在，请查看："
echo "  1. 服务器日志: tail -f logs/app.log"
echo "  2. 小程序控制台: 微信开发者工具"
echo "  3. 排查指南: docs/小程序创建任务失败排查指南.md"
