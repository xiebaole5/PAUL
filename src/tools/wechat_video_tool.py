"""
企业微信视频生成工具
使用 doubao-seedance 模型生成视频
"""
import os
import tempfile
from pathlib import Path
from langchain.tools import tool, ToolRuntime
from coze_coding_dev_sdk.s3 import upload_to_s3
import requests
from dotenv import load_dotenv

load_dotenv()

# 获取环境变量
ARK_API_KEY = os.getenv("ARK_API_KEY", "")
BASE_URL = os.getenv("ARK_BASE_URL", "https://ark.cn-beijing.volces.com/api/v3")

# 支持的主题
THEMES = {
    "品质保证": "展示天虹紧固件的高品质标准和严格的质量控制流程，突出红色TNHO品牌",
    "技术创新": "展示天虹紧固件的技术创新和研发实力，突出科技感和创新力",
    "工业应用": "展示天虹紧固件在各种工业场景中的应用，突出实用性和可靠性",
    "品牌形象": "展示天虹紧固件的企业形象和品牌文化，提升品牌认知度"
}

# 视频分段策略
VIDEO_DURATION_MAP = {
    15: [8, 7],
    20: [10, 10],
    25: [8, 8, 9],
    30: [10, 10, 10]
}


@tool
def generate_video(
    theme: str,
    duration: int,
    scenario: str = "",
    product_image_url: str = "",
    runtime: ToolRuntime = None
) -> str:
    """
    生成产品宣传视频

    Args:
        theme: 视频主题（品质保证/技术创新/工业应用/品牌形象）
        duration: 视频总时长（15/20/25/30秒）
        scenario: 使用场景描述（可选）
        product_image_url: 产品图片URL，用于图生视频（可选）
        runtime: ToolRuntime对象

    Returns:
        生成结果，包含视频URL和其他信息
    """
    try:
        print(f"开始生成视频: 主题={theme}, 时长={duration}秒")

        # 验证主题
        if theme not in THEMES:
            return f"错误：不支持的主题 '{theme}'，支持的主题：{', '.join(THEMES.keys())}"

        # 验证时长
        if duration not in VIDEO_DURATION_MAP:
            return f"错误：不支持的时长 '{duration}'秒，支持的时长：{', '.join(map(str, VIDEO_DURATION_MAP.keys()))}秒"

        # 构建提示词
        theme_desc = THEMES[theme]
        base_prompt = f"""
{theme_desc}。

场景：{scenario if scenario else '产品展示'}

要求：
- 视频时长：{duration}秒
- 融入红色TNHO商标元素
- 展示紧固件产品的细节和特性
- 专业、大气、有科技感
- 产品特写和场景展示结合
"""

        # 如果有图片，使用图生视频
        if product_image_url:
            prompt = f"{base_prompt}\n参考图片中的产品进行视频生成。"

            # 构建请求（图生视频）
            request_data = {
                "model": "doubao-seedance-1-5-pro-251215",
                "input": {
                    "prompt": prompt,
                    "image_url": product_image_url,
                    "mode": "image_to_video"
                },
                "parameters": {
                    "width": 1080,
                    "height": 1920,
                    "duration": min(duration, 5)  # 单段最多5秒
                }
            }
        else:
            prompt = base_prompt

            # 构建请求（文生视频）
            request_data = {
                "model": "doubao-seedance-1-5-pro-251215",
                "input": {
                    "prompt": prompt,
                    "mode": "text_to_video"
                },
                "parameters": {
                    "width": 1080,
                    "height": 1920,
                    "duration": min(duration, 5)  # 单段最多5秒
                }
            }

        # 调用火山方舟API
        headers = {
            "Authorization": f"Bearer {ARK_API_KEY}",
            "Content-Type": "application/json"
        }

        response = requests.post(
            f"{BASE_URL}/chat/completions",
            headers=headers,
            json=request_data,
            timeout=300
        )

        if response.status_code != 200:
            return f"视频生成失败：API返回错误 {response.status_code}"

        result = response.json()

        # 提取视频URL
        video_url = None
        if 'choices' in result and len(result['choices']) > 0:
            video_url = result['choices'][0]['message'].get('content')

        if not video_url:
            return "视频生成失败：未获取到视频URL"

        # 上传到对象存储
        try:
            # 下载视频
            temp_file = tempfile.NamedTemporaryFile(suffix='.mp4', delete=False)
            video_response = requests.get(video_url, timeout=60)
            temp_file.write(video_response.content)
            temp_file.close()

            # 上传到对象存储
            oss_url = upload_to_s3(temp_file.name, "wechat/videos/")
            os.unlink(temp_file.name)

            return f"""
✅ 视频生成成功！

📹 视频信息：
- 主题：{theme}
- 时长：{duration}秒
- 视频：{oss_url}

💡 提示：
- 如果是短视频，可以继续生成更多段落并拼接
- 建议搭配文案和语音使用效果更佳
"""

        except Exception as e:
            print(f"上传到对象存储失败: {str(e)}")
            # 如果上传失败，返回原始URL
            return f"""
✅ 视频生成成功！

📹 视频信息：
- 主题：{theme}
- 时长：{duration}秒
- 视频：{video_url}

⚠️ 注意：临时链接，建议尽快下载
"""

    except Exception as e:
        print(f"视频生成失败: {str(e)}")
        return f"视频生成失败：{str(e)}"


@tool
def generate_script(
    theme: str,
    duration: int,
    scenario: str = "",
    runtime: ToolRuntime = None
) -> str:
    """
    生成视频脚本/文案

    Args:
        theme: 视频主题（品质保证/技术创新/工业应用/品牌形象）
        duration: 视频时长（15/20/25/30秒）
        scenario: 使用场景描述（可选）
        runtime: ToolRuntime对象

    Returns:
        生成的脚本内容
    """
    try:
        print(f"开始生成脚本: 主题={theme}, 时长={duration}秒")

        # 验证主题
        if theme not in THEMES:
            return f"错误：不支持的主题 '{theme}'，支持的主题：{', '.join(THEMES.keys())}"

        # 构建提示词
        theme_desc = THEMES[theme]

        prompt = f"""
请为天虹紧固件产品生成一个{duration}秒的宣传视频脚本。

主题：{theme}
主题描述：{theme_desc}
使用场景：{scenario if scenario else '通用'}

要求：
1. 脚本时长：约{duration}秒（正常语速约{int(duration * 2.5)}字）
2. 突出红色TNHO品牌元素
3. 展示紧固件的产品特性
4. 语言：简洁有力，有感染力
5. 格式：包含场景描述和旁白文案

输出格式：
【场景描述】...
【旁白/文案】...
【音效建议】...
"""

        # 调用火山方舟API（文本生成）
        headers = {
            "Authorization": f"Bearer {ARK_API_KEY}",
            "Content-Type": "application/json"
        }

        request_data = {
            "model": "doubao-seed-1-8-251228",
            "messages": [
                {
                    "role": "system",
                    "content": "你是专业的视频脚本撰写专家，擅长为工业产品创作宣传文案。"
                },
                {
                    "role": "user",
                    "content": prompt
                }
            ],
            "temperature": 0.7,
            "max_tokens": 1000
        }

        response = requests.post(
            f"{BASE_URL}/chat/completions",
            headers=headers,
            json=request_data,
            timeout=120
        )

        if response.status_code != 200:
            return f"脚本生成失败：API返回错误 {response.status_code}"

        result = response.json()

        # 提取脚本内容
        script_content = None
        if 'choices' in result and len(result['choices']) > 0:
            script_content = result['choices'][0]['message']['content']

        if not script_content:
            return "脚本生成失败：未获取到内容"

        return f"""
✅ 脚本生成成功！

📝 脚本内容：
{script_content}

💡 提示：
- 可以直接用于视频制作
- 可以配合语音合成功能生成配音
- 可以根据实际需求进行调整
"""

    except Exception as e:
        print(f"脚本生成失败: {str(e)}")
        return f"脚本生成失败：{str(e)}"
