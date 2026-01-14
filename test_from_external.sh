#!/bin/bash

echo "=========================================="
echo "从外部访问8080端口"
echo "=========================================="
echo ""

# 从本地访问（作为对比）
echo "1. 从本地访问 localhost:8080"
curl -s "http://localhost:8080/api/wechat/test" > /dev/null
echo ""
sleep 1

# 从公网IP访问
echo "2. 从公网访问 47.110.72.148:8080"
curl -s "http://47.110.72.148:8080/api/wechat/test" > /dev/null
echo ""
sleep 1

# 查看最近的日志
echo ""
echo "=========================================="
echo "最近的日志（客户端IP）:"
echo "=========================================="
tail -20 fastapi.log | grep "客户端 IP"
