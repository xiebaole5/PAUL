#!/usr/bin/env python3
"""
测试企业微信 URL 验证接口（服务器版本）
"""
import requests
import hashlib
import time

# 企业微信配置
WECHAT_TOKEN = "gkIzrwgJI041s52TPAszz2j5iGnpZ4"
API_URL = "http://localhost:8080/api/wechat/callback"

def test_wechat_url_verify():
    """测试企业微信 URL 验证接口"""
    # 生成参数
    timestamp = str(int(time.time()))
    nonce = "test123"
    echostr = "test_echostr_" + timestamp

    print("=" * 60)
    print("测试企业微信 URL 验证接口")
    print("=" * 60)
    print(f"Timestamp: {timestamp}")
    print(f"Nonce: {nonce}")
    print(f"Echostr: {echostr}")
    print()

    # 计算签名
    arr = [WECHAT_TOKEN, timestamp, nonce, echostr]
    arr.sort()
    s = ''.join(arr)
    sha1 = hashlib.sha1()
    sha1.update(s.encode('utf-8'))
    signature = sha1.hexdigest()

    print(f"计算的签名: {signature}")
    print()

    # 发送请求
    params = {
        "msg_signature": signature,
        "timestamp": timestamp,
        "nonce": nonce,
        "echostr": echostr
    }

    print(f"请求 URL: {API_URL}")
    print()

    try:
        response = requests.get(API_URL, params=params, timeout=10)
        print(f"HTTP 状态码: {response.status_code}")
        print(f"响应类型: {response.headers.get('Content-Type', 'N/A')}")
        print(f"响应内容: {response.text}")
        print()

        # 验证返回值
        if response.status_code == 200 and response.text == echostr:
            print("✅ 测试通过！")
            print(f"   服务器正确返回了 echostr: {echostr}")
            print()
            print("=" * 60)
            print("现在可以在企业微信后台进行 URL 验证了！")
            print("=" * 60)
            print()
            print("企业微信配置信息：")
            print(f"  回调 URL: http://47.110.72.148:8080/api/wechat/callback")
            print(f"  Token: {WECHAT_TOKEN}")
            print(f"  EncodingAESKey: 2pCDTnGuFB0s8Ianv7WDzhfcyMnmlwb65KDnAbXNFCr")
            print()
            print("操作步骤：")
            print("  1. 打开企业微信后台管理")
            print("  2. 进入「应用管理」→「TNHO全能营销助手」→「设置」")
            print("  3. 配置「接收消息」的回调 URL")
            print("  4. 输入上述信息")
            print("  5. 点击「验证」按钮")
            print()
            print("查看验证日志：")
            echo "  tail -f /tmp/fastapi.log"
            return True
        else:
            print("❌ 测试失败！")
            print(f"   期望返回: {echostr}")
            print(f"   实际返回: {response.text}")
            print()
            print("请检查日志：")
            echo "  tail -n 50 /tmp/fastapi.log"
            return False

    except Exception as e:
        print(f"❌ 请求失败: {str(e)}")
        return False

if __name__ == "__main__":
    test_wechat_url_verify()
