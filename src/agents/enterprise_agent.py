"""
企业微信智能助手 Agent
整合视频、图片、文案、语音生成能力
"""
import os
import json
from typing import Annotated
from langchain.agents import create_agent
from langchain_openai import ChatOpenAI
from langgraph.graph import MessagesState
from langgraph.graph.message import add_messages
from langchain_core.messages import AnyMessage

# 导入工具
from tools.wechat_video_tool import generate_video, generate_script
from tools.wechat_image_tool import generate_image
from tools.wechat_voice_tool import generate_voice, optimize_text

LLM_CONFIG = "config/agent_llm_config.json"

# 默认保留最近 20 轮对话 (40 条消息)
MAX_MESSAGES = 40

def _windowed_messages(old, new):
    """滑动窗口: 只保留最近 MAX_MESSAGES 条消息"""
    return add_messages(old, new)[-MAX_MESSAGES:]  # type: ignore


class AgentState(MessagesState):
    messages: Annotated[list[AnyMessage], _windowed_messages]


def build_enterprise_agent(ctx=None):
    """
    构建企业微信智能助手 Agent

    整合能力：
    - 视频生成（doubao-seedance）
    - 图片生成（doubao-seedream）
    - 脚本生成（doubao-seed）
    - 语音合成（doubao-voice）
    """
    workspace_path = os.getenv("COZE_WORKSPACE_PATH", "/app")
    config_path = os.path.join(workspace_path, LLM_CONFIG)

    # 如果配置文件不存在，使用默认配置
    if not os.path.exists(config_path):
        model_config = {
            "config": {
                "model": "doubao-seed-1-8-251228",
                "temperature": 0.7,
                "top_p": 0.9,
                "max_completion_tokens": 4000,
                "timeout": 600,
                "thinking": "disabled"
            }
        }
    else:
        with open(config_path, 'r', encoding='utf-8') as f:
            model_config = json.load(f)

    api_key = os.getenv("ARK_API_KEY")
    base_url = os.getenv("ARK_BASE_URL", "https://ark.cn-beijing.volces.com/api/v3")

    llm = ChatOpenAI(
        model=model_config['config'].get("model", "doubao-seed-1-8-251228"),
        api_key=api_key,
        base_url=base_url,
        temperature=model_config['config'].get('temperature', 0.7),
        streaming=True,
        timeout=model_config['config'].get('timeout', 600),
        extra_body={
            "thinking": {
                "type": model_config['config'].get('thinking', 'disabled')
            }
        }
    )

    # 系统提示词
    system_prompt = """# 角色定义
你是天虹紧固件的全能营销助手，专门为企业微信用户提供AI生成服务。你能够整合视频、图片、文案、语音等多种能力，为用户提供一站式的营销内容生成解决方案。

# 任务目标
你的任务是理解用户需求，调用合适的工具生成营销内容，包括视频、图片、脚本、语音等，帮助用户快速完成营销素材制作。

# 能力
你具备以下核心能力：

1. **视频生成**
   - 支持主题：品质保证、技术创新、工业应用、品牌形象
   - 支持时长：15秒、20秒、25秒、30秒
   - 支持图生视频（用户上传产品图片）
   - 自动生成融入红色TNHO商标元素的视频
   - 工具：generate_video

2. **脚本生成**
   - 为视频生成专业脚本和文案
   - 包含场景描述、旁白、音效建议
   - 工具：generate_script

3. **图片生成**
   - 支持类型：产品图片、宣传海报、场景展示、创意设计、产品手册
   - 高质量工业摄影风格
   - 融入红色TNHO品牌元素
   - 工具：generate_image

4. **语音合成**
   - 支持多种音色：天净（女声）、云健（男声）、小萱（女声）、志强（男声）、小美（女声）
   - 适合视频配音和语音播报
   - 工具：generate_voice

5. **文本优化**
   - 优化文案风格：营销、专业、简洁、生动
   - 提升文案感染力
   - 工具：optimize_text

# 工作流程
1. **理解需求**：分析用户的请求，识别需要生成的内容类型（视频/图片/文案/语音）
2. **参数确认**：根据工具要求，确认必要的参数（主题、时长、风格等）
3. **调用工具**：调用相应的工具生成内容
4. **整理结果**：将生成结果整理成清晰的格式，包含下载链接和使用建议
5. **提供建议**：根据生成的内容，提供进一步的建议（如搭配其他素材使用）

# 输出格式
保持友好、专业的语气，输出格式如下：

✅ [内容类型]生成成功！

[详细信息]
- [参数1]：[值1]
- [参数2]：[值2]
- [内容]：[链接或内容]

💡 提示：
- [使用建议1]
- [使用建议2]

如果需要生成多种内容，按类别分段输出。

# 注意事项
1. 始终使用工具生成内容，不要凭空编造
2. 生成的内容必须符合天虹紧固件的品牌形象
3. 强调红色TNHO品牌元素
4. 提供清晰的使用说明
5. 鼓励用户提出更多需求

# 示例对话

用户：帮我生成一个20秒的技术创新视频
助手：✅ 视频生成成功！📹 视频信息：- 主题：技术创新- 时长：20秒- 视频：[链接]💡 提示：可以生成配套的文案和语音使用效果更佳

用户：帮我生成一张品质保证主题的宣传海报
助手：✅ 图片生成成功！🖼️ 图片信息：- 主题：品质保证- 类型：宣传海报- 图片：[链接]💡 提示：可用于产品宣传和营销推广

用户：为这段文字生成语音："天虹紧固件，品质保证"
助手：✅ 语音生成成功！🎤 语音信息：- 文本：天虹紧固件，品质保证- 音色：天净（女声）- 语音文件：[链接]
"""

    # 创建 Agent
    agent = create_agent(
        model=llm,
        system_prompt=system_prompt,
        tools=[
            generate_video,
            generate_script,
            generate_image,
            generate_voice,
            optimize_text
        ],
        state_schema=AgentState,
    )

    return agent
