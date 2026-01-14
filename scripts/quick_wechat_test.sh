#!/bin/bash
# 企业微信 URL 验证快速测试脚本

echo "================================"
echo "企业微信 URL 验证快速测试"
echo "================================"
echo ""

# 测试健康检查
echo "[1/2] 测试健康检查..."
HEALTH_RESULT=$(curl -s http://localhost:8080/api/wechat/test)
echo "结果: $HEALTH_RESULT"

if echo "$HEALTH_RESULT" | grep -q '"status":"ok"'; then
    echo "✅ 健康检查通过"
else
    echo "❌ 健康检查失败"
    exit 1
fi
echo ""

# 生成测试参数
echo "[2/2] 测试 URL 验证..."
TOKEN="gkIzrwgJI041s52TPAszz2j5iGnpZ4"
TIMESTAMP=$(date +%s)
NONCE=$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 10)
ECHOSTR=$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 16)

# 计算签名
ARR=("$TOKEN" "$TIMESTAMP" "$NONCE" "$ECHOSTR")
SORTED_ARR=$(printf '%s\n' "${ARR[@]}" | sort | tr -d '\n')
SIGNATURE=$(echo -n "$SORTED_ARR" | sha1sum | cut -d' ' -f1)

echo "Timestamp: $TIMESTAMP"
echo "Nonce: $NONCE"
echo "Echostr: $ECHOSTR"
echo "Signature: $SIGNATURE"
echo ""

# 发送验证请求
RESULT=$(curl -s "http://localhost:8080/api/wechat/callback?msg_signature=$SIGNATURE&timestamp=$TIMESTAMP&nonce=$NONCE&echostr=$ECHOSTR")

echo "响应: $RESULT"

if [ "$RESULT" = "\"$ECHOSTR\"" ] || [ "$RESULT" = "$ECHOSTR" ]; then
    echo "✅ URL 验证测试通过"
    echo ""
    echo "================================"
    echo "可以在企业微信后台进行 URL 验证了！"
    echo "================================"
    echo "回调 URL: http://47.110.72.148:8080/api/wechat/callback"
    echo "Token: gkIzrwgJI041s52TPAszz2j5iGnpZ4"
    exit 0
else
    echo "❌ URL 验证测试失败"
    echo "期望返回: $ECHOSTR"
    echo "实际返回: $RESULT"
    exit 1
fi
