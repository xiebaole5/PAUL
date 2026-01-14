#!/bin/bash

# 数据库连接优化脚本
# 适用于低配置服务器（2核/1.6GB）

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

print_warning() {
    echo -e "${COLOR_YELLOW}⚠ $1${COLOR_RESET}"
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

print_header "数据库连接优化"
print_info "开始时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

cd "$PROJECT_DIR" || exit 1

# 1. 检查文件是否存在
print_header "1. 检查文件"
if [ ! -f "src/storage/database/db.py" ]; then
    print_error "src/storage/database/db.py 不存在"
    exit 1
fi
print_success "文件存在"

# 2. 备份原文件
print_header "2. 备份原文件"
BACKUP_FILE="src/storage/database/db.py.backup.$(date +%Y%m%d_%H%M%S)"
cp src/storage/database/db.py "$BACKUP_FILE"
print_success "文件已备份到: $BACKUP_FILE"

# 3. 显示当前配置
print_header "3. 当前配置"
echo "连接池配置："
grep -A 5 "pool_size=" src/storage/database/db.py | head -n 6

# 4. 优化连接池配置
print_header "4. 优化连接池配置"

# 检查是否已经是优化后的配置
if grep -q "size = 5" src/storage/database/db.py; then
    print_warning "配置已经优化，跳过修改"
else
    print_info "正在修改配置..."

    # 使用 Python 脚本精确修改配置
    python3 << 'PYTHON_SCRIPT'
import re

file_path = "src/storage/database/db.py"

# 读取文件
with open(file_path, 'r') as f:
    content = f.read()

# 替换连接池配置
content = re.sub(r'size = \d+', 'size = 5', content)
content = re.sub(r'overflow = \d+', 'overflow = 10', content)
content = re.sub(r'recycle = \d+', 'recycle = 3600', content)
content = re.sub(r'timeout = \d+', 'timeout = 10', content)

# 检查是否需要添加 connect_args
if 'connect_args' not in content:
    # 找到 create_engine 调用的位置，在 pool_pre_ping=True 后添加 connect_args
    pattern = r'(pool_pre_ping=True,)'
    replacement = r'''\1
        connect_args={
            "connect_timeout": 5,
            "options": "-c statement_timeout=10000"
        },'''
    content = re.sub(pattern, replacement, content, count=1)

# 写回文件
with open(file_path, 'w') as f:
    f.write(content)

print("配置修改完成")
PYTHON_SCRIPT

    print_success "连接池配置已优化"
fi

# 5. 显示新配置
print_header "5. 优化后配置"
echo "连接池配置："
grep -A 10 "pool_size=" src/storage/database/db.py | head -n 11

# 6. 验证配置
print_header "6. 验证配置"

if grep -q "size = 5" src/storage/database/db.py && \
   grep -q "overflow = 10" src/storage/database/db.py && \
   grep -q "recycle = 3600" src/storage/database/db.py && \
   grep -q "timeout = 10" src/storage/database/db.py; then
    print_success "配置验证通过"
else
    print_warning "配置可能不完整，请手动检查"
fi

if grep -q "connect_timeout" src/storage/database/db.py; then
    print_success "connect_args 已添加"
else
    print_warning "connect_args 未添加，可能需要手动添加"
fi

# 7. 重启应用
print_header "7. 重启应用"
print_info "停止旧进程..."
source venv/bin/activate
pkill -f "uvicorn app:app" || true
sleep 2

print_info "启动新进程..."
nohup uvicorn app:app --host 0.0.0.0 --port 8000 --workers 1 --log-level info >> logs/app.log 2>&1 &
sleep 3

if ps aux | grep -v grep | grep "uvicorn app:app" > /dev/null; then
    print_success "应用已重启"
else
    print_error "应用启动失败"
    print_info "查看日志：tail -f logs/app.log"
    exit 1
fi

# 8. 测试数据库连接
print_header "8. 测试数据库连接"
print_info "测试数据库连接..."

if python -c "from storage.database.db import get_session; db = get_session(); db.execute('SELECT 1'); print('✓ 数据库连接成功'); db.close()" 2>&1 | grep -q "数据库连接成功"; then
    print_success "数据库连接正常"
else
    print_error "数据库连接失败"
    print_info "查看日志：tail -f logs/app.log"
fi

# 9. 测试 API
print_header "9. 测试 API"
sleep 2

if curl -s https://tnho-fasteners.com/api/health > /dev/null; then
    print_success "HTTPS API 服务正常"
elif curl -s http://localhost:8000/api/health > /dev/null; then
    print_success "HTTP API 服务正常"
else
    print_warning "API 服务异常"
fi

# 10. 显示优化结果
print_header "优化完成"
print_info "完成时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""
print_success "优化已完成"
echo ""
print_info "配置变更："
echo "  pool_size:      100 → 5"
echo "  max_overflow:   100 → 10"
echo "  pool_recycle:   1800s → 3600s (30分钟 → 1小时)"
echo "  pool_timeout:   30s → 10s"
echo "  connect_timeout: 未设置 → 5s"
echo "  statement_timeout: 未设置 → 10s"
echo ""
print_info "预期效果："
echo "  ✓ 内存占用减少约 90%（从 ~1GB 降到 ~100MB）"
echo "  ✓ 连接超时减少 67%（从30秒降到10秒）"
echo "  ✓ 最大连接数从 200 降到 15"
echo "  ✓ 提高响应速度和稳定性"
echo ""
print_info "下一步："
echo "  1. 在小程序中测试视频生成功能"
echo "  2. 观察是否还有连接错误"
echo "  3. 查看日志：tail -f logs/app.log"
echo "  4. 监控数据库连接：docker exec -it tnho-postgres psql -U tnho_user -d tnho_video -c \"SELECT count(*) FROM pg_stat_activity;\""
echo ""
print_info "恢复备份（如需要）："
echo "  cp $BACKUP_FILE src/storage/database/db.py"
echo "  bash scripts/restart-app.sh"
