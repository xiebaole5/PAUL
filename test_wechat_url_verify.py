#!/usr/bin/env python3
"""
测试企业微信URL验证
模拟企业微信的签名计算和验证
"""
import hashlib
import sys
import os

# 添加项目路径
sys.path.insert(0, '/workspace/projects')
sys.path.insert(0, '/workspace/projects/src')

from dotenv import load_dotenv
load_dotenv('/workspace/projects/.env')

WECHAT_TOKEN = os.getenv("WECHAT_TOKEN")

def calculate_signature(token, timestamp, nonce):
    """计算企业微信签名"""
    arr = [token, timestamp, nonce]
    arr.sort()
    s = ''.join(arr)
    sha1 = hashlib.sha1()
    sha1.update(s.encode('utf-8'))
    return sha1.hexdigest()

def test_url_verify():
    """测试URL验证"""
    # 模拟参数
    timestamp = "1736880000"
    nonce = "123456789"
    echostr = "test_echo_str_abc123"

    # 计算签名
    signature = calculate_signature(WECHAT_TOKEN, timestamp, nonce)

    print("=" * 60)
    print("企业微信URL验证测试")
    print("=" * 60)
    print(f"Token: {WECHAT_TOKEN}")
    print(f"Timestamp: {timestamp}")
    print(f"Nonce: {nonce}")
    print(f"Echostr: {echostr}")
    print(f"计算的签名: {signature}")
    print("=" * 60)

    # 构造URL
    url = f"http://localhost:8080/api/wechat/callback?msg_signature={signature}&timestamp={timestamp}&nonce={nonce}&echostr={echostr}"

    print(f"\n测试URL:")
    print(url)
    print("\n发送请求...")

    # 发送请求
    import requests
    try:
        response = requests.get(url)
        print(f"\n响应状态码: {response.status_code}")
        print(f"响应内容: {response.text}")
        print(f"响应头Content-Type: {response.headers.get('Content-Type')}")

        if response.status_code == 200 and echostr in response.text:
            print("\n✅ 验证成功！")
            return True
        else:
            print(f"\n❌ 验证失败！")
            return False
    except Exception as e:
        print(f"\n❌ 请求失败: {e}")
        return False

if __name__ == "__main__":
    success = test_url_verify()
    sys.exit(0 if success else 1)
