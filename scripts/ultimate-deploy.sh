#!/bin/bash

# 天虹紧固件视频API - 终极部署脚本（包含所有文件）
# 用法：在服务器上直接执行此脚本

set -e

# ========================================
# 配置参数
# ========================================
PROJECT_DIR="/root/tnho-video-api"
API_KEY="39bf20d0-55b5-4957-baa1-02f4529a3076"

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# ========================================
# 创建所有文件
# ========================================
echo -e "${CYAN}=====================================${NC}"
echo -e "${CYAN}天虹紧固件视频API - 终极部署${NC}"
echo -e "${CYAN}=====================================${NC}"
echo ""

# 进入项目目录
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

print_step "1. 创建目录结构..."
mkdir -p src/llm src/storage/memory src/tools config api
print_success "目录创建完成"

print_step "2. 创建配置文件..."

# 创建 docker-compose.yml
cat > docker-compose.yml << 'EOF'
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
EOF
print_info "创建 docker-compose.yml"

# 创建 Dockerfile
cat > Dockerfile << 'EOF'
FROM python:3.11-slim

WORKDIR /app

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 复制依赖文件
COPY requirements.txt .

# 安装 Python 依赖
RUN pip install --no-cache-dir -r requirements.txt

# 复制源代码
COPY src/ ./src/
COPY config/ ./config/

# 创建必要的目录
RUN mkdir -p /app/assets /app/logs

# 设置环境变量
ENV PYTHONPATH=/app:/app/src
ENV COZE_WORKSPACE_PATH=/app

# 暴露端口
EXPOSE 8000

# 启动命令
CMD ["uvicorn", "api.app:app", "--host", "0.0.0.0", "--port", "8000"]
EOF
print_info "创建 Dockerfile"

# 创建 requirements.txt
cat > requirements.txt << 'EOF'
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
volcenginesdkarkruntime==1.0.57
EOF
print_info "创建 requirements.txt"

# 创建 .env
cat > .env << EOF
ARK_API_KEY=${API_KEY}
ARK_BASE_URL=https://ark.cn-beijing.volces.com
EXTERNAL_BASE_URL=https://tnho-fasteners.com
COZE_WORKSPACE_PATH=/app
EOF
print_info "创建 .env"

# 创建 api/app.py
cat > api/app.py << 'EOF'
"""
FastAPI 主应用
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import os
import sys

# 设置路径
sys.path.insert(0, '/app')
sys.path.insert(0, '/app/src')

app = FastAPI(
    title="天虹紧固件视频生成API",
    description="基于AI的紧固件产品宣传视频生成系统",
    version="1.1.0"
)

# CORS 配置
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return {
        "message": "天虹紧固件视频生成API",
        "version": "1.1.0",
        "status": "running"
    }

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

# 导入路由
# from api.routes import generate_video
# app.include_router(generate_video.router, prefix="/api", tags=["video"])
EOF
print_info "创建 api/app.py"

# 创建 api/__init__.py
cat > api/__init__.py << 'EOF'
"""
API 模块
"""
EOF
print_info "创建 api/__init__.py"

print_step "3. 创建源代码文件..."

# 创建 src/llm/__init__.py
cat > src/llm/__init__.py << 'EOF'
from .volcano_responses_llm import VolcanoResponsesLLM
__all__ = ["VolcanoResponsesLLM"]
EOF
print_info "创建 src/llm/__init__.py"

# 创建 src/llm/volcano_responses_llm.py
cat > src/llm/volcano_responses_llm.py << 'EOF'
"""
火山方舟 Responses 接口自定义 LLM
"""
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

    def _generate(
        self,
        messages: Sequence[BaseMessage],
        stop: Optional[List[str]] = None,
        run_manager: Optional[CallbackManagerForLLMRun] = None,
        **kwargs: Any,
    ) -> ChatResult:
        input_items = self._convert_messages_to_input(messages)
        
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }
        
        payload = {
            "model": self.model,
            "messages": input_items,
            "temperature": self.temperature,
            "max_tokens": self.max_tokens,
            "stream": False
        }
        
        try:
            response = requests.post(
                f"{self.base_url}/chat/completions",
                headers=headers,
                json=payload,
                timeout=self.timeout
            )
            response.raise_for_status()
            
            data = response.json()
            content = data["choices"][0]["message"]["content"]
            
            generation = ChatGeneration(message=AIMessage(content=content))
            return ChatResult(generations=[generation], llm_output={"model": self.model})
            
        except Exception as e:
            raise Exception(f"Volcano API 调用失败: {str(e)}")

    def bind_tools(self, tools):
        return self
EOF
print_info "创建 src/llm/volcano_responses_llm.py"

# 创建 src/storage/memory/memory_saver.py
cat > src/storage/memory/memory_saver.py << 'EOF'
"""
记忆存储模块
"""
from langgraph.checkpoint.memory import MemorySaver

_checkpointer = None

def get_memory_saver():
    global _checkpointer
    if _checkpointer is None:
        _checkpointer = MemorySaver()
    return _checkpointer
EOF
print_info "创建 src/storage/memory/memory_saver.py"

# 创建 src/storage/__init__.py
cat > src/storage/__init__.py << 'EOF'
from .memory.memory_saver import get_memory_saver
__all__ = ["get_memory_saver"]
EOF
print_info "创建 src/storage/__init__.py"

# 创建 config/agent_llm_config.json
cat > config/agent_llm_config.json << 'EOF'
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
EOF
print_info "创建 config/agent_llm_config.json"

print_step "4. 创建资源目录..."
mkdir -p assets logs
print_success "资源目录创建完成"

print_success "所有文件创建完成！"
echo ""

# ========================================
# 清理旧容器
# ========================================
print_step "5. 清理旧容器..."
docker stop tnho-video-api || true
docker rm tnho-video-api || true
docker-compose down || true
docker image prune -f || true
print_success "旧容器清理完成"

# ========================================
# 构建和启动
# ========================================
print_step "6. 构建 Docker 镜像（这可能需要几分钟）..."
docker-compose build --no-cache
print_success "镜像构建完成"

print_step "7. 启动服务..."
docker-compose up -d
print_success "服务启动中..."

# 等待服务启动
print_info "等待服务启动（30秒）..."
sleep 30

# 检查容器状态
print_step "8. 检查服务状态..."
if docker ps | grep -q tnho-video-api; then
    print_success "✓ 容器运行正常"
else
    echo -e "${RED}✗ 容器启动失败${NC}"
    echo "查看日志："
    docker-compose logs --tail=50
    exit 1
fi

# 健康检查
sleep 5
if curl -f http://localhost:8000/health > /dev/null 2>&1; then
    print_success "✓ API 健康检查通过"
else
    echo -e "${YELLOW}⚠ API 健康检查失败，查看日志...${NC}"
    docker-compose logs --tail=30
fi

# 显示最近的日志
echo ""
echo "====================================="
echo "最近的容器日志："
echo "====================================="
docker-compose logs --tail=20
echo ""

# 显示部署信息
echo ""
echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}     部署完成！${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""
print_info "API 地址："
echo "  - HTTP:  http://47.110.72.148:8000"
echo "  - HTTPS: https://tnho-fasteners.com"
echo ""
print_info "常用命令："
echo "  查看日志：docker-compose logs -f api"
echo "  重启服务：docker-compose restart"
echo "  停止服务：docker-compose down"
echo "  进入容器：docker exec -it tnho-video-api /bin/bash"
echo ""
print_info "健康检查："
echo "  curl http://localhost:8000/health"
echo ""
echo -e "${GREEN}=====================================${NC}"
EOF

chmod +x /root/ultimate-deploy.sh
/root/ultimate-deploy.sh
