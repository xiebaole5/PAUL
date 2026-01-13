#!/usr/bin/env python3
"""
测试火山方舟 API 连接
支持两种方式：langchain-openai 和官方 SDK
"""
import os
import sys

# 添加 src 到路径
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

# 从环境变量读取配置
API_KEY = os.getenv("ARK_API_KEY", "e1533511-efae-4131-aea9-b573a1be4ecf")
BASE_URL = os.getenv("ARK_BASE_URL", "https://ark.cn-beijing.volces.com/api/v3")

print("=" * 50)
print("测试火山方舟 API 连接")
print("=" * 50)
print(f"API Key: {API_KEY[:10]}...")
print(f"Base URL: {BASE_URL}")
print()

# 方式 1: 使用 langchain-openai
print("方式 1: 使用 langchain-openai")
print("-" * 50)
try:
    from langchain_openai import ChatOpenAI

    llm = ChatOpenAI(
        model="doubao-1.8",
        api_key=API_KEY,
        base_url=BASE_URL,
        temperature=0.7,
        timeout=60,
    )

    response = llm.invoke("你好，请用一句话介绍天虹紧固件。")
    print(f"✓ LangChain 方式成功")
    print(f"响应: {response.content}")
    print()
except Exception as e:
    print(f"✗ LangChain 方式失败: {e}")
    print()

# 方式 2: 使用官方 SDK
print("方式 2: 使用官方 SDK (volcenginesdkarkruntime)")
print("-" * 50)
try:
    from volcenginesdkarkruntime import Ark

    client = Ark(
        base_url=BASE_URL,
        api_key=API_KEY,
    )

    response = client.chat.completions.create(
        model="doubao-1.8",
        messages=[
            {
                "role": "user",
                "content": "你好，请用一句话介绍天虹紧固件。",
            }
        ],
    )

    print(f"✓ 官方 SDK 方式成功")
    print(f"响应: {response.choices[0].message.content}")
    print()
except ImportError as e:
    print(f"✗ 官方 SDK 未安装: {e}")
    print("请运行: pip install volcenginesdkarkruntime")
    print()
except Exception as e:
    print(f"✗ 官方 SDK 方式失败: {e}")
    print()

print("=" * 50)
print("测试完成")
print("=" * 50)
