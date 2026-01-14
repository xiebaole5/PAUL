#!/bin/bash

# 应用4GB内存配置脚本
# 超时时间60秒，连接池大小适配4GB内存

set -e

COLOR_GREEN='\033[0;32m'
COLOR_RED='\033[0;31m'
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

print_header() {
    echo ""
    echo -e "${COLOR_BLUE}========================================${COLOR_RESET}"
    echo -e "${COLOR_BLUE}$1${COLOR_RESET}"
    echo -e "${COLOR_BLUE}========================================${COLOR_RESET}"
}

PROJECT_DIR="/root/tnho-video"

print_header "应用4GB内存配置"
print_info "开始时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

cd "$PROJECT_DIR" || exit 1

# 1. 显示当前配置
print_header "1. 当前配置"
echo "连接池配置："
grep -A 10 "pool_size=" src/storage/database/db.py | head -n 11

# 2. 验证配置
print_header "2. 验证配置"

if grep -q "size = 20" src/storage/database/db.py && \
   grep -q "overflow = 30" src/storage/database/db.py && \
   grep -q "recycle = 3600" src/storage/database/db.py && \
   grep -q "timeout = 60" src/storage/database/db.py && \
   grep -q "statement_timeout=60000" src/storage/database/db.py; then
    print_success "配置验证通过"
else
    print_error "配置不匹配，请检查文件"
    exit 1
fi

# 3. 重启应用
print_header "3. 重启应用"
source venv/bin/activate

print_info "停止旧进程..."
pkill -f "uvicorn app:app" || true
sleep 2

print_info "启动新进程..."
nohup uvicorn app:app --host 0.0.0.0 --port 8000 --workers 1 --log-level info >> logs/app.log 2>&1 &
sleep 3

if ps aux | grep -v grep | grep "uvicorn app:app" > /dev/null; then
    print_success "应用已重启"
else
    print_error "应用启动失败"
    exit 1
fi

# 4. 测试数据库连接
print_header "4. 测试数据库连接"
print_info "测试数据库连接..."

if python -c "from storage.database.db import get_session; db = get_session(); db.execute('SELECT 1'); print('✓ 数据库连接成功'); db.close()" 2>&1 | grep -q "数据库连接成功"; then
    print_success "数据库连接正常"
else
    print_error "数据库连接失败"
    print_info "查看日志：tail -f logs/app.log"
fi

# 5. 测试 API
print_header "5. 测试 API"
sleep 2

if curl -s https://tnho-fasteners.com/api/health > /dev/null; then
    print_success "HTTPS API 服务正常"
elif curl -s http://localhost:8000/api/health > /dev/null; then
    print_success "HTTP API 服务正常"
else
    print_warning "API 服务异常"
fi

# 6. 显示配置结果
print_header "配置应用完成"
print_info "完成时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""
print_success "4GB内存配置已应用"
echo ""
print_info "当前配置："
echo "  pool_size:         20"
echo "  max_overflow:      30"
echo "  最大连接数:        50 (20+30)"
echo "  pool_recycle:      3600s (1小时)"
echo "  pool_timeout:      60s"
echo "  connect_timeout:   10s"
echo "  statement_timeout: 60s"
echo ""
print_info "预期效果："
echo "  ✓ 支持更长的任务执行时间（60秒超时）"
echo "  ✓ 适配4GB内存服务器"
echo "  ✓ 最大连接数50个，内存占用约250MB"
echo "  ✓ 提高并发处理能力"
echo ""
print_info "下一步："
echo "  1. 在小程序中测试视频生成功能"
echo "  2. 测试长时间任务是否正常"
echo "  3. 观察日志：tail -f logs/app.log"
echo "  4. 监控数据库连接：docker exec -it tnho-postgres psql -U tnho_user -d tnho_video -c \"SELECT count(*) FROM pg_stat_activity;\""
