#!/bin/bash

echo "=========================================="
echo "全面诊断工具"
echo "=========================================="
echo ""

# 1. 检查服务状态
echo "【1/6】服务状态检查"
echo "----------------------------------------"
if ps aux | grep -v grep | grep "python3 app.py" > /dev/null; then
    PID=$(ps aux | grep -v grep | grep "python3 app.py" | awk '{print $2}')
    UPTIME=$(ps -p $PID -o etime= | tr -d ' ')
    echo "✅ 服务运行正常"
    echo "   PID: $PID"
    echo "   运行时间: $UPTIME"
else
    echo "❌ 服务未运行"
    exit 1
fi

# 2. 检查端口
echo ""
echo "【2/6】端口检查"
echo "----------------------------------------"
if netstat -tlnp 2>/dev/null | grep ":8080 " > /dev/null; then
    echo "✅ 8080端口正在监听"
else
    echo "❌ 8080端口未监听"
fi

# 3. 本地测试
echo ""
echo "【3/6】本地接口测试"
echo "----------------------------------------"
LOCAL_RESULT=$(curl -s --max-time 3 "http://localhost:8080/api/wechat/test")
if echo "$LOCAL_RESULT" | grep -q "ok"; then
    echo "✅ 本地接口正常"
else
    echo "❌ 本地接口异常"
    echo "   返回: $LOCAL_RESULT"
fi

# 4. 公网测试
echo ""
echo "【4/6】公网接口测试"
echo "----------------------------------------"
echo "测试地址: http://47.110.72.148:8080/api/wechat/test"
PUBLIC_RESULT=$(curl -s --max-time 5 "http://47.110.72.148:8080/api/wechat/test" 2>&1)
if echo "$PUBLIC_RESULT" | grep -q "ok"; then
    echo "✅ 公网接口正常"
elif echo "$PUBLIC_RESULT" | grep -q "timeout"; then
    echo "⚠️  公网接口超时"
    echo "   可能原因: 防火墙或网络问题"
else
    echo "❌ 公网接口异常"
    echo "   返回: $PUBLIC_RESULT"
fi

# 5. 检查最近的请求
echo ""
echo "【5/6】最近的请求日志"
echo "----------------------------------------"
RECENT_REQUESTS=$(tail -50 fastapi.log | grep "收到请求" | tail -5)
if [ -n "$RECENT_REQUESTS" ]; then
    echo "最近的请求:"
    echo "$RECENT_REQUESTS"
else
    echo "没有找到请求日志"
fi

# 检查是否有企业微信的请求
WECHAT_REQUESTS=$(tail -100 fastapi.log | grep "企业微信")
if [ -n "$WECHAT_REQUESTS" ]; then
    echo ""
    echo "企业微信相关日志:"
    echo "$WECHAT_REQUESTS"
fi

# 6. 检查服务器信息
echo ""
echo "【6/6】服务器信息"
echo "----------------------------------------"
echo "主机名: $(hostname)"
echo "内网IP: $(hostname -I | awk '{print $1}')"
echo "进程数: $(ps aux | grep "python3 app.py" | grep -v grep | wc -l)"
echo "日志大小: $(du -h fastapi.log | cut -f1)"
echo "日志行数: $(wc -l < fastapi.log)"

# 诊断结果
echo ""
echo "=========================================="
echo "诊断结果"
echo "=========================================="

# 检查所有测试是否通过
PASS=0
FAIL=0

ps aux | grep -v grep | grep "python3 app.py" > /dev/null && PASS=$((PASS+1)) || FAIL=$((FAIL+1))
netstat -tlnp 2>/dev/null | grep ":8080 " > /dev/null && PASS=$((PASS+1)) || FAIL=$((FAIL+1))
echo "$LOCAL_RESULT" | grep -q "ok" && PASS=$((PASS+1)) || FAIL=$((FAIL+1))
echo "$PUBLIC_RESULT" | grep -q "ok" && PASS=$((PASS+1)) || FAIL=$((FAIL+1))

echo "通过: $PASS"
echo "失败: $FAIL"
echo ""

if [ $FAIL -eq 0 ]; then
    echo "✅ 所有测试通过，服务正常运行"
    echo ""
    echo "下一步操作:"
    echo "  1. 在企业微信后台验证URL"
    echo "  2. 同时运行: bash watch.sh"
    echo "  3. 观察日志看是否有请求到达"
else
    echo "⚠️  发现问题，请检查上述详细信息"
    echo ""
    echo "可能的原因:"
    echo "  1. 服务未正常启动"
    echo "  2. 端口被占用"
    echo "  3. 网络问题"
    echo "  4. 防火墙拦截"
fi

echo ""
echo "=========================================="
