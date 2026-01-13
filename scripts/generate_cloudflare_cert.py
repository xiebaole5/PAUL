#!/usr/bin/env python3
"""
Cloudflare Origin Certificate 生成脚本
使用 Cloudflare API 自动创建 Origin Certificate

使用说明：
1. 需要提供 Cloudflare API Token（权限：Zone - SSL and Certificates - Edit）
2. 脚本会自动创建证书并保存到文件
3. 生成的证书有效期为 15 年

生成文件：
- cloudflare-origin.pem (证书文件)
- cloudflare-origin-key.pem (私钥文件)
"""

import os
import sys
import requests
import argparse
from pathlib import Path
from datetime import datetime


def generate_origin_certificate(api_token, zone_id, hostnames, validity_days=5475):
    """
    生成 Cloudflare Origin Certificate

    Args:
        api_token: Cloudflare API Token
        zone_id: Cloudflare Zone ID
        hostnames: 域名列表，如 ["tnho-fasteners.com", "*.tnho-fasteners.com"]
        validity_days: 证书有效期（默认 15 年 = 5475 天）

    Returns:
        dict: 包含证书和私钥的字典
    """
    headers = {
        "Authorization": f"Bearer {api_token}",
        "Content-Type": "application/json"
    }

    payload = {
        "hostnames": hostnames,
        "requested_validity": validity_days,
        "request_type": "origin-ecc",  # 使用 ECC 证书，性能更好
        "certificate_authority": "cloudflare"  # 使用 Cloudflare 签发
    }

    api_url = f"https://api.cloudflare.com/client/v4/zones/{zone_id}/origin/ca/certificate"

    try:
        print(f"正在生成 Origin Certificate...")
        print(f"域名: {', '.join(hostnames)}")
        print(f"有效期: {validity_days} 天 ({validity_days // 365} 年)")

        response = requests.post(api_url, headers=headers, json=payload, timeout=30)

        if response.status_code == 200:
            data = response.json()
            if data.get("success"):
                result = data.get("result", {})
                print("\n✅ 证书生成成功！")
                return {
                    "certificate": result.get("certificate"),
                    "private_key": result.get("private_key"),
                    "csr": result.get("csr")
                }
            else:
                errors = data.get("errors", [])
                print(f"\n❌ 证书生成失败: {errors}")
                return None
        else:
            print(f"\n❌ API 请求失败 (HTTP {response.status_code}): {response.text}")
            return None

    except Exception as e:
        print(f"\n❌ 发生错误: {str(e)}")
        return None


def save_certificates(cert_data, output_dir="certs"):
    """
    保存证书和私钥到文件

    Args:
        cert_data: 包含证书和私钥的字典
        output_dir: 输出目录
    """
    output_path = Path(output_dir)
    output_path.mkdir(exist_ok=True)

    # 保存证书
    cert_file = output_path / "cloudflare-origin.pem"
    with open(cert_file, "w", encoding="utf-8") as f:
        f.write(cert_data["certificate"])
    print(f"✅ 证书已保存: {cert_file.absolute()}")

    # 保存私钥
    key_file = output_path / "cloudflare-origin-key.pem"
    with open(key_file, "w", encoding="utf-8") as f:
        f.write(cert_data["private_key"])
    print(f"✅ 私钥已保存: {key_file.absolute()}")

    # 设置私钥权限
    os.chmod(key_file, 0o600)
    print(f"✅ 私钥权限已设置为 600 (仅所有者可读写)")

    # 保存 CSR（可选）
    csr_file = output_path / "cloudflare-origin.csr"
    if cert_data.get("csr"):
        with open(csr_file, "w", encoding="utf-8") as f:
            f.write(cert_data["csr"])
        print(f"✅ CSR 已保存: {csr_file.absolute()}")

    return {
        "cert": str(cert_file.absolute()),
        "key": str(key_file.absolute())
    }


def get_zone_list(api_token):
    """
    获取用户的 Zone 列表

    Args:
        api_token: Cloudflare API Token

    Returns:
        list: Zone 列表
    """
    headers = {
        "Authorization": f"Bearer {api_token}",
        "Content-Type": "application/json"
    }

    api_url = "https://api.cloudflare.com/client/v4/zones"

    try:
        response = requests.get(api_url, headers=headers, timeout=30)

        if response.status_code == 200:
            data = response.json()
            if data.get("success"):
                return data.get("result", [])
        return []

    except Exception as e:
        print(f"❌ 获取 Zone 列表失败: {str(e)}")
        return []


def main():
    parser = argparse.ArgumentParser(description="生成 Cloudflare Origin Certificate")
    parser.add_argument("--api-token", "-t", required=True, help="Cloudflare API Token")
    parser.add_argument("--zone-id", "-z", help="Cloudflare Zone ID")
    parser.add_argument("--domain", "-d", default="tnho-fasteners.com", help="域名 (默认: tnho-fasteners.com)")
    parser.add_argument("--output-dir", "-o", default="certs", help="输出目录 (默认: certs)")
    parser.add_argument("--validity-days", "-v", type=int, default=5475, help="有效期天数 (默认: 5475 = 15年)")

    args = parser.parse_args()

    # 检查 API Token
    print("=" * 60)
    print("Cloudflare Origin Certificate 生成工具")
    print("=" * 60)

    # 如果没有提供 Zone ID，自动查找
    zone_id = args.zone_id
    if not zone_id:
        print("\n正在获取 Zone 列表...")
        zones = get_zone_list(args.api_token)

        if not zones:
            print("❌ 未找到任何 Zone，请检查 API Token 权限")
            sys.exit(1)

        # 查找匹配的 Zone
        matching_zones = [z for z in zones if args.domain in z.get("name", "")]

        if not matching_zones:
            print(f"\n❌ 未找到域名 '{args.domain}' 对应的 Zone")
            print("\n可用的 Zone 列表:")
            for zone in zones:
                print(f"  - {zone['name']} (ID: {zone['id']})")
            sys.exit(1)

        if len(matching_zones) == 1:
            zone_id = matching_zones[0]["id"]
            print(f"✅ 自动找到 Zone: {matching_zones[0]['name']} (ID: {zone_id})")
        else:
            print(f"\n找到多个匹配的 Zone:")
            for i, zone in enumerate(matching_zones, 1):
                print(f"  {i}. {zone['name']} (ID: {zone['id']})")

            choice = input("\n请选择 Zone 编号 (1-{}): ".format(len(matching_zones)))
            try:
                zone_id = matching_zones[int(choice) - 1]["id"]
            except (ValueError, IndexError):
                print("❌ 无效的选择")
                sys.exit(1)

    # 准备域名列表（包含通配符）
    hostnames = [
        args.domain,
        f"*.{args.domain}",
        f"www.{args.domain}"
    ]

    # 生成证书
    cert_data = generate_origin_certificate(
        api_token=args.api_token,
        zone_id=zone_id,
        hostnames=hostnames,
        validity_days=args.validity_days
    )

    if cert_data:
        # 保存证书
        print("\n正在保存证书...")
        saved_files = save_certificates(cert_data, args.output_dir)

        print("\n" + "=" * 60)
        print("📋 下一步操作:")
        print("=" * 60)
        print("\n1. 将证书文件上传到服务器:")
        print(f"   scp {saved_files['cert']} root@47.110.72.148:/etc/nginx/ssl/")
        print(f"   scp {saved_files['key']} root@47.110.72.148:/etc/nginx/ssl/")
        print("\n2. 在服务器上更新 Nginx 配置:")
        print("   ssl_certificate /etc/nginx/ssl/cloudflare-origin.pem;")
        print("   ssl_certificate_key /etc/nginx/ssl/cloudflare-origin-key.pem;")
        print("\n3. 重启 Nginx:")
        print("   nginx -t && systemctl reload nginx")
        print("\n4. 配置 Cloudflare DNS:")
        print(f"   - A 记录: tnho-fasteners.com -> 47.110.72.148")
        print(f"   - CNAME 记录: www.tnho-fasteners.com -> tnho-fasteners.com")
        print("\n5. 在 Cloudflare SSL/TLS 设置中:")
        print("   - 加密模式: Full (strict)")
        print("=" * 60)
    else:
        print("\n❌ 证书生成失败，请检查错误信息")
        sys.exit(1)


if __name__ == "__main__":
    main()
