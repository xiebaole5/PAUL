#!/bin/bash
# 服务器诊断脚本 - 帮助快速定位问题

echo "========================================"
echo "服务器诊断脚本"
echo "========================================"

# 1. 检查当前目录
echo ""
echo "1️⃣  当前工作目录："
pwd

# 2. 查找 Git 仓库
echo ""
echo "2️⃣  查找 Git 仓库..."
POSSIBLE_PATHS=(
    "/root/PAUL"
    "/home/PAUL"
    "/opt/PAUL"
    "/var/www/PAUL"
    "/workspace/PAUL"
    "$HOME/PAUL"
)

FOUND_REPO=false
for path in "${POSSIBLE_PATHS[@]}"; do
    if [ -d "$path/.git" ]; then
        echo "✅ 找到 Git 仓库: $path"
        echo "   最后更新: $(cd "$path" && git log -1 --format=%cd --date=relative)"
        echo "   当前分支: $(cd "$path" && git branch --show-current)"
        FOUND_REPO=true
        break
    fi
done

if [ "$FOUND_REPO" = false ]; then
    echo "❌ 未找到 PAUL 项目目录"
    echo ""
    echo "请搜索项目目录："
    echo "  find / -name 'PAUL' -type d 2>/dev/null | head -10"
fi

# 3. 检查运行中的服务
echo ""
echo "3️⃣  运行中的服务："
echo "FastAPI 服务："
ps aux | grep -E "uvicorn.*main:app" | grep -v grep || echo "  ⚠️  未找到运行中的 FastAPI 服务"

echo ""
echo "端口占用："
netstat -tlnp 2>/dev/null | grep ":8080" || echo "  ⚠️  8080 端口未被占用"

# 4. 检查 Python 环境
echo ""
echo "4️⃣  Python 环境："
echo "Python 版本: $(python3 --version 2>/dev/null || echo '❌ 未找到 python3')"
echo "Pip 版本: $(pip3 --version 2>/dev/null || echo '❌ 未找到 pip3')"

# 5. 检查 Nginx
echo ""
echo "5️⃣  Nginx 状态："
systemctl is-active nginx 2>/dev/null && echo "✅ Nginx 运行中" || echo "⚠️  Nginx 未运行"

# 6. 测试 API
echo ""
echo "6️⃣  API 连通性测试："
curl -s -o /dev/null -w "✅ 健康检查: http://localhost:8080/health - HTTP %{http_code}\n" http://localhost:8080/health 2>/dev/null || echo "❌ 无法连接到 http://localhost:8080"

# 7. 查看最近的错误日志
echo ""
echo "7️⃣  最近的错误日志："
if [ -f "/tmp/miniprogram_backend.log" ]; then
    echo "后端日志（最后 20 行）："
    tail -20 /tmp/miniprogram_backend.log
else
    echo "⚠️  未找到日志文件"
fi

echo ""
echo "========================================"
echo "诊断完成"
echo "========================================"
