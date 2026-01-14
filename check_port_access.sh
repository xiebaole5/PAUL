#!/bin/bash

echo "=========================================="
echo "检查服务器端口开放情况"
echo "=========================================="

# 1. 检查端口监听
echo ""
echo "1. 检查端口监听..."
lsof -i :8080 | grep LISTEN || echo "❌ 端口 8080 未监听"

# 2. 检查防火墙状态
echo ""
echo "2. 检查防火墙状态..."
if command -v firewall-cmd &> /dev/null; then
    firewall-cmd --state
    echo "开放的端口:"
    firewall-cmd --list-ports
elif command -v ufw &> /dev/null; then
    ufw status
else
    echo "未检测到防火墙工具"
fi

# 3. 检查 iptables 规则
echo ""
echo "3. 检查 iptables 规则..."
iptables -L -n | grep 8080 || echo "未找到 8080 端口的 iptables 规则"

# 4. 检查 netstat
echo ""
echo "4. 检查 netstat..."
netstat -tlnp | grep 8080 || echo "❌ netstat 未发现 8080 端口"

# 5. 测试本地访问
echo ""
echo "5. 测试本地访问..."
curl -s -o /dev/null -w "本地访问状态码: %{http_code}\n" http://localhost:8080/api/wechat/test

# 6. 获取公网 IP
echo ""
echo "6. 服务器网络信息..."
echo "本地 IP 地址:"
ip addr show | grep "inet " | grep -v "127.0.0.1"

# 7. 测试外网访问（使用 curl 访问公网 IP）
echo ""
echo "7. 测试外网访问..."
curl -s -o /dev/null -w "公网 IP 访问状态码: %{http_code}\n" http://47.110.72.148:8080/api/wechat/test || echo "❌ 公网 IP 访问失败"

# 8. 检查 Nginx 配置
echo ""
echo "8. 检查 Nginx 配置..."
if command -v nginx &> /dev/null; then
    nginx -t
    echo "Nginx 配置文件位置:"
    nginx -V 2>&1 | grep "configure arguments:" | sed 's/.*--conf-path=\([^ ]*\).*/\1/'
fi

echo ""
echo "=========================================="
echo "检查完成"
echo "=========================================="
