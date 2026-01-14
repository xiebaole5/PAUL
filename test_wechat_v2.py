#!/usr/bin/env python3
"""
企业微信 URL 验证测试脚本 V2
"""
import hashlib

# 企业微信配置
TOKEN = "gkIzrwgJI041s52TPAszz2j5iGnpZ4"

# 从日志中提取的参数（URL 编码）
msg_signature = "e368c60df0f3b47a406f38c1c2e1d6510c4d2834"
timestamp = "1768413552"
nonce = "1767981738"
# URL 编码的 echostr
echostr_encoded = "SB7WKF7UPHcgHP4%2FzZjCwh5o9%2B3G%2F45L8HJ2uinYQj%2BF%2F2aVojYIssntln1p9ELFlx9MlJUK02Pqhr3YOmJ78A%3D%3D"

print("=" * 60)
print("企业微信 URL 验证测试 V2")
print("=" * 60)

# 方法1：使用 URL 编码的 echostr
arr1 = [TOKEN, timestamp, nonce, echostr_encoded]
arr1.sort()
s1 = ''.join(arr1)
sha1_1 = hashlib.sha1()
sha1_1.update(s1.encode('utf-8'))
signature1 = sha1_1.hexdigest()

print("\n方法1：使用 URL 编码的 echostr")
print(f"排序后: {arr1}")
print(f"拼接后: {s1}")
print(f"计算签名: {signature1}")
print(f"期望签名: {msg_signature}")
print(f"匹配: {'✅' if signature1 == msg_signature else '❌'}")

# 方法2：使用 URL 解码的 echostr
from urllib.parse import unquote
echostr_decoded = unquote(echostr_encoded)
arr2 = [TOKEN, timestamp, nonce, echostr_decoded]
arr2.sort()
s2 = ''.join(arr2)
sha1_2 = hashlib.sha1()
sha1_2.update(s2.encode('utf-8'))
signature2 = sha1_2.hexdigest()

print("\n方法2：使用 URL 解码的 echostr")
print(f"排序后: {arr2}")
print(f"拼接后: {s2}")
print(f"计算签名: {signature2}")
print(f"期望签名: {msg_signature}")
print(f"匹配: {'✅' if signature2 == msg_signature else '❌'}")

print("\n" + "=" * 60)
print(f"echostr (编码): {echostr_encoded}")
print(f"echostr (解码): {echostr_decoded}")
print("=" * 60)

# 结论
if signature1 == msg_signature:
    print("\n✅ 结论：应该使用 URL 编码的 echostr 进行签名验证")
    print(f"返回值应该使用: {'解码后的 echostr' if signature2 == msg_signature else '编码后的 echostr'}")
elif signature2 == msg_signature:
    print("\n✅ 结论：应该使用 URL 解码的 echostr 进行签名验证")
    print(f"返回值应该使用: 解码后的 echostr")
else:
    print("\n❌ 两种方法都不匹配，需要进一步检查")
