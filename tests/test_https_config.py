#!/usr/bin/env python3
"""
HTTPS配置验证脚本
用于验证Nginx、SSL证书、API接口是否正常工作
"""
import requests
import socket
import ssl
import subprocess
import json
from urllib.parse import urlparse

# 测试配置
DOMAIN = "tnho-fasteners.com"
HTTP_URL = f"http://{DOMAIN}"
HTTPS_URL = f"https://{DOMAIN}"
API_URL = f"https://{DOMAIN}/health"

# 服务器直接访问（绕过Cloudflare）
SERVER_IP = "47.110.72.148"
SERVER_HTTPS_URL = f"https://{SERVER_IP}/health"

def print_section(title):
    """打印分节标题"""
    print(f"\n{'='*60}")
    print(f"  {title}")
    print('='*60)

def test_dns_resolution():
    """测试DNS解析"""
    print_section("1. 测试DNS解析")
    try:
        ip = socket.gethostbyname(DOMAIN)
        print(f"✅ DNS解析成功")
        print(f"   域名: {DOMAIN}")
        print(f"   IP地址: {ip}")
        return True
    except socket.gaierror as e:
        print(f"❌ DNS解析失败: {e}")
        return False

def test_http_redirect():
    """测试HTTP到HTTPS的重定向"""
    print_section("2. 测试HTTP到HTTPS重定向")
    try:
        response = requests.get(HTTP_URL, timeout=10, allow_redirects=False)
        status = response.status_code
        location = response.headers.get('Location', '')

        if status == 301 and 'https' in location:
            print(f"✅ HTTP重定向正常")
            print(f"   状态码: {status}")
            print(f"   重定向到: {location}")
            return True
        else:
            print(f"❌ HTTP重定向异常")
            print(f"   状态码: {status}")
            print(f"   Location: {location}")
            return False
    except Exception as e:
        print(f"❌ HTTP重定向测试失败: {e}")
        return False

def test_ssl_certificate():
    """测试SSL证书"""
    print_section("3. 测试SSL证书")
    try:
        # 创建SSL上下文
        context = ssl.create_default_context()

        # 建立HTTPS连接
        with socket.create_connection((DOMAIN, 443)) as sock:
            with context.wrap_socket(sock, server_hostname=DOMAIN) as ssock:
                cert = ssock.getpeercert()

                print(f"✅ SSL证书有效")
                print(f"   颁发给: {cert.get('subject', [[('')]])[0][0][1]}")
                print(f"   颁发者: {cert.get('issuer', [[('')]])[0][0][1]}")
                print(f"   有效期至: {cert.get('notAfter')}")

                # 检查域名是否匹配
                hostname = cert.get('subjectAltNames', [])
                domain_match = any(DOMAIN in item[1] for item in hostname if item[0] == 'DNS')
                if domain_match or cert.get('subject', [[('')]])[0][0][1] == DOMAIN:
                    print(f"   域名匹配: ✅")
                    return True
                else:
                    print(f"   域名匹配: ❌")
                    return False
    except Exception as e:
        print(f"❌ SSL证书验证失败: {e}")
        return False

def test_api_via_cloudflare():
    """通过Cloudflare测试API"""
    print_section("4. 测试API接口（通过Cloudflare）")
    try:
        response = requests.get(API_URL, timeout=10)

        print(f"✅ API请求成功")
        print(f"   状态码: {response.status_code}")
        print(f"   响应内容: {response.text}")

        if response.status_code == 200:
            data = response.json()
            if data.get('status') == 'ok':
                print(f"   API状态: ✅ 正常")
                return True
            else:
                print(f"   API状态: ❌ 异常")
                return False
        else:
            return False
    except requests.exceptions.SSLError as e:
        print(f"❌ SSL错误: {e}")
        print(f"   提示：可能是证书配置问题，尝试直接访问服务器")
        return False
    except Exception as e:
        print(f"❌ API请求失败: {e}")
        return False

def test_api_direct():
    """直接测试服务器API（绕过Cloudflare）"""
    print_section("5. 测试API接口（直接访问服务器）")
    try:
        # 忽略SSL证书验证（因为IP访问时证书不匹配）
        response = requests.get(SERVER_HTTPS_URL, timeout=10, verify=False)

        print(f"✅ API请求成功")
        print(f"   状态码: {response.status_code}")
        print(f"   响应内容: {response.text}")

        if response.status_code == 200:
            data = response.json()
            if data.get('status') == 'ok':
                print(f"   API状态: ✅ 正常")
                return True
            else:
                print(f"   API状态: ❌ 异常")
                return False
        else:
            return False
    except Exception as e:
        print(f"❌ API请求失败: {e}")
        return False

def test_nginx_status():
    """测试Nginx状态"""
    print_section("6. 测试Nginx状态")
    try:
        result = subprocess.run(
            ['systemctl', 'is-active', 'nginx'],
            capture_output=True,
            text=True
        )
        status = result.stdout.strip()

        if status == 'active':
            print(f"✅ Nginx运行正常")
            print(f"   状态: {status}")
            return True
        else:
            print(f"❌ Nginx状态异常")
            print(f"   状态: {status}")
            return False
    except Exception as e:
        print(f"❌ 检查Nginx状态失败: {e}")
        return False

def test_http_headers():
    """测试HTTP响应头"""
    print_section("7. 检查HTTP响应头")
    try:
        response = requests.get(HTTPS_URL, timeout=10)

        headers_to_check = {
            'Strict-Transport-Security': 'HSTS',
            'X-Content-Type-Options': 'X-Content-Type-Options',
            'X-Frame-Options': 'X-Frame-Options',
            'Server': 'Server'
        }

        print(f"✅ 响应头检查:")
        for header, desc in headers_to_check.items():
            value = response.headers.get(header, '未设置')
            print(f"   {desc} ({header}): {value}")

        return True
    except Exception as e:
        print(f"❌ 检查响应头失败: {e}")
        return False

def main():
    """主测试流程"""
    print("\n" + "="*60)
    print("  HTTPS配置验证脚本")
    print("  天虹紧固件小程序")
    print("="*60)
    print(f"\n测试域名: {DOMAIN}")
    print(f"服务器IP: {SERVER_IP}\n")

    results = {}

    # 运行所有测试
    results['DNS解析'] = test_dns_resolution()
    results['HTTP重定向'] = test_http_redirect()
    results['SSL证书'] = test_ssl_certificate()
    results['API(通过Cloudflare)'] = test_api_via_cloudflare()
    results['API(直接访问)'] = test_api_direct()
    results['Nginx状态'] = test_nginx_status()
    results['HTTP响应头'] = test_http_headers()

    # 汇总结果
    print_section("测试结果汇总")
    total = len(results)
    passed = sum(1 for v in results.values() if v)
    failed = total - passed

    for test_name, result in results.items():
        status = "✅ 通过" if result else "❌ 失败"
        print(f"  {test_name:25} {status}")

    print("\n" + "="*60)
    print(f"  总计: {total} 项测试")
    print(f"  通过: {passed} 项")
    print(f"  失败: {failed} 项")
    print("="*60)

    # 给出建议
    if failed == 0:
        print("\n✅ 所有测试通过！HTTPS配置正常。")
        print("\n下一步操作：")
        print("  1. 配置Cloudflare SSL/TLS模式为Full")
        print("  2. 在小程序后台配置服务器域名")
        print("  3. 更新小程序API地址为HTTPS")
        print("  4. 上传小程序代码并提交审核")
    else:
        print("\n⚠️  部分测试失败，请根据失败项进行排查。")
        print("\n常见问题排查：")
        print("  - DNS解析失败：检查域名解析是否正确")
        print("  - SSL证书失败：检查证书路径和Nginx配置")
        print("  - API访问失败：检查应用是否运行（端口8000）")
        print("  - Nginx状态异常：检查Nginx配置和日志")
        print("\n查看日志：")
        print("  sudo tail -f /var/log/nginx/tnho-fasteners-error.log")

    print("\n" + "="*60 + "\n")

if __name__ == "__main__":
    main()
