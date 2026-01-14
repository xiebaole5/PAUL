"""
测试企业微信签名验证逻辑
"""
import hashlib
import os
from dotenv import load_dotenv

load_dotenv()

WECHAT_TOKEN = os.getenv("WECHAT_TOKEN", "")
echostr = "test123"
timestamp = "123"
nonce = "456"

print("=" * 60)
print("测试企业微信签名验证")
print("=" * 60)
print(f"Token: {WECHAT_TOKEN}")
print(f"echostr: {echostr}")
print(f"timestamp: {timestamp}")
print(f"nonce: {nonce}")
print()

# 按照企业微信文档的签名算法
arr = [WECHAT_TOKEN, timestamp, nonce, echostr]
arr.sort()
s = ''.join(arr)

print(f"排序后的参数: {arr}")
print(f"拼接后的字符串: {s}")
print()

# SHA1 加密
sha1 = hashlib.sha1()
sha1.update(s.encode('utf-8'))
signature = sha1.hexdigest()

print(f"计算的签名: {signature}")
print()
print(f"测试URL:")
print(f"http://47.110.72.148:8080/api/wechat/callback?msg_signature={signature}&timestamp={timestamp}&nonce={nonce}&echostr={echostr}")
