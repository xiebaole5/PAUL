#!/bin/bash
# 修复服务依赖并重启
# 使用方法: bash fix_service_dependency.sh

set -e

echo "========================================="
echo "开始修复服务依赖..."
echo "========================================="

# 进入项目目录
cd /root/PAUL

# 激活虚拟环境
source venv/bin/activate

echo "1. 停止服务..."
systemctl stop tnho-api || true

echo "2. 安装 python-multipart 依赖..."
pip install python-multipart --index-url https://mirrors.aliyun.com/pypi/simple/ || {
    echo "安装失败，尝试使用官方源..."
    pip install python-multipart
}

echo "3. 验证安装..."
python -c "import multipart; print('python-multipart 安装成功')" || {
    echo "错误: python-multipart 安装失败"
    exit 1
}

echo "4. 检查 coze-coding-dev-sdk..."
python -c "import coze_coding_dev_sdk; print('coze-coding-dev-sdk 已安装')" 2>/dev/null || {
    echo "警告: coze-coding-dev-sdk 未安装，尝试安装..."
    pip install coze-coding-dev-sdk --index-url https://mirrors.aliyun.com/pypi/simple/ || true
}

echo "5. 重启服务..."
systemctl start tnho-api

echo "6. 等待服务启动..."
sleep 5

echo "7. 检查服务状态..."
systemctl status tnho-api --no-pager || true

echo ""
echo "========================================="
echo "查看最新日志..."
echo "========================================="
journalctl -u tnho-api -n 30 --no-pager

echo ""
echo "========================================="
echo "修复完成！"
echo "========================================="
