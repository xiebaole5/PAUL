#!/bin/bash
# TNHO 视频生成服务 - 从 GitHub 部署到服务器
# 在服务器上执行此脚本

set -e

echo "=========================================="
echo "TNHO 视频生成服务部署（GitHub 方式）"
echo "=========================================="
echo ""

# 检查 SSH 密钥
if [ ! -f ~/.ssh/id_ed25519 ]; then
    echo "⚠️  未检测到 SSH 密钥"
    echo ""
    echo "需要配置 SSH 密钥才能克隆私有仓库"
    echo ""
    echo "配置步骤："
    echo "1. 生成 SSH 密钥:"
    echo "   ssh-keygen -t ed25519 -C 'root@tnho-server'"
    echo ""
    echo "2. 查看公钥:"
    echo "   cat ~/.ssh/id_ed25519.pub"
    echo ""
    echo "3. 将公钥添加到 GitHub:"
    echo "   - 访问 https://github.com/settings/keys"
    echo "   - 点击 'New SSH key'"
    echo "   - 粘贴公钥内容"
    echo ""
    echo "4. 配置完成后，重新执行此脚本"
    echo ""
    exit 1
fi

# 克隆或更新代码
if [ -d "/root/tnho-video/.git" ]; then
    echo "步骤 1: 更新代码..."
    cd /root/tnho-video
    git fetch origin
    git reset --hard origin/main
else
    echo "步骤 1: 克隆代码..."
    cd /root
    git clone git@github.com:xiebaole5/PAUL.git tnho-video
    cd tnho-video
fi

# 停止现有容器
echo "步骤 2: 停止现有容器..."
docker-compose down 2>/dev/null || true

# 检查 .env 文件
echo "步骤 3: 检查配置文件..."
if [ ! -f ".env" ]; then
    echo "创建 .env 文件..."
    cat > .env << 'EOF'
# 火山方舟配置
ARK_API_KEY=39bf20d0-55b5-4957-baa1-02f4529a3076
ARK_BASE_URL=https://ark.cn-beijing.volces.com/api/v3

# 对象存储配置
S3_ENDPOINT=https://tos-s3-cn-beijing.volces.com
S3_ACCESS_KEY_ID=your_access_key_id
S3_SECRET_ACCESS_KEY=your_secret_access_key
S3_BUCKET=tnho-videos
S3_REGION=cn-beijing

# 数据库配置
PGDATABASE_URL=postgresql://postgres:postgres123@db:5432/tnho_video

# 应用配置
APP_HOST=0.0.0.0
APP_PORT=8000
LOG_LEVEL=info
EOF

    echo "⚠️  .env 文件已创建，请根据实际情况修改以下配置："
    echo "   - S3_ACCESS_KEY_ID"
    echo "   - S3_SECRET_ACCESS_KEY"
    echo "   - S3_BUCKET"
    echo ""
    read -p "是否继续？(y/n): " confirm
    if [ "$confirm" != "y" ]; then
        echo "部署已取消"
        exit 0
    fi
fi

# 构建并启动容器
echo "步骤 4: 构建并启动 Docker 容器..."
docker-compose build --no-cache
docker-compose up -d

# 等待服务启动
echo "步骤 5: 等待服务启动..."
sleep 15

# 检查服务状态
echo "步骤 6: 检查服务状态..."
docker-compose ps

# 测试健康检查
echo "步骤 7: 测试健康检查..."
if curl -f http://localhost:8000/health; then
    echo ""
    echo "✅ 服务启动成功！"
else
    echo ""
    echo "❌ 服务启动失败，请查看日志"
    docker-compose logs
    exit 1
fi

echo ""
echo "=========================================="
echo "部署完成！"
echo "=========================================="
echo ""
echo "访问地址："
echo "  API 文档: http://tnho-fasteners.com/docs"
echo "  健康检查: http://tnho-fasteners.com/health"
echo ""
echo "常用命令："
echo "  查看日志: docker-compose logs -f"
echo "  重启服务: docker-compose restart"
echo "  停止服务: docker-compose down"
echo "  更新代码: git pull && docker-compose up -d --build"
echo ""
