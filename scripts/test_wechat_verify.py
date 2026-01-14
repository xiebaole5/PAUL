#!/usr/bin/env python3
"""
测试企业微信 URL 验证接口
模拟企业微信发送的验证请求
"""
import requests
import hashlib
import time
import random
import string

# 企业微信配置
WECHAT_TOKEN = "gkIzrwgJI041s52TPAszz2j5iGnpZ4"
API_URL = "http://47.110.72.148:8080/api/wechat/callback"

def generate_random_string(length=16):
    """生成随机字符串"""
    return ''.join(random.choices(string.ascii_letters + string.digits, k=length))

def test_wechat_url_verify():
    """测试企业微信 URL 验证接口"""
    # 生成参数
    timestamp = str(int(time.time()))
    nonce = generate_random_string(10)
    echostr = generate_random_string(16)

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
    print(f"请求参数:")
    for k, v in params.items():
        if k == "echostr":
            print(f"  {k}: {v}")
        else:
            print(f"  {k}: {v}")
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
            print("现在可以在企业微信后台进行 URL 验证了！")
            print(f"回调 URL: {API_URL}")
            print(f"Token: {WECHAT_TOKEN}")
            return True
        else:
            print("❌ 测试失败！")
            print(f"   期望返回: {echostr}")
            print(f"   实际返回: {response.text}")
            return False

    except Exception as e:
        print(f"❌ 请求失败: {str(e)}")
        return False

    print("=" * 60)

if __name__ == "__main__":
    test_wechat_url_verify()
