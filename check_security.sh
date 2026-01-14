#!/bin/bash

echo "=== 检查安全配置 ==="
echo ""

echo "1. 检查8080端口的连接状态："
netstat -an | grep ":8080" | awk '{print $6}' | sort | uniq -c
echo ""

echo "2. 检查最近建立的连接："
ss -tn state established | grep ":8080" | head -5
echo ""

echo "3. 检查防火墙规则（如果有的话）："
which ufw >/dev/null 2>&1 && ufw status || echo "ufw 未安装"
which firewall-cmd >/dev/null 2>&1 && firewall-cmd --list-all || echo "firewalld 未安装"
echo ""

echo "4. 检查云服务商安全组（需要手动在阿里云控制台查看）："
echo "   请检查阿里云安全组规则是否允许 8080 端口入站"
echo ""

echo "5. 测试从服务器内部访问："
curl -s -o /dev/null -w "内部访问8080端口: %{http_code}\n" http://127.0.0.1:8080/health
echo ""

echo "6. 测试从外网访问（模拟企业微信）："
curl -s -o /dev/null -w "外网访问8080端口: %{http_code}\n" http://47.110.72.148:8080/health
echo ""
