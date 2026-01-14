#!/bin/bash
# 服务器代码完整性检查脚本

echo "=========================================="
echo "TNHO 视频生成服务 - 代码完整性检查"
echo "=========================================="
echo ""

PROJECT_DIR="/root/tnho-video"

# 检查目录是否存在
if [ ! -d "$PROJECT_DIR" ]; then
    echo "❌ 项目目录不存在: $PROJECT_DIR"
    echo "请先克隆代码：git clone https://github.com/xiebaole5/PAUL.git tnho-video"
    exit 1
fi

cd "$PROJECT_DIR"

echo "检查关键文件..."
echo ""

# 检查关键文件
FILES_OK=true

# 检查 app.py
if [ -f "app.py" ]; then
    echo "✅ app.py 存在"
else
    echo "❌ app.py 缺失"
    FILES_OK=false
fi

# 检查 requirements.txt
if [ -f "requirements.txt" ]; then
    echo "✅ requirements.txt 存在"
else
    echo "❌ requirements.txt 缺失"
    FILES_OK=false
fi

# 检查 .env
if [ -f ".env" ]; then
    echo "✅ .env 存在"
else
    echo "❌ .env 缺失"
    FILES_OK=false
fi

echo ""
echo "检查目录结构..."
echo ""

# 检查关键目录
DIRS_OK=true

if [ -d "src" ]; then
    echo "✅ src/ 目录存在"

    # 检查 src 下的子目录
    if [ -d "src/agents" ]; then
        echo "✅ src/agents/ 目录存在"
    else
        echo "❌ src/agents/ 目录缺失"
        DIRS_OK=false
    fi

    if [ -d "src/api" ]; then
        echo "✅ src/api/ 目录存在"
    else
        echo "❌ src/api/ 目录缺失"
        DIRS_OK=false
    fi

    if [ -d "src/storage" ]; then
        echo "✅ src/storage/ 目录存在"

        if [ -d "src/storage/database" ]; then
            echo "✅ src/storage/database/ 目录存在"

            if [ -f "src/storage/database/init_db.py" ]; then
                echo "✅ src/storage/database/init_db.py 存在"
            else
                echo "❌ src/storage/database/init_db.py 缺失"
                FILES_OK=false
            fi
        else
            echo "❌ src/storage/database/ 目录缺失"
            DIRS_OK=false
        fi
    else
        echo "❌ src/storage/ 目录缺失"
        DIRS_OK=false
    fi

    if [ -d "src/tools" ]; then
        echo "✅ src/tools/ 目录存在"
    else
        echo "❌ src/tools/ 目录缺失"
        DIRS_OK=false
    fi
else
    echo "❌ src/ 目录缺失"
    DIRS_OK=false
fi

echo ""
echo "=========================================="

if [ "$FILES_OK" = true ] && [ "$DIRS_OK" = true ]; then
    echo "✅ 代码完整性检查通过"
    echo "=========================================="
    echo ""
    echo "可以继续执行："
    echo "1. 数据库初始化"
    echo "2. 启动应用服务"
    echo "3. 验证 API 功能"
else
    echo "❌ 代码完整性检查失败"
    echo "=========================================="
    echo ""
    echo "需要重新克隆代码："
    echo ""
    echo "步骤 1: 备份配置"
    echo "  cp .env .env.backup"
    echo ""
    echo "步骤 2: 删除旧代码"
    echo "  cd /root"
    echo "  rm -rf tnho-video"
    echo ""
    echo "步骤 3: 重新克隆"
    echo "  git clone https://github.com/xiebaole5/PAUL.git tnho-video"
    echo "  cd tnho-video"
    echo ""
    echo "步骤 4: 恢复配置"
    echo "  cp ../.env.backup .env"
    echo ""
fi

echo ""
echo "项目根目录文件列表："
ls -lh | head -20

echo ""
echo "src 目录结构："
find src -type f -o -type d | sort | head -30
