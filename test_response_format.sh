#!/bin/bash

echo "=========================================="
echo "测试 PlainTextResponse 响应格式"
echo "=========================================="

# 测试1: 简单测试
echo ""
echo "测试1: 测试接口（应该返回 JSON）"
echo ""
curl -s -H "Accept: application/json" http://localhost:8080/api/wechat/test
echo ""
echo ""

# 测试2: 测试回调接口（应该返回纯文本）
echo "测试2: 回调接口（应该返回纯文本）"
echo ""
TOKEN="gkIzrwgJI041s52TPAszz2j5iGnpZ4"
TIMESTAMP=$(date +%s)
NONCE=12345
ECHOSTR="test123"

# 计算签名
SIGNATURE=$(python3 -c "
import hashlib
arr = ['$TOKEN', '$TIMESTAMP', '$NONCE', '$ECHOSTR']
arr.sort()
s = ''.join(arr)
sha1 = hashlib.sha1()
sha1.update(s.encode('utf-8'))
print(sha1.hexdigest())
")

URL="http://localhost:8080/api/wechat/callback?msg_signature=$SIGNATURE&timestamp=$TIMESTAMP&nonce=$NONCE&echostr=$ECHOSTR"

echo "请求 URL: $URL"
echo ""
echo "响应内容："
echo "---"
curl -v -s "$URL"
echo ""
echo "---"
echo ""

# 检查响应头
echo "测试3: 检查响应头"
echo ""
curl -s -I "$URL"
echo ""

echo "=========================================="
echo "测试完成"
echo "=========================================="
