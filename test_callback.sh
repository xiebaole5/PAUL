#!/bin/bash

echo "=========================================="
echo "测试企业微信回调接口"
echo "=========================================="

# 企业微信配置
TOKEN="gkIzrwgJI041s52TPAszz2j5iGnpZ4"
TIMESTAMP=$(date +%s)
NONCE=$RANDOM
ECHOSTR="test123"

# 计算签名
# 注意：使用 echostr（FastAPI 会自动解码）
SIGN_STR="$TOKEN$TIMESTAMP$NONCE$ECHOSTR"
SIGN_STR=$(echo -n "$SIGN_STR" | tr -d '\n' | sort | tr -d '\n')

# Python 计算签名
SIGNATURE=$(python3 -c "
import hashlib
arr = ['$TOKEN', '$TIMESTAMP', '$NONCE', '$ECHOSTR']
arr.sort()
s = ''.join(arr)
sha1 = hashlib.sha1()
sha1.update(s.encode('utf-8'))
print(sha1.hexdigest())
")

echo "参数："
echo "  Token: $TOKEN"
echo "  Timestamp: $TIMESTAMP"
echo "  Nonce: $NONCE"
echo "  Echostr: $ECHOSTR"
echo "  签名: $SIGNATURE"
echo ""

# 测试接口
URL="http://localhost:8080/api/wechat/callback?msg_signature=$SIGNATURE&timestamp=$TIMESTAMP&nonce=$NONCE&echostr=$ECHOSTR"

echo "请求 URL: $URL"
echo ""

curl -s "$URL"
echo ""

echo ""
echo "=========================================="
echo "测试完成"
echo "=========================================="
