#!/bin/bash

echo "=== 端口连接测试 ==="
echo ""
echo "1. 测试内网 IP 9.128.84.91:8080"
timeout 5 curl -s http://9.128.84.91:8080/health && echo " ✅ 成功" || echo " ❌ 失败"
echo ""

echo "2. 测试本地 127.0.0.1:8080"
timeout 5 curl -s http://127.0.0.1:8080/health && echo " ✅ 成功" || echo " ❌ 失败"
echo ""

echo "3. 测试公网 IP 115.191.1.219:8080（会超时）"
timeout 5 curl -s http://115.191.1.219:8080/health && echo " ✅ 成功" || echo " ❌ 超时（端口未开放）"
echo ""

echo "4. 测试公网 IP 47.110.72.148:8080"
timeout 5 curl -s http://47.110.72.148:8080/health && echo " ✅ 成功" || echo " ❌ 失败"
echo ""

