"""
文本生成工具 - 使用火山方舟 Responses 接口
支持 doubao-seed-1-8-251228 模型
"""
from langchain.tools import tool
import requests
import os


@tool
def generate_text_with_responses(
    prompt: str,
    system_prompt: str = ""
) -> str:
    """
    使用火山方舟 Responses 接口生成文本

    Args:
        prompt: 用户提示词
        system_prompt: 系统提示词（可选）

    Returns:
        生成的文本内容
    """
    MODEL_NAME = "doubao-seed-1-8-251228"
    BASE_URL = "https://ark.cn-beijing.volces.com/api/v3"

    # 获取 API Key
    api_key = (
        os.getenv("ARK_API_KEY") or
        os.getenv("COZE_WORKLOAD_IDENTITY_API_KEY") or
        "e1533511-efae-4131-aea9-b573a1be4ecf"
    )

    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }

    # 构建输入
    input_items = []

    # 添加系统提示词（如果有）
    if system_prompt:
        input_items.append({
            "role": "system",
            "content": system_prompt
        })

    # 添加用户消息
    input_items.append({
        "role": "user",
        "content": [
            {
                "type": "input_text",
                "text": prompt
            }
        ]
    })

    request = {
        "model": MODEL_NAME,
        "input": input_items,
        "temperature": 0.7,
        "max_tokens": 8000
    }

    try:
        response = requests.post(
            f"{BASE_URL}/responses",
            json=request,
            headers=headers,
            timeout=600
        )
        response.raise_for_status()

        result = response.json()

        # 解析响应
        output = result.get("output", [])
        if output and len(output) > 0:
            content = output[0].get("content", [])
            # 提取文本内容
            text_parts = []
            for item in content:
                if item.get("type") == "text":
                    text_parts.append(item.get("text", ""))
            return "".join(text_parts)
        else:
            return "生成失败：未返回有效响应"

    except requests.exceptions.HTTPError as e:
        return f"API请求失败: {e.response.status_code} - {e.response.text}"
    except Exception as e:
        return f"文本生成失败: {str(e)}"
