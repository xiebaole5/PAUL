#!/bin/bash
# 将本地最新 app.py 上传到服务器

SERVER="root@47.110.72.148"

echo "======================================"
echo "上传最新 app.py 到服务器"
echo "======================================"

# 1. 检查本地文件
if [ ! -f "src/api/app.py" ]; then
    echo "❌ 本地文件不存在: src/api/app.py"
    exit 1
fi

echo "✅ 找到本地文件: src/api/app.py"

# 2. 上传到服务器
echo "正在上传..."
scp src/api/app.py $SERVER:/root/tnho-video-api/app.py.new

if [ $? -eq 0 ]; then
    echo "✅ 文件上传成功"
else
    echo "❌ 文件上传失败"
    exit 1
fi

# 3. 在服务器上替换并重启
echo ""
echo "在服务器上替换文件并重启..."
ssh $SERVER << 'REMOTE_COMMANDS'
cd /root/tnho-video-api

# 备份旧文件
cp app.py app.py.backup.old

# 替换为新文件
mv app.py.new app.py

# 检查路由
echo "检查新版本路由:"
grep -c "@app\." app.py

# 重启容器
docker-compose down
docker-compose up -d

# 等待启动
sleep 10

# 检查 API 端点
echo "检查 API 端点:"
curl -s http://localhost:8000/openapi.json | grep -o '"/[^"]*"' | head -10
REMOTE_COMMANDS

echo ""
echo "======================================"
echo "上传完成！"
echo "======================================"
