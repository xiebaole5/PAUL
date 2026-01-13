#!/bin/bash
set -e

PROJECT_DIR="/root/tnho-video-api"
API_KEY="39bf20d0-55b5-4957-baa1-02f4529a3076"

echo "====================================="
echo "天虹紧固件视频API - 修复版部署"
echo "====================================="
echo ""

mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

echo "[STEP] 1. 创建目录结构..."
mkdir -p src/llm src/storage/memory src/tools config api

echo "[STEP] 2. 创建配置文件..."

# docker-compose.yml
cat > docker-compose.yml << 'DOCOMPOSE'
version: '3.8'

services:
  api:
    build: .
    container_name: tnho-video-api
    ports:
      - "8000:8000"
    environment:
      - COZE_WORKSPACE_PATH=/app
      - COZE_INTEGRATION_MODEL_BASE_URL=https://ark.cn-beijing.volces.com
      - COZE_WORKLOAD_IDENTITY_API_KEY=${ARK_API_KEY}
      - EXTERNAL_BASE_URL=https://tnho-fasteners.com
      - ARK_API_KEY=${ARK_API_KEY}
      - ARK_BASE_URL=https://ark.cn-beijing.volces.com
    volumes:
      - ./src:/app/src
      - ./config:/app/config
      - ./assets:/app/assets
      - ./logs:/app/logs
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
DOCOMPOSE

# Dockerfile
cat > Dockerfile << 'DOCKFILE'
FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY src/ ./src/
COPY config/ ./config/

RUN mkdir -p /app/assets /app/logs

ENV PYTHONPATH=/app:/app/src
ENV COZE_WORKSPACE_PATH=/app

EXPOSE 8000

CMD ["uvicorn", "api.app:app", "--host", "0.0.0.0", "--port", "8000"]
DOCKFILE

# requirements.txt (修复版本，移除不存在的包)
cat > requirements.txt << 'REQFILE'
fastapi==0.104.1
uvicorn[standard]==0.24.0
langchain==0.1.20
langchain-core==0.1.52
langchain-openai==0.1.7
langgraph==0.0.28
pydantic==2.5.3
requests==2.31.0
python-multipart==0.0.6
python-dotenv==1.0.0
REQFILE

# .env
cat > .env << ENVEOF
ARK_API_KEY=${API_KEY}
ARK_BASE_URL=https://ark.cn-beijing.volces.com
EXTERNAL_BASE_URL=https://tnho-fasteners.com
COZE_WORKSPACE_PATH=/app
ENVEOF

# api/app.py
cat > api/app.py << 'PYAPP'
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import os
import sys

sys.path.insert(0, '/app')
sys.path.insert(0, '/app/src')

app = FastAPI(title="天虹紧固件视频生成API", version="1.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return {"message": "天虹紧固件视频生成API", "version": "1.1.0", "status": "running"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}
PYAPP

touch api/__init__.py

echo "[STEP] 3. 创建源代码文件..."

cat > src/llm/__init__.py << 'PYINIT'
from .volcano_responses_llm import VolcanoResponsesLLM
__all__ = ["VolcanoResponsesLLM"]
PYINIT

cat > src/llm/volcano_responses_llm.py << 'PYLLM'
from typing import Any, Dict, List, Optional, Sequence
from langchain_core.language_models.chat_models import BaseChatModel
from langchain_core.messages import BaseMessage, HumanMessage, SystemMessage, AIMessage
from langchain_core.outputs import ChatGeneration, ChatResult
from langchain_core.callbacks.manager import CallbackManagerForLLMRun
from pydantic import Field
import requests

class VolcanoResponsesLLM(BaseChatModel):
    model: str = Field(...)
    api_key: str = Field(...)
    base_url: str = Field(default="https://ark.cn-beijing.volces.com/api/v3")
    temperature: float = Field(default=0.7)
    max_tokens: int = Field(default=8000)
    timeout: int = Field(default=600)

    @property
    def _llm_type(self) -> str:
        return "volcano-responses"

    def _convert_messages_to_input(self, messages: Sequence[BaseMessage]) -> List[Dict[str, Any]]:
        input_items = []
        for message in messages:
            if message.__class__.__name__ == "ToolMessage":
                continue
            elif isinstance(message, SystemMessage):
                input_items.append({"role": "system", "content": message.content})
            elif isinstance(message, HumanMessage):
                input_items.append({"role": "user", "content": message.content})
            elif isinstance(message, AIMessage):
                input_items.append({"role": "assistant", "content": message.content})
        return input_items

    def _generate(self, messages: Sequence[BaseMessage], stop: Optional[List[str]] = None, run_manager: Optional[CallbackManagerForLLMRun] = None, **kwargs: Any) -> ChatResult:
        input_items = self._convert_messages_to_input(messages)
        headers = {"Authorization": f"Bearer {self.api_key}", "Content-Type": "application/json"}
        payload = {"model": self.model, "messages": input_items, "temperature": self.temperature, "max_tokens": self.max_tokens, "stream": False}
        
        try:
            response = requests.post(f"{self.base_url}/chat/completions", headers=headers, json=payload, timeout=self.timeout)
            response.raise_for_status()
            data = response.json()
            content = data["choices"][0]["message"]["content"]
            generation = ChatGeneration(message=AIMessage(content=content))
            return ChatResult(generations=[generation], llm_output={"model": self.model})
        except Exception as e:
            raise Exception(f"Volcano API 调用失败: {str(e)}")

    def bind_tools(self, tools):
        return self
PYLLM

cat > src/storage/memory/memory_saver.py << 'PYMEM'
from langgraph.checkpoint.memory import MemorySaver
_checkpointer = None
def get_memory_saver():
    global _checkpointer
    if _checkpointer is None:
        _checkpointer = MemorySaver()
    return _checkpointer
PYMEM

cat > src/storage/__init__.py << 'PYSTORAGE'
from .memory.memory_saver import get_memory_saver
__all__ = ["get_memory_saver"]
PYSTORAGE

cat > config/agent_llm_config.json << 'PYCONFIG'
{
  "config": {
    "model": "doubao-seed-1-8-251228",
    "temperature": 0.7,
    "top_p": 0.9,
    "max_completion_tokens": 10000,
    "timeout": 600,
    "thinking": "disabled"
  },
  "sp": "你是天虹紧固件的产品宣传视频生成专家。",
  "tools": []
}
PYCONFIG

echo "[STEP] 4. 创建资源目录..."
mkdir -p assets logs

echo "[STEP] 5. 清理旧容器..."
docker stop tnho-video-api || true
docker rm tnho-video-api || true
docker-compose down || true

echo "[STEP] 6. 构建 Docker 镜像..."
docker-compose build --no-cache

echo "[STEP] 7. 启动服务..."
docker-compose up -d

echo "等待服务启动（30秒）..."
sleep 30

echo "[STEP] 8. 检查服务状态..."
if docker ps | grep -q tnho-video-api; then
    echo "[SUCCESS] ✓ 容器运行正常"
else
    echo "[ERROR] ✗ 容器启动失败"
    docker-compose logs --tail=50
    exit 1
fi

sleep 5
if curl -f http://localhost:8000/health > /dev/null 2>&1; then
    echo "[SUCCESS] ✓ API 健康检查通过"
else
    echo "API 健康检查失败，查看日志..."
    docker-compose logs --tail=30
fi

echo ""
echo "====================================="
echo "最近的容器日志："
echo "====================================="
docker-compose logs --tail=20
echo ""

echo "====================================="
echo "部署完成！"
echo "====================================="
echo "API 地址："
echo "  - HTTP:  http://47.110.72.148:8000"
echo "  - HTTPS: https://tnho-fasteners.com"
echo ""
echo "查看日志：docker-compose logs -f api"
echo "====================================="
EOF

chmod +x /root/fixed-deploy.sh
/root/fixed-deploy.sh
