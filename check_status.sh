#!/bin/bash

echo "=========================================="
echo "企业微信验证 - 状态检查"
echo "=========================================="
echo ""

# 检查服务进程
echo "1. 服务进程状态:"
if ps aux | grep -v grep | grep "python3 app.py" > /dev/null; then
    PID=$(ps aux | grep -v grep | grep "python3 app.py" | awk '{print $2}')
    echo "   ✅ 服务运行中 (PID: $PID)"
else
    echo "   ❌ 服务未运行"
    echo ""
    echo "启动服务:"
    echo "   cd /workspace/projects"
    echo "   bash restart_service.sh"
    exit 1
fi

# 检查端口
echo ""
echo "2. 端口监听状态:"
if netstat -tlnp 2>/dev/null | grep ":8080 " > /dev/null; then
    echo "   ✅ 8080端口正常监听"
else
    echo "   ❌ 8080端口未监听"
fi

# 测试接口
echo ""
echo "3. 接口测试:"
RESULT=$(curl -s "http://localhost:8080/api/wechat/test" 2>/dev/null)
if echo "$RESULT" | grep -q "ok"; then
    echo "   ✅ 本地接口正常"
else
    echo "   ❌ 本地接口异常"
fi

RESULT=$(curl -s "http://47.110.72.148:8080/api/wechat/test" 2>/dev/null)
if echo "$RESULT" | grep -q "ok"; then
    echo "   ✅ 公网接口正常"
else
    echo "   ⚠️  公网接口可能异常"
fi

# 检查日志文件
echo ""
echo "4. 日志文件:"
if [ -f "fastapi.log" ]; then
    SIZE=$(du -h fastapi.log | cut -f1)
    LINES=$(wc -l < fastapi.log)
    echo "   ✅ 日志文件存在 (大小: $SIZE, 行数: $LINES)"
else
    echo "   ❌ 日志文件不存在"
fi

# 显示最近的日志
echo ""
echo "=========================================="
echo "最近的日志 (最后10行):"
echo "=========================================="
if [ -f "fastapi.log" ]; then
    tail -10 fastapi.log
fi

echo ""
echo "=========================================="
echo "操作建议:"
echo "=========================================="
echo ""
echo "开始监控企业微信验证请求:"
echo "  bash watch.sh"
echo ""
echo "或者查看实时日志:"
echo "  tail -f fastapi.log"
echo ""
echo "在企业微信后台验证URL:"
echo "  URL: http://47.110.72.148:8080/api/wechat/callback"
echo "  Token: gkIzrwgJI041s52TPAszz2j5iGnpZ4"
echo ""
echo "=========================================="
