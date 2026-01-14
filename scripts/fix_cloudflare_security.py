#!/usr/bin/env python3
"""
Cloudflare 安全规则修复脚本
解决小程序 API 请求被 Bot Fight Mode 阻止（403错误）的问题
"""

import requests
import json
import sys

# Cloudflare API 配置
# 请在运行前设置环境变量或直接修改这些值
CLOUDFLARE_API_TOKEN = ""  # 你的 Cloudflare API Token
CLOUDFLARE_ZONE_ID = ""    # 你的域名 Zone ID
CLOUDFLARE_ACCOUNT_ID = "" # 你的 Account ID

BASE_URL = "https://api.cloudflare.com/client/v4"

headers = {
    "Authorization": f"Bearer {CLOUDFLARE_API_TOKEN}",
    "Content-Type": "application/json"
}


def disable_bot_fight_mode():
    """关闭 Bot Fight Mode"""
    print("\n=== 方案一：关闭 Bot Fight Mode ===")

    url = f"{BASE_URL}/zones/{CLOUDFLARE_ZONE_ID}/settings/bot_fight_mode"
    data = {"value": "off"}

    response = requests.patch(url, headers=headers, json=data)

    if response.status_code == 200:
        result = response.json()
        if result.get("success"):
            print("✅ Bot Fight Mode 已成功关闭")
            return True
        else:
            print(f"❌ 关闭失败: {result.get('errors')}")
            return False
    else:
        print(f"❌ API 请求失败: {response.status_code}")
        print(f"响应内容: {response.text}")
        return False


def allow_all_ip_rules():
    """创建 IP Access Rules 允许所有流量"""
    print("\n=== 方案二：创建 IP Access Rules ===")

    url = f"{BASE_URL}/zones/{CLOUDFLARE_ZONE_ID}/firewall/access_rules/rules"

    # 创建规则：允许所有 IP（优先级最高）
    data = {
        "mode": "whitelist",
        "configuration": {
            "target": "ip",
            "value": "0.0.0.0/0"
        },
        "notes": "允许所有流量访问（用于小程序API）"
    }

    response = requests.post(url, headers=headers, json=data)

    if response.status_code == 200:
        result = response.json()
        if result.get("success"):
            print("✅ IP Access Rule 创建成功：允许所有流量")
            print(f"   规则ID: {result['result']['id']}")
            return True
        else:
            print(f"❌ 创建失败: {result.get('errors')}")
            return False
    else:
        print(f"❌ API 请求失败: {response.status_code}")
        print(f"响应内容: {response.text}")
        return False


def create_zone_lockdown_rule():
    """创建 Zone Lockdown 规则允许 API 访问"""
    print("\n=== 方案三：创建 Zone Lockdown 规则 ===")

    url = f"{BASE_URL}/zones/{CLOUDFLARE_ZONE_ID}/firewall/lockdowns"

    # 创建规则：允许所有 IP 访问 /api/* 路径
    data = {
        "description": "允许小程序API访问",
        "urls": [
            "https://tnho-fasteners.com/api/*"
        ],
        "configurations": [
            {
                "target": "ip",
                "value": "0.0.0.0/0"
            }
        ]
    }

    response = requests.post(url, headers=headers, json=data)

    if response.status_code == 200:
        result = response.json()
        if result.get("success"):
            print("✅ Zone Lockdown 规则创建成功")
            print(f"   规则ID: {result['result']['id']}")
            return True
        else:
            print(f"❌ 创建失败: {result.get('errors')}")
            return False
    else:
        print(f"❌ API 请求失败: {response.status_code}")
        print(f"响应内容: {response.text}")
        return False


def get_current_security_settings():
    """查看当前安全设置"""
    print("\n=== 当前安全设置 ===")

    # 查看 Bot Fight Mode
    url = f"{BASE_URL}/zones/{CLOUDFLARE_ZONE_ID}/settings/bot_fight_mode"
    response = requests.get(url, headers=headers)

    if response.status_code == 200:
        result = response.json()
        if result.get("success"):
            bot_mode = result["result"]["value"]
            print(f"Bot Fight Mode: {'开启' if bot_mode == 'on' else '关闭'}")

    # 查看 WAF 级别
    url = f"{BASE_URL}/zones/{CLOUDFLARE_ZONE_ID}/settings/security_level"
    response = requests.get(url, headers=headers)

    if response.status_code == 200:
        result = response.json()
        if result.get("success"):
            security_level = result["result"]["value"]
            print(f"安全级别: {security_level}")


def print_manual_guide():
    """打印手动配置指南"""
    print("\n" + "="*70)
    print("如果脚本无法运行，请按照以下步骤手动配置 Cloudflare：")
    print("="*70)

    print("\n【推荐】方案一：关闭 Bot Fight Mode（最快）")
    print("-"*70)
    print("1. 登录 Cloudflare 控制台：https://dash.cloudflare.com/")
    print("2. 选择你的域名：tnho-fasteners.com")
    print("3. 左侧菜单点击：Security（安全）")
    print("4. 点击 Settings（设置）")
    print("5. 找到 Bot fight mode 部分")
    print("6. 将 JS Detections 设置为：Off（关闭）")
    print("7. 保存设置")

    print("\n【备选】方案二：创建 IP Access Rules")
    print("-"*70)
    print("1. 在 Cloudflare 控制台，点击：Security -> WAF -> IP Access Rules")
    print("2. 点击：Create IP access custom rule")
    print("3. 配置规则：")
    print("   - Field: IP Address")
    print("   - Operator: is in")
    print("   - Value: 0.0.0.0/0")
    print("   - Action: Allow（白名单）")
    print("4. 点击：Save and Deploy")

    print("\n【备选】方案三：创建 Zone Lockdown 规则")
    print("-"*70)
    print("1. 在 Cloudflare 控制台，点击：Security -> WAF -> Zone Lockdown")
    print("2. 点击：Create Zone Lockdown custom rule")
    print("3. 配置规则：")
    print("   - URL pattern: https://tnho-fasteners.com/api/*")
    print("   - Add IP address: 0.0.0.0/0")
    print("   - Action: Allow")
    print("4. 点击：Save and Deploy")

    print("\n【重要】配置后验证")
    print("-"*70)
    print("1. 在微信开发者工具中，清除缓存并重新编译小程序")
    print("2. 点击图片上传按钮，测试是否成功")
    print("3. 查看控制台，确认不再出现 403 错误")


def main():
    print("="*70)
    print("Cloudflare 安全规则修复工具")
    print("解决小程序 API 请求 403 错误")
    print("="*70)

    # 检查配置
    if not CLOUDFLARE_API_TOKEN:
        print("\n❌ 错误：请先设置 Cloudflare API Token")
        print("   在脚本中修改 CLOUDFLARE_API_TOKEN 变量")
        print("\n或者使用环境变量：")
        print("   export CLOUDFLARE_API_TOKEN='your_token_here'")
        print("   export CLOUDFLARE_ZONE_ID='your_zone_id_here'")
        print("   export CLOUDFLARE_ACCOUNT_ID='your_account_id_here'")
        print_manual_guide()
        return False

    # 显示当前设置
    get_current_security_settings()

    print("\n请选择修复方案：")
    print("1. 关闭 Bot Fight Mode（推荐）")
    print("2. 创建 IP Access Rules（允许所有流量）")
    print("3. 创建 Zone Lockdown 规则（仅允许API路径）")
    print("4. 执行所有方案")
    print("5. 显示手动配置指南")

    choice = input("\n请输入选项（1-5）：").strip()

    if choice == "1":
        return disable_bot_fight_mode()
    elif choice == "2":
        return allow_all_ip_rules()
    elif choice == "3":
        return create_zone_lockdown_rule()
    elif choice == "4":
        result1 = disable_bot_fight_mode()
        result2 = allow_all_ip_rules()
        result3 = create_zone_lockdown_rule()
        return result1 or result2 or result3
    elif choice == "5":
        print_manual_guide()
        return True
    else:
        print("❌ 无效的选项")
        print_manual_guide()
        return False


if __name__ == "__main__":
    success = main()
    print("\n" + "="*70)
    if success:
        print("✅ 配置完成！请在微信开发者工具中重新测试小程序")
    else:
        print("❌ 配置失败，请参考手动配置指南")
    print("="*70)
