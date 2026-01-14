import os
import json
from typing import Annotated
from langchain.agents import create_agent
from langchain_openai import ChatOpenAI
from langgraph.graph import MessagesState
from langgraph.graph.message import add_messages
from langchain_core.messages import AnyMessage
# 使用绝对导入确保模块能正确找到
import sys
sys.path.insert(0, '/app/src')
from storage.memory.memory_saver import get_memory_saver

# 导入工具
from tools.video_generation_tool import generate_fastener_promo_video, check_task_status
from tools.video_script_generator import generate_fastener_promo_script

LLM_CONFIG = "config/agent_llm_config.json"

# 默认保留最近 20 轮对话 (40 条消息)
MAX_MESSAGES = 40


def _windowed_messages(old, new):
    """滑动窗口: 只保留最近 MAX_MESSAGES 条消息"""
    return add_messages(old, new)[-MAX_MESSAGES:]  # type: ignore


class AgentState(MessagesState):
    messages: Annotated[list[AnyMessage], _windowed_messages]


def build_agent(ctx=None):
    # 优先使用环境变量，否则使用当前脚本所在目录的父目录
    workspace_path = os.getenv("COZE_WORKSPACE_PATH", os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    config_path = os.path.join(workspace_path, LLM_CONFIG)

    with open(config_path, 'r', encoding='utf-8') as f:
        cfg = json.load(f)

    # 使用标准的 ChatOpenAI，支持工具调用
    api_key = os.getenv("ARK_API_KEY") or "39bf20d0-55b5-4957-baa1-02f4529a3076"
    base_url = os.getenv("ARK_BASE_URL") or "https://ark.cn-beijing.volces.com/api/v3"
    
    llm = ChatOpenAI(
        model=cfg['config'].get("model"),
        api_key=api_key,
        base_url=base_url,
        temperature=cfg['config'].get('temperature', 0.7),
        max_tokens=cfg['config'].get('max_completion_tokens', 8000),
        timeout=cfg['config'].get('timeout', 600),
        streaming=True
    )

    # 注册所有工具
    tools = [
        generate_fastener_promo_video,
        generate_fastener_promo_script,
        check_task_status
    ]

    return create_agent(
        model=llm,
        system_prompt=cfg.get("sp"),
        tools=tools,
        checkpointer=get_memory_saver(),
        state_schema=AgentState,
    )
