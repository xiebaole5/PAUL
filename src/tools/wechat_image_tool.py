"""
企业微信图片生成工具
使用 doubao-seedream 模型生成图片
"""
import os
import tempfile
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
    "品质保证": "天虹紧固件高品质产品展示，严格的质量控制，专业可靠",
    "技术创新": "天虹紧固件技术创新，研发实力，科技感，创新设计",
    "工业应用": "天虹紧固件在工业场景中的应用，实用可靠，性能优异",
    "品牌形象": "天虹紧固件企业形象，品牌文化，红色TNHO品牌"
}

# 支持的图片类型
IMAGE_TYPES = {
    "产品图片": "紧固件产品特写，清晰展示产品细节",
    "宣传海报": "宣传海报设计，包含品牌元素和产品信息",
    "场景展示": "产品使用场景展示，实际应用效果",
    "创意设计": "创意设计图，艺术化表现",
    "产品手册": "产品手册插图，技术说明"
}


@tool
def generate_image(
    theme: str,
    image_type: str = "产品图片",
    description: str = "",
    runtime: ToolRuntime = None
) -> str:
    """
    生成产品宣传图片

    Args:
        theme: 图片主题（品质保证/技术创新/工业应用/品牌形象）
        image_type: 图片类型（产品图片/宣传海报/场景展示/创意设计/产品手册）
        description: 图片描述（可选）
        runtime: ToolRuntime对象

    Returns:
        生成结果，包含图片URL
    """
    try:
        print(f"开始生成图片: 主题={theme}, 类型={image_type}")

        # 验证主题
        if theme not in THEMES:
            return f"错误：不支持的主题 '{theme}'，支持的主题：{', '.join(THEMES.keys())}"

        # 验证图片类型
        if image_type not in IMAGE_TYPES:
            return f"错误：不支持的图片类型 '{image_type}'，支持的类型：{', '.join(IMAGE_TYPES.keys())}"

        # 构建提示词
        theme_desc = THEMES[theme]
        type_desc = IMAGE_TYPES[image_type]

        prompt = f"""
天虹紧固件{type_desc}。

主题：{theme}
主题描述：{theme_desc}
详细描述：{description if description else '专业、大气、有科技感'}

要求：
- 高质量图片
- 融入红色TNHO品牌元素
- 展示紧固件产品的特性
- 专业摄影风格，清晰锐利
- 光线充足，构图美观
- 背景简洁，突出主体
- 适合商业用途

视觉风格：
- 专业工业摄影
- 红色作为主色调（TNHO品牌色）
- 现代、简洁、有科技感
- 高对比度，视觉冲击力强
"""

        # 构建请求
        headers = {
            "Authorization": f"Bearer {ARK_API_KEY}",
            "Content-Type": "application/json"
        }

        request_data = {
            "model": "doubao-seedream",
            "prompt": prompt,
            "size": "1024x1024",
            "n": 1,
            "quality": "standard",
            "style": "vivid"
        }

        response = requests.post(
            f"{BASE_URL}/images/generations",
            headers=headers,
            json=request_data,
            timeout=120
        )

        if response.status_code != 200:
            return f"图片生成失败：API返回错误 {response.status_code}"

        result = response.json()

        # 提取图片URL
        image_url = None
        if 'data' in result and len(result['data']) > 0:
            image_url = result['data'][0].get('url')

        if not image_url:
            return "图片生成失败：未获取到图片URL"

        # 上传到对象存储
        try:
            # 下载图片
            temp_file = tempfile.NamedTemporaryFile(suffix='.png', delete=False)
            image_response = requests.get(image_url, timeout=60)
            temp_file.write(image_response.content)
            temp_file.close()

            # 上传到对象存储
            oss_url = upload_to_s3(temp_file.name, "wechat/images/")
            os.unlink(temp_file.name)

            return f"""
✅ 图片生成成功！

🖼️ 图片信息：
- 主题：{theme}
- 类型：{image_type}
- 图片：{oss_url}

💡 提示：
- 可用于产品宣传、营销推广
- 可配合视频使用增强效果
- 建议搭配文案提升传播效果
"""

        except Exception as e:
            print(f"上传到对象存储失败: {str(e)}")
            # 如果上传失败，返回原始URL
            return f"""
✅ 图片生成成功！

🖼️ 图片信息：
- 主题：{theme}
- 类型：{image_type}
- 图片：{image_url}

⚠️ 注意：临时链接，建议尽快下载
"""

    except Exception as e:
        print(f"图片生成失败: {str(e)}")
        return f"图片生成失败：{str(e)}"
