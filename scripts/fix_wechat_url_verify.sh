#!/bin/bash
# 企业微信 URL 验证修复脚本
# 在服务器上运行此脚本

echo "================================"
echo "企业微信 URL 验证修复脚本"
echo "================================"
echo ""

# 1. 停止所有 Python 服务
echo "[1/6] 停止所有 Python 服务..."
pkill -9 -f "python.*app"
pkill -9 -f "uvicorn"
sleep 2
echo "✅ 服务已停止"
echo ""

# 2. 清理 Python 缓存
echo "[2/6] 清理 Python 缓存..."
cd /root/PAUL
find src/ -name "*.pyc" -delete
find src/ -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null
echo "✅ 缓存已清理"
echo ""

# 3. 确认 wechat_callback_simple.py 的内容
echo "[3/6] 检查 wechat_callback_simple.py 的内容..."
if grep -q "直接返回 echostr" src/api/wechat_callback_simple.py; then
    echo "✅ wechat_callback_simple.py 包含正确的返回逻辑"
else
    echo "❌ wechat_callback_simple.py 可能有问题"
    echo "请手动检查该文件"
fi
echo ""

# 4. 确认 enterprise_wechat.py 没有被导入
echo "[4/6] 检查是否有其他文件导入 enterprise_wechat.py..."
if grep -r "from.*enterprise_wechat\|import.*enterprise_wechat" src/ --include="*.py" | grep -v ".pyc" | grep -v "enterprise_wechat.py"; then
    echo "⚠️  发现有文件导入了 enterprise_wechat.py"
    echo "这可能导致路由冲突"
else
    echo "✅ 没有发现导入 enterprise_wechat.py"
fi
echo ""

# 5. 启动 FastAPI 服务
echo "[5/6] 启动 FastAPI 服务..."
nohup venv/bin/python app.py > /tmp/fastapi.log 2>&1 &
echo "✅ 服务已启动"
echo ""

# 6. 等待服务启动并验证
echo "[6/6] 等待服务启动并验证..."
sleep 5

if curl -s http://localhost:8080/health > /dev/null 2>&1; then
    echo "✅ 服务启动成功！"

    echo ""
    echo "================================"
    echo "测试企业微信接口"
    echo "================================"
    curl -s http://localhost:8080/api/wechat/test
    echo ""
    echo ""

    echo "================================"
    echo "企业微信 URL 验证配置"
    echo "================================"
    echo "回调 URL: http://47.110.72.148:8080/api/wechat/callback"
    echo "Token: gkIzrwgJI041s52TPAszz2j5iGnpZ4"
    echo "EncodingAESKey: 2pCDTnGuFB0s8Ianv7WDzhfcyMnmlwb65KDnAbXNFCr"
    echo "Corp ID: ww4564cfcc6de70e6c"
    echo ""
    echo "现在可以在企业微信后台进行 URL 验证了！"
    echo ""

    echo "查看日志："
    echo "  tail -f /tmp/fastapi.log"
else
    echo "❌ 服务启动失败！"
    echo ""
    echo "查看日志："
    echo "  cat /tmp/fastapi.log"
fi

echo ""
echo "================================"
echo "修复完成"
echo "================================"
