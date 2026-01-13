#!/bin/bash
# TNHO 视频生成服务部署脚本
# 在阿里云服务器 47.110.72.148 上执行

set -e

echo "=========================================="
echo "TNHO 视频生成服务部署脚本"
echo "=========================================="

# 停止现有容器
echo "步骤 1: 停止现有容器..."
cd /root/tnho-video || mkdir -p /root/tnho-video && cd /root/tnho-video
docker-compose down 2>/dev/null || true

# 备份现有代码（如果有）
if [ -d "src" ]; then
    echo "步骤 2: 备份现有代码..."
    tar -czf backup-$(date +%Y%m%d-%H%M%S).tar.gz src/
fi

# 创建项目目录结构
echo "步骤 3: 创建目录结构..."
mkdir -p src/agents src/api src/llm src/storage/{database,memory,s3} src/utils/messages src/graphs config logs scripts

# 检查是否上传了代码压缩包
if [ -f "tnho-complete-code.tar.gz" ]; then
    echo "步骤 4: 解压代码压缩包..."
    tar -xzf tnho-complete-code.tar.gz
    echo "代码解压完成"
else
    echo "错误: 未找到 tnho-complete-code.tar.gz"
    echo "请先上传代码压缩包到 /root/tnho-video 目录"
    exit 1
fi

# 检查 .env 文件
if [ ! -f ".env" ]; then
    echo "步骤 5: 创建 .env 文件..."
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
    echo "⚠️  .env 文件已创建，请根据实际情况修改 S3 和数据库配置"
fi

# 构建并启动容器
echo "步骤 6: 构建并启动 Docker 容器..."
docker-compose down 2>/dev/null || true
docker-compose build
docker-compose up -d

# 等待服务启动
echo "步骤 7: 等待服务启动..."
sleep 10

# 检查服务状态
echo "步骤 8: 检查服务状态..."
docker-compose ps

# 测试健康检查
echo "步骤 9: 测试健康检查..."
if curl -f http://localhost:8000/health; then
    echo "✅ 服务启动成功！"
else
    echo "❌ 服务启动失败，请查看日志"
    docker-compose logs
    exit 1
fi

echo ""
echo "=========================================="
echo "部署完成！"
echo "=========================================="
echo "API 文档: http://tnho-fasteners.com/docs"
echo "健康检查: http://tnho-fasteners.com/health"
echo ""
echo "常用命令:"
echo "  查看日志: docker-compose logs -f"
echo "  重启服务: docker-compose restart"
echo "  停止服务: docker-compose down"
echo ""
