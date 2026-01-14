#!/bin/bash

# 服务器紧急修复脚本
# 用于修复 ModuleNotFoundError 和缺少脚本文件的问题

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

print_header "服务器紧急修复"
print_info "开始时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

cd "$PROJECT_DIR" || exit 1

# 1. 处理本地修改
print_header "1. 处理本地修改"
print_info "检查本地修改..."

if git diff --quiet miniprogram/app.js src/api/app.py 2>/dev/null; then
    print_info "没有本地修改"
else
    print_warning "发现本地修改，将使用 stash 保存"
    git stash push -m "本地修改备份 $(date '+%Y%m%d_%H%M%S')" miniprogram/app.js src/api/app.py 2>/dev/null || true
    print_success "本地修改已保存到 stash"
fi

# 2. 拉取最新代码
print_header "2. 拉取最新代码"
if git pull origin main; then
    print_success "代码拉取成功"
else
    print_error "代码拉取失败，尝试强制拉取..."
    git fetch --all
    git reset --hard origin/main
    print_success "代码已强制更新"
fi

# 3. 检查必要目录
print_header "3. 检查必要目录"

mkdir -p scripts src/storage/database src/storage/memory
mkdir -p logs assets/uploads
print_success "必要目录已创建"

# 4. 检查 storage 模块
print_header "4. 检查 storage 模块"

MISSING_FILES=()

if [ ! -f "src/storage/database/db.py" ]; then
    MISSING_FILES+=("src/storage/database/db.py")
fi

if [ ! -f "src/storage/database/video_task_manager.py" ]; then
    MISSING_FILES+=("src/storage/database/video_task_manager.py")
fi

if [ ! -f "src/storage/memory/memory_saver.py" ]; then
    MISSING_FILES+=("src/storage/memory/memory_saver.py")
fi

if [ ${#MISSING_FILES[@]} -eq 0 ]; then
    print_success "storage 模块文件完整"
else
    print_error "storage 模块文件缺失："
    for file in "${MISSING_FILES[@]}"; do
        echo "  - $file"
    done
    print_info "请从 GitHub 仓库获取完整代码或检查备份"
    # 继续执行，让用户手动处理
fi

# 5. 创建重启脚本
print_header "5. 创建重启脚本"

cat > scripts/restart-app.sh << 'EOF'
#!/bin/bash

# 小程序应用重启脚本

set -e

PROJECT_DIR="/root/tnho-video"

echo "=== 重启应用 ==="
cd "$PROJECT_DIR"

# 停止旧进程
echo "停止旧进程..."
pkill -f "uvicorn app:app" || true
sleep 2

# 启动新进程
echo "启动新进程..."
source venv/bin/activate
nohup uvicorn app:app --host 0.0.0.0 --port 8000 --workers 1 --log-level info >> logs/app.log 2>&1 &

sleep 3

# 检查进程
if ps aux | grep -v grep | grep "uvicorn app:app" > /dev/null; then
    echo "✓ 应用启动成功"
else
    echo "✗ 应用启动失败"
    exit 1
fi
EOF

chmod +x scripts/restart-app.sh
print_success "重启脚本已创建"

# 6. 重启应用
print_header "6. 重启应用"

if [ ${#MISSING_FILES[@]} -gt 0 ]; then
    print_warning "storage 模块文件缺失，跳过应用重启"
    print_info "请先补充缺失的文件，然后手动重启：bash scripts/restart-app.sh"
else
    bash scripts/restart-app.sh
fi

# 7. 测试服务
print_header "7. 测试服务"

sleep 2

if curl -s https://tnho-fasteners.com/api/health > /dev/null; then
    print_success "HTTPS 服务正常"
elif curl -s http://localhost:8000/api/health > /dev/null; then
    print_success "HTTP 服务正常"
else
    print_warning "服务异常，请查看日志"
fi

# 8. 测试数据库连接
print_header "8. 测试数据库连接"

if [ -f ".env" ]; then
    print_info "测试数据库连接..."
    if source venv/bin/activate && python -c "from storage.database.db import get_session; db = get_session(); print('✓ 数据库连接成功'); db.close()" 2>&1 | grep -q "数据库连接成功"; then
        print_success "数据库连接正常"
    else
        print_error "数据库连接失败"
    fi
else
    print_warning ".env 文件不存在"
fi

# 9. 查看日志
print_header "9. 查看最新日志"
print_info "最近 15 行日志："
echo ""
if [ -f "logs/app.log" ]; then
    tail -n 15 logs/app.log
else
    print_warning "日志文件不存在"
fi

# 10. 完成
print_header "修复完成"
print_info "完成时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""
print_success "修复已完成"
echo ""

if [ ${#MISSING_FILES[@]} -gt 0 ]; then
    print_warning "⚠ 注意：storage 模块文件缺失，需要手动处理"
    echo ""
    print_info "请执行以下操作之一："
    echo "  1. 从 GitHub 仓库拉取完整代码："
    echo "     git clone https://github.com/xiebaole5/PAUL.git /tmp/paul-full"
    echo "     cp -r /tmp/paul-full/src/storage/* src/storage/"
    echo "     rm -rf /tmp/paul-full"
    echo ""
    echo "  2. 从 stash 恢复（如果有备份）："
    echo "     git stash list"
    echo "     git stash pop"
    echo ""
    echo "  3. 手动创建缺失的文件"
    echo ""
    print_info "完成后重启应用：bash scripts/restart-app.sh"
else
    print_info "如果问题仍然存在，请查看："
    echo "  1. 完整日志: tail -f logs/app.log"
    echo "  2. 错误日志: tail -f logs/error.log"
    echo "  3. Python 路径: source venv/bin/activate && python -c 'import sys; print(sys.path)'"
    echo ""
    print_info "测试 API："
    echo "  curl https://tnho-fasteners.com/api/health"
fi
