#!/bin/bash

# 修复 agent.py 文件 - 移除 coze_coding_utils 依赖

echo "=========================================="
echo "修复 agent.py 文件"
echo "=========================================="

cd /opt/tnho-video-generator

# 停止容器
docker-compose down

# 备份当前文件
cp src/agents/agent.py src/agents/agent.py.backup2

# 写入修复后的内容
cat > src/agents/agent.py << 'EOF'
import os
import json
from typing import Annotated
from langchain.agents import create_agent
from langchain_openai import ChatOpenAI
from langgraph.graph import MessagesState
from langgraph.graph.message import add_messages
from langchain_core.messages import AnyMessage
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
    workspace_path = os.getenv("COZE_WORKSPACE_PATH", "/workspace/projects")
    config_path = os.path.join(workspace_path, LLM_CONFIG)

    with open(config_path, 'r', encoding='utf-8') as f:
        cfg = json.load(f)

    api_key = os.getenv("COZE_WORKLOAD_IDENTITY_API_KEY")
    base_url = os.getenv("COZE_INTEGRATION_MODEL_BASE_URL")

    llm = ChatOpenAI(
        model=cfg['config'].get("model"),
        api_key=api_key,
        base_url=base_url,
        temperature=cfg['config'].get('temperature', 0.7),
        streaming=True,
        timeout=cfg['config'].get('timeout', 600),
        extra_body={
            "thinking": {
                "type": cfg['config'].get('thinking', 'disabled')
            }
        }
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
EOF

echo "✓ agent.py 文件已修复"

# 重新启动服务
echo ""
echo "重新启动服务..."
docker-compose up -d

echo ""
echo "等待服务启动（15秒）..."
sleep 15

echo ""
echo "=========================================="
echo "容器状态："
echo "=========================================="
docker ps

echo ""
echo "=========================================="
echo "API 服务日志（最后30行）："
echo "=========================================="
docker logs tnho-video-api --tail 30

echo ""
echo "=========================================="
echo "测试健康检查："
echo "=========================================="
curl http://localhost:8000/health

echo ""
echo "=========================================="
echo "修复完成！"
echo "=========================================="
