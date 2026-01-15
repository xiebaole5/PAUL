"""
微信小程序专用视频生成 Agent
完整流程：脚本生成 → 首尾帧图片生成 → 视频生成
"""
import os
import json
from typing import Annotated
from langchain.agents import create_agent
from langchain_openai import ChatOpenAI
from langgraph.graph import MessagesState
from langgraph.graph.message import add_messages
from langchain_core.messages import AnyMessage

# 导入小程序专用工具
from tools.miniprogram_video_tool import generate_ad_script, generate_frame_images, generate_miniprogram_video

LLM_CONFIG = "config/miniprogram_video_config.json"

# 默认保留最近 20 轮对话 (40 条消息)
MAX_MESSAGES = 40


def _windowed_messages(old, new):
    """滑动窗口: 只保留最近 MAX_MESSAGES 条消息"""
    return add_messages(old, new)[-MAX_MESSAGES:]  # type: ignore


class AgentState(MessagesState):
    messages: Annotated[list[AnyMessage], _windowed_messages]


def build_agent(ctx=None):
    """
    构建微信小程序专用视频生成 Agent

    完整流程：
    1. 用户输入必填信息 → 生成广告脚本
    2. 根据脚本 → 生成首尾帧图片（各2张）
    3. 用户选择首尾帧 → 生成20秒视频
    """
    workspace_path = os.getenv("COZE_WORKSPACE_PATH", "/app")
    config_path = os.path.join(workspace_path, LLM_CONFIG)

    # 读取配置文件
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

    # 创建 Agent
    agent = create_agent(
        model=llm,
        system_prompt=model_config.get("sp"),
        tools=[
            generate_ad_script,
            generate_frame_images,
            generate_miniprogram_video
        ],
        checkpointer=None,  # 小程序不需要记忆
        state_schema=AgentState,
    )

    return agent
