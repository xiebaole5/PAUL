#!/bin/bash
# 天虹紧固件视频生成服务 - 启动脚本

set -e

PROJECT_DIR="/root/PAUL"
VENV_DIR="${PROJECT_DIR}/venv"
LOG_FILE="/var/log/tnho-api.log"

echo "=========================================="
echo "天虹紧固件视频生成服务 - 启动"
echo "=========================================="

# 激活虚拟环境
source "${VENV_DIR}/bin/activate"

# 检查环境变量文件
if [ ! -f "${PROJECT_DIR}/.env" ]; then
    echo "错误：未找到 .env 文件"
    echo "请先创建 .env 文件并配置环境变量"
    exit 1
fi

# 检查 PostgreSQL 是否运行
if ! docker ps --format '{{.Names}}' | grep -q "^tnho-postgres$"; then
    echo "错误：PostgreSQL 容器未运行"
    echo "正在启动 PostgreSQL..."
    docker start tnho-postgres
    sleep 5
fi

# 停止旧服务（如果存在）
echo "停止旧服务..."
systemctl stop tnho-api 2>/dev/null || true

# 启动新服务
echo "启动服务..."
systemctl start tnho-api

# 等待服务启动
sleep 3

# 检查服务状态
if systemctl is-active --quiet tnho-api; then
    echo "=========================================="
    echo -e "\033[0;32m✓ 服务启动成功\033[0m"
    echo "=========================================="
    echo ""
    echo "服务状态："
    systemctl status tnho-api --no-pager -l
    echo ""
    echo "查看实时日志："
    echo "  journalctl -u tnho-api -f"
    echo ""
    echo "查看最近日志："
    echo "  journalctl -u tnho-api -n 50"
    echo ""
else
    echo "=========================================="
    echo -e "\033[0;31m✗ 服务启动失败\033[0m"
    echo "=========================================="
    echo ""
    echo "查看日志："
    journalctl -u tnho-api -n 50 --no-pager
    echo ""
    exit 1
fi
