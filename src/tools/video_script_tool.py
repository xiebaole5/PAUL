from langchain.tools import tool, ToolRuntime
from coze_coding_dev_sdk import LLMClient
from coze_coding_utils.runtime_ctx.context import new_context
from langchain_core.messages import SystemMessage, HumanMessage
import json


@tool
def generate_video_script(product_name: str, theme: str, duration: int = 30, runtime: ToolRuntime = None) -> str:
    """
    Generate a promotional video script for fastener products.
    
    This tool creates a detailed video script including:
    - Scene breakdown with timing
    - Visual descriptions for each scene
    - Voiceover/narration text
    - Background music suggestions
    - Product highlights to showcase
    
    Args:
        product_name: The name of the fastener product (e.g., "高强度螺栓", "不锈钢螺丝")
        theme: The theme of the video (e.g., "工业应用", "技术创新", "品质保证")
        duration: Total video duration in seconds (default: 30)
    
    Returns:
        A JSON string containing the complete video script with scenes, narration, and visual descriptions
    """
    ctx = new_context(method="generate_video_script")
    
    client = LLMClient(ctx=ctx)
    
    system_prompt = """你是一位专业的工业产品宣传视频脚本策划专家，擅长为紧固件等工业产品制作吸引人的宣传视频脚本。

你的任务是生成一个结构化的视频脚本，必须包含以下内容：
1. 场景分镜：将视频分解为多个场景，每个场景有明确的时长
2. 画面描述：每个场景的视觉呈现细节
3. 旁白文案：配合画面的解说词
4. 产品卖点：突出紧固件的核心优势（强度、耐用性、精度等）
5. 背景音乐建议：适合工业产品宣传的音乐风格

输出格式要求：
- 必须输出标准的 JSON 格式
- scenes 数组包含所有场景信息
- 每个场景包含：scene_id（场景编号）、duration（秒数）、visual（画面描述）、narration（旁白）
- 总时长要接近用户要求的 duration 参数

示例输出格式：
{
  "video_title": "视频标题",
  "total_duration": 30,
  "theme": "主题",
  "background_music": "音乐风格建议",
  "scenes": [
    {
      "scene_id": 1,
      "duration": 5,
      "visual": "画面描述",
      "narration": "旁白文案"
    }
  ]
}"""

    user_prompt = f"""请为以下产品生成一个宣传视频脚本：

产品名称：{product_name}
视频主题：{theme}
视频时长：{duration}秒

要求：
1. 突出紧固件的质量、可靠性和技术优势
2. 画面要体现工业应用场景
3. 旁白要简洁有力，有感染力
4. 确保总时长接近 {duration} 秒

请严格按照 JSON 格式输出脚本。"""

    messages = [
        SystemMessage(content=system_prompt),
        HumanMessage(content=user_prompt)
    ]
    
    response = client.invoke(messages=messages, temperature=0.8)
    
    # 尝试解析 JSON，如果失败则返回原始文本
    try:
        # 提取 JSON 部分（如果响应中有其他文本）
        content = response.content
        
        # 处理可能的列表类型（虽然通常应该是字符串）
        if isinstance(content, list):
            content = str(content[0]) if content else ""
        elif not isinstance(content, str):
            content = str(content)
        
        content = content.strip()
        if content.startswith("```json"):
            content = content[7:]
        if content.startswith("```"):
            content = content[3:]
        if content.endswith("```"):
            content = content[:-3]
        content = content.strip()
        
        script_data = json.loads(content)
        return json.dumps(script_data, ensure_ascii=False, indent=2)
    except (json.JSONDecodeError, TypeError, AttributeError) as e:
        # 如果 JSON 解析失败，返回一个默认格式的脚本
        default_script = {
            "video_title": f"{product_name}宣传视频",
            "total_duration": duration,
            "theme": theme,
            "background_music": "激昂的工业风格背景音乐",
            "note": f"JSON 解析失败，使用默认格式。错误: {str(e)}",
            "raw_content": str(response.content) if hasattr(response, 'content') else str(response)
        }
        return json.dumps(default_script, ensure_ascii=False, indent=2)
