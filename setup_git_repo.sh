#!/bin/bash
# 服务器Git仓库初始化脚本
# 在服务器47.110.72.148上执行

set -e

echo "=== Git仓库初始化和同步 ==="
echo ""

# 检查当前目录
CURRENT_DIR=$(pwd)
echo "当前目录: $CURRENT_DIR"
echo ""

# 检查是否是Git仓库
if [ -d ".git" ]; then
    echo "✅ 当前目录已是Git仓库"

    # 检查远程仓库
    if git remote -v | grep -q "xiebaole5/PAUL"; then
        echo "✅ 已连接到远程仓库: https://github.com/xiebaole5/PAUL.git"
    else
        echo "⚠️  需要添加远程仓库"
        git remote add origin https://github.com/xiebaole5/PAUL.git
    fi

    # 拉取最新代码
    echo ""
    echo "拉取最新代码..."
    git fetch origin
    git reset --hard origin/main
    git clean -fd
else
    echo "❌ 当前目录不是Git仓库"
    echo ""

    # 询问用户选择
    echo "请选择操作："
    echo "1) 将当前目录初始化为Git仓库（保留现有代码）"
    echo "2) 从GitHub克隆新仓库（覆盖现有代码）"
    echo "3) 退出"
    echo ""
    read -p "请输入选项 (1/2/3): " choice

    case $choice in
        1)
            echo ""
            echo "初始化Git仓库..."

            # 初始化Git仓库
            git init

            # 添加远程仓库
            git remote add origin https://github.com/xiebaole5/PAUL.git

            # 拉取最新代码（不覆盖本地修改）
            git fetch origin
            git reset --hard origin/main
            git clean -fd

            echo "✅ Git仓库初始化完成"
            ;;
        2)
            echo ""
            echo "克隆新仓库..."

            # 备份现有目录
            BACKUP_DIR="${CURRENT_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
            echo "备份现有目录到: $BACKUP_DIR"
            mv ${CURRENT_DIR} ${BACKUP_DIR}

            # 克隆仓库
            git clone https://github.com/xiebaole5/PAUL.git ${CURRENT_DIR}
            cd ${CURRENT_DIR}

            echo "✅ 仓库克隆完成"
            echo "备份目录: $BACKUP_DIR"
            ;;
        3)
            echo "退出"
            exit 0
            ;;
        *)
            echo "无效选项"
            exit 1
            ;;
    esac
fi

echo ""
echo "=== 当前Git状态 ==="
git log --oneline -3
echo ""
git status
echo ""

# 检查脚本文件
echo "=== 检查脚本文件 ==="
if [ -f "start_service_v2.sh" ]; then
    echo "✅ start_service_v2.sh 存在"
    chmod +x start_service_v2.sh
else
    echo "❌ start_service_v2.sh 不存在"
fi

if [ -f "sync_and_deploy.sh" ]; then
    echo "✅ sync_and_deploy.sh 存在"
    chmod +x sync_and_deploy.sh
else
    echo "❌ sync_and_deploy.sh 不存在"
fi

echo ""

# 询问是否启动服务
read -p "是否立即启动服务? (y/n): " start_service

if [ "$start_service" = "y" ] || [ "$start_service" = "Y" ]; then
    echo ""
    echo "=== 启动服务 ==="

    # 停止旧服务
    pkill -9 -f uvicorn 2>/dev/null || true
    sleep 2

    # 设置环境变量
    export COZE_WORKSPACE_PATH=${CURRENT_DIR}
    export PYTHONPATH=${CURRENT_DIR}/src:$PYTHONPATH

    # 启动服务
    if [ -f "start_service_v2.sh" ]; then
        bash start_service_v2.sh
    else
        echo "⚠️  start_service_v2.sh 不存在，使用手动启动..."
        nohup python3 -m uvicorn src.main:app --host 0.0.0.0 --port 8080 --log-level info > /tmp/fastapi.log 2>&1 &

        sleep 5

        if ps aux | grep -v grep | grep -q "uvicorn.*src.main:app"; then
            echo "✅ 服务已启动"
            curl http://localhost:8080/health
        else
            echo "❌ 服务启动失败"
            tail -30 /tmp/fastapi.log
        fi
    fi
else
    echo ""
    echo "跳过服务启动"
    echo ""
    echo "手动启动命令："
    echo "  bash start_service_v2.sh"
fi

echo ""
echo "=== 完成 ==="
