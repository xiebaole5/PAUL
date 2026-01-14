#!/bin/bash

echo "=========================================="
echo "企业微信 URL 验证 - 监控和诊断工具"
echo "=========================================="
echo ""
echo "服务状态检查："
echo "----------------------------------------"

# 检查服务是否运行
if ps aux | grep -v grep | grep "python app.py" > /dev/null; then
    echo "✅ 服务运行中"
    ps aux | grep -v grep | grep "python app.py" | awk '{print "  PID:", $2, "  CPU:", $3"%", "  MEM:", $4"%"}'
else
    echo "❌ 服务未运行"
    echo ""
    echo "启动服务："
    echo "  python3 app.py > fastapi.log 2>&1 &"
    exit 1
fi

# 检查端口
if lsof -i :8080 > /dev/null; then
    echo "✅ 端口 8080 正常监听"
else
    echo "❌ 端口 8080 未监听"
    exit 1
fi

# 测试本地访问
echo ""
echo "本地访问测试："
echo "----------------------------------------"
LOCAL_TEST=$(curl -s http://localhost:8080/api/wechat/test)
if [ $? -eq 0 ]; then
    echo "✅ 本地访问正常"
    echo "  响应: $LOCAL_TEST"
else
    echo "❌ 本地访问失败"
    exit 1
fi

# 测试公网访问
echo ""
echo "公网访问测试："
echo "----------------------------------------"
PUBLIC_TEST=$(curl -s http://47.110.72.148:8080/api/wechat/test)
if [ $? -eq 0 ]; then
    echo "✅ 公网访问正常"
    echo "  响应: $PUBLIC_TEST"
else
    echo "❌ 公网访问失败"
    echo "  可能原因："
    echo "  1. 阿里云安全组未开放 8080 端口"
    echo "  2. 云服务器防火墙阻止访问"
    echo ""
    echo "请检查："
    echo "  - 阿里云控制台：安全组 → 配置规则 → 添加 8080 端口入站规则"
fi

echo ""
echo "=========================================="
echo "现在可以开始监控日志了"
echo "=========================================="
echo ""
echo "实时监控日志（查看所有请求）："
echo "  tail -f fastapi.log"
echo ""
echo "只监控企业微信相关日志："
echo "  tail -f fastapi.log | grep -A 10 \"企业微信\""
echo ""
echo "监控中间件日志（查看详细请求信息）："
echo "  tail -f fastapi.log | grep \"middleware\""
echo ""
echo "=========================================="
echo "下一步操作"
echo "=========================================="
echo ""
echo "1. 保持日志监控运行："
echo "   tail -f fastapi.log"
echo ""
echo "2. 在企业微信管理后台重新进行 URL 验证："
echo "   - 登录企业微信管理后台"
echo "   - 进入\"应用管理\" → \"自建应用\" → \"TNHO全能营销助手\""
echo "   - 找到\"接收消息\" → \"设置API接收\""
echo "   - 输入回调 URL: http://47.110.72.148:8080/api/wechat/callback"
echo "   - 输入 Token: gkIzrwgJI041s52TPAszz2j5iGnpZ4"
echo "   - 点击\"保存\""
echo ""
echo "3. 查看日志中是否有企业微信的请求记录"
echo ""
echo "=========================================="
