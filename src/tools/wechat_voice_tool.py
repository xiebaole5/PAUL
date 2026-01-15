"""
企业微信语音合成工具
使用 doubao-voice 模型生成语音
"""
import os
import tempfile
from langchain.tools import tool, ToolRuntime
import requests
from dotenv import load_dotenv

load_dotenv()

# 导入对象存储上传工具
try:
    from tools.storage_upload_tool import upload_and_get_url
except ImportError:
    upload_and_get_url = None

# 获取环境变量
ARK_API_KEY = os.getenv("ARK_API_KEY", "")
BASE_URL = os.getenv("ARK_BASE_URL", "https://ark.cn-beijing.volces.com/api/v3")

# 支持的音色
VOICES = {
    "zh_female_tianjing": "天净（女声，温柔亲切）",
    "zh_male_yunjian": "云健（男声，稳重专业）",
    "zh_female_xiaoxuan": "小萱（女声，活泼可爱）",
    "zh_male_zhiqiang": "志强（男声，有力有磁性）",
    "zh_female_xiaomei": "小美（女声，甜美自然）"
}


@tool
def generate_voice(
    text: str,
    voice: str = "zh_female_tianjing",
    runtime: ToolRuntime = None
) -> str:
    """
    生成语音文件

    Args:
        text: 要合成的文本内容
        voice: 音色选择（默认天净女声）
        runtime: ToolRuntime对象

    Returns:
        生成结果，包含语音文件URL
    """
    try:
        print(f"开始生成语音: 文本长度={len(text)}字符, 音色={voice}")

        # 验证音色
        if voice not in VOICES:
            return f"错误：不支持的音色 '{voice}'，支持的音色：{', '.join(VOICES.keys())}"

        # 文本长度限制（单次最多2000字符）
        if len(text) > 2000:
            return f"错误：文本过长（{len(text)}字符），最多支持2000字符"

        # 构建请求
        headers = {
            "Authorization": f"Bearer {ARK_API_KEY}",
            "Content-Type": "application/json"
        }

        request_data = {
            "model": "doubao-voice",
            "input": {
                "text": text
            },
            "voice": voice,
            "response_format": "mp3",
            "speed": 1.0,
            "pitch": 0
        }

        response = requests.post(
            f"{BASE_URL}/audio/speech",
            headers=headers,
            json=request_data,
            timeout=120
        )

        if response.status_code != 200:
            return f"语音生成失败：API返回错误 {response.status_code}"

        # 获取音频内容
        audio_content = response.content

        # 保存到临时文件
        temp_file = tempfile.NamedTemporaryFile(suffix='.mp3', delete=False)
        temp_file.write(audio_content)
        temp_file.close()

        # 上传到对象存储
        if upload_and_get_url:
            import datetime
            import uuid
            timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
            unique_id = str(uuid.uuid4())[:8]
            file_name = f"wechat_voice_{timestamp}_{unique_id}.mp3"
            oss_url = upload_and_get_url(temp_file.name, file_name)
        else:
            oss_url = None  # 如果上传工具不可用，返回本地文件

        os.unlink(temp_file.name)

        # 估算时长
        duration_seconds = len(text) / 3  # 平均每秒3个字

        return f"""
✅ 语音生成成功！

🎤 语音信息：
- 文本长度：{len(text)}字符
- 预估时长：约{int(duration_seconds)}秒
- 音色：{VOICES[voice]}
- 语音文件：{oss_url}

💡 提示：
- 可用于视频配音
- 可用于语音播报
- 可配合文案使用增强传播效果
"""

    except Exception as e:
        print(f"语音生成失败: {str(e)}")
        return f"语音生成失败：{str(e)}"


@tool
def optimize_text(
    text: str,
    style: str = "营销",
    runtime: ToolRuntime = None
) -> str:
    """
    优化文本内容

    Args:
        text: 原始文本
        style: 优化风格（营销/专业/简洁/生动）
        runtime: ToolRuntime对象

    Returns:
        优化后的文本
    """
    try:
        print(f"开始优化文本: 风格={style}")

        styles = {
            "营销": "营销文案，突出产品优势，增强吸引力",
            "专业": "专业严谨，适合技术文档和产品说明",
            "简洁": "简洁明了，适合快速传播",
            "生动": "生动有趣，增强感染力"
        }

        if style not in styles:
            return f"错误：不支持的风格 '{style}'，支持的风格：{', '.join(styles.keys())}"

        # 构建提示词
        prompt = f"""
请优化以下文本内容，使其更适合{styles[style]}场景。

原始文本：
{text}

要求：
1. 保持原意不变
2. 突出天虹紧固件的TNHO品牌
3. 语言风格：{styles[style]}
4. 简洁有力，易于传播
5. 长度控制在原长度的80%-120%

请直接输出优化后的文本，不要包含其他说明。
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
                    "content": "你是专业的文案优化专家，擅长创作各种风格的营销文案。"
                },
                {
                    "role": "user",
                    "content": prompt
                }
            ],
            "temperature": 0.7,
            "max_tokens": 500
        }

        response = requests.post(
            f"{BASE_URL}/chat/completions",
            headers=headers,
            json=request_data,
            timeout=60
        )

        if response.status_code != 200:
            return f"文本优化失败：API返回错误 {response.status_code}"

        result = response.json()

        # 提取优化后的文本
        optimized_text = None
        if 'choices' in result and len(result['choices']) > 0:
            optimized_text = result['choices'][0]['message']['content']

        if not optimized_text:
            return "文本优化失败：未获取到内容"

        return f"""
✅ 文本优化成功！

📝 优化结果（{style}风格）：
{optimized_text}

💡 提示：
- 可以直接使用
- 可以继续调整风格
- 可以配合语音合成功能使用
"""

    except Exception as e:
        print(f"文本优化失败: {str(e)}")
        return f"文本优化失败：{str(e)}"
