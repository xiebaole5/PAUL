#!/usr/bin/env python3
"""
Cloudflare Origin Certificate 生成脚本

使用方法：
    python generate_cloudflare_cert.py --api-token YOUR_API_TOKEN --domain tnho-fasteners.com

前置要求：
    1. 安装依赖：pip install pyyaml requests
    2. 在 Cloudflare 控制台获取 API Token
"""

import argparse
import base64
import os
import sys
from datetime import datetime

try:
    import requests
except ImportError:
    print("错误：缺少 requests 库")
    print("请运行：pip install requests")
    sys.exit(1)

# Cloudflare API 配置
CLOUDFLARE_API_URL = "https://api.cloudflare.com/client/v4"


def generate_certificate(api_token, domain, validity_days=5475):
    """
    生成 Cloudflare Origin Certificate

    参数:
        api_token: Cloudflare API Token
        domain: 域名
        validity_days: 证书有效期（天），默认 5475 天（15 年）

    返回:
        证书和私钥
    """
    headers = {
        "Authorization": f"Bearer {api_token}",
        "Content-Type": "application/json",
    }

    # 准备证书请求
    payload = {
        "type": "origin-ecc",  # 使用 ECC 证书（更安全、性能更好）
        "hostnames": [
            f"*.{domain}",
            domain,
        ],
        "request_type": "origin-rsa",  # RSA 兼容性更好
        "validity": validity_days,
    }

    print(f"正在为域名 {domain} 生成 Origin Certificate...")
    print(f"有效期：{validity_days} 天")

    # 发送请求
    response = requests.post(
        f"{CLOUDFLARE_API_URL}/certificates",
        headers=headers,
        json=payload,
    )

    if response.status_code != 200:
        print(f"错误：生成证书失败")
        print(f"状态码：{response.status_code}")
        print(f"响应：{response.text}")
        sys.exit(1)

    data = response.json()

    if not data.get("success"):
        print(f"错误：API 返回失败")
        print(f"错误信息：{data.get('errors')}")
        sys.exit(1)

    result = data["result"]

    print("✅ 证书生成成功！")

    return result["certificate"], result["private_key"]


def save_certificate(certificate, private_key, output_dir="certs"):
    """
    保存证书和私钥到文件

    参数:
        certificate: 证书内容
        private_key: 私钥内容
        output_dir: 输出目录
    """
    # 创建输出目录
    os.makedirs(output_dir, exist_ok=True)

    # 证书文件路径
    cert_path = os.path.join(output_dir, "cloudflare-origin.crt")
    key_path = os.path.join(output_dir, "cloudflare-origin.key")

    # 保存证书
    with open(cert_path, "w") as f:
        f.write(certificate)
    print(f"✅ 证书已保存：{cert_path}")

    # 保存私钥
    with open(key_path, "w") as f:
        f.write(private_key)
    print(f"✅ 私钥已保存：{key_path}")

    return cert_path, key_path


def display_instructions(cert_path, key_path):
    """
    显示下一步操作说明
    """
    print("\n" + "=" * 60)
    print("📋 下一步操作说明")
    print("=" * 60)
    print("\n1. 上传证书到服务器：")
    print(f"   scp {cert_path} root@47.110.72.148:/etc/nginx/ssl/tnho-origin.crt")
    print(f"   scp {key_path} root@47.110.72.148:/etc/nginx/ssl/tnho-origin.key")
    print("\n2. SSH 登录服务器：")
    print("   ssh root@47.110.72.148")
    print("\n3. 重启 Nginx：")
    print("   nginx -t && nginx -s reload")
    print("\n4. 测试证书：")
    print("   curl -I https://tnho-fasteners.com")
    print("\n5. 检查 Cloudflare SSL 设置：")
    print("   - 登录 https://dash.cloudflare.com/")
    print("   - 选择 tnho-fasteners.com 域名")
    print("   - 进入 SSL/TLS -> Overview")
    print("   - 确保模式为 'Full' 或 'Full (strict)'")
    print("\n6. 测试小程序：")
    print("   - 打开微信开发者工具")
    print("   - 刷新小程序")
    print("   - 应该可以正常访问 API 了")
    print("=" * 60)


def main():
    parser = argparse.ArgumentParser(
        description="生成 Cloudflare Origin Certificate"
    )
    parser.add_argument(
        "--api-token",
        required=True,
        help="Cloudflare API Token",
    )
    parser.add_argument(
        "--domain",
        default="tnho-fasteners.com",
        help="域名（默认：tnho-fasteners.com）",
    )
    parser.add_argument(
        "--validity-days",
        type=int,
        default=5475,
        help="证书有效期（天，默认：5475 天）",
    )
    parser.add_argument(
        "--output-dir",
        default="certs",
        help="输出目录（默认：certs）",
    )

    args = parser.parse_args()

    # 生成证书
    certificate, private_key = generate_certificate(
        args.api_token,
        args.domain,
        args.validity_days,
    )

    # 保存证书
    cert_path, key_path = save_certificate(
        certificate,
        private_key,
        args.output_dir,
    )

    # 显示说明
    display_instructions(cert_path, key_path)


if __name__ == "__main__":
    main()
