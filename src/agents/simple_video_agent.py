"""
简洁版视频生成 Agent
专为微信小程序设计，简化流程
"""
import os
import json
from typing import Annotated
from langchain.agents import create_agent
from langchain_openai import ChatOpenAI
from langgraph.graph import MessagesState
from langgraph.graph.message import add_messages
from langchain_core.messages import AnyMessage

# 导入简洁版工具
from tools.simple_video_tool import generate_video_with_script, generate_simple_script

LLM_CONFIG = "config/simple_video_config.json"

# 默认保留最近 20 轮对话 (40 条消息)
MAX_MESSAGES = 40


def _windowed_messages(old, new):
    """滑动窗口: 只保留最近 MAX_MESSAGES 条消息"""
    return add_messages(old, new)[-MAX_MESSAGES:]  # type: ignore


class AgentState(MessagesState):
    messages: Annotated[list[AnyMessage], _windowed_messages]


def build_agent(ctx=None):
    """
    构建简洁版视频生成 Agent

    核心功能：
    1. 根据用户提供的图片和主题文案生成脚本
    2. 根据脚本生成20秒紧固件宣传视频
    3. 支持首尾帧图片上传
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
            generate_video_with_script,
            generate_simple_script
        ],
        checkpointer=None,  # 简化版不使用记忆
        state_schema=AgentState,
    )

    return agent
