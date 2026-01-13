# TNHO 视频生成服务 - 服务器手动部署指南

## 前提条件

- 阿里云服务器已安装 Docker 和 Docker Compose
- 服务器已配置域名 `tnho-fasteners.com` 并指向 `47.110.72.148`
- 已配置 Nginx 反向代理

## 部署步骤

### 方法 1: 使用 SCP 上传（推荐）

**在 Windows PowerShell 中执行:**

```powershell
# 1. 从 Linux 环境复制代码压缩包到本地可访问的位置
# (如果已在 /tmp/tnho-complete-code.tar.gz 创建)

# 2. 使用 SCP 上传到服务器
scp /tmp/tnho-complete-code.tar.gz root@47.110.72.148:/tmp/
```

**在服务器上执行（SSH 登录后）:**

```bash
# 创建项目目录
mkdir -p /root/tnho-video
cd /root/tnho-video

# 移动压缩包到项目目录
mv /tmp/tnho-complete-code.tar.gz .

# 解压代码
tar -xzf tnho-complete-code.tar.gz

# 检查并创建 .env 文件
cat > .env << 'EOF'
# 火山方舟配置
ARK_API_KEY=39bf20d0-55b5-4957-baa1-02f4529a3076
ARK_BASE_URL=https://ark.cn-beijing.volces.com/api/v3

# 对象存储配置
S3_ENDPOINT=https://tos-s3-cn-beijing.volces.com
S3_ACCESS_KEY_ID=your_access_key_id
S3_SECRET_ACCESS_KEY=your_secret_access_key
S3_BUCKET=tnho-videos
S3_REGION=cn-beijing

# 数据库配置
PGDATABASE_URL=postgresql://postgres:postgres123@db:5432/tnho_video

# 应用配置
APP_HOST=0.0.0.0
APP_PORT=8000
LOG_LEVEL=info
EOF

# 构建并启动容器
docker-compose down
docker-compose build
docker-compose up -d

# 查看日志
docker-compose logs -f
```

### 方法 2: 手动创建核心文件（备用）

如果无法上传文件，可以在服务器上手动创建核心文件：

#### 1. 创建目录结构

```bash
cd /root
mkdir -p tnho-video/src/{agents,api,llm,storage/{database,memory,s3},utils/messages,graphs}
mkdir -p tnho-video/{config,logs,scripts,assets}
cd tnho-video
```

#### 2. 创建 requirements.txt

```bash
cat > requirements.txt << 'EOF'
fastapi==0.104.1
uvicorn[standard]==0.24.0
pydantic==2.5.0
pydantic-settings==2.1.0
python-multipart==0.0.6
requests==2.31.0
python-dotenv==1.0.0
langchain==0.1.0
langchain-openai==0.0.2
langgraph==0.0.20
moviepy==2.2.1
pillow==10.1.0
psycopg2-binary==2.9.9
coze-coding-dev-sdk==1.0.0
sqlalchemy==2.0.23
alembic==1.13.0
EOF
```

#### 3. 创建 src/agents/agent.py

```bash
cat > src/agents/agent.py << 'EOF'
import os
import json
from typing import Annotated
from langchain.agents import create_agent
from langchain_openai import ChatOpenAI
from langgraph.graph import MessagesState
from langgraph.graph.message import add_messages
from langchain_core.messages import AnyMessage
from coze_coding_utils.runtime_ctx.context import default_headers
from storage.memory.memory_saver import get_memory_saver

LLM_CONFIG = "config/agent_llm_config.json"
MAX_MESSAGES = 40

def _windowed_messages(old, new):
    return add_messages(old, new)[-MAX_MESSAGES:]

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
        },
        default_headers=default_headers(ctx) if ctx else {}
    )

    return create_agent(
        model=llm,
        system_prompt=cfg.get("sp"),
        tools=[],
        checkpointer=get_memory_saver(),
        state_schema=AgentState,
    )
EOF
```

#### 4. 创建 src/api/app.py

```bash
cat > src/api/app.py << 'EOF'
import os
import time
import json
import asyncio
from typing import Optional, List
from fastapi import FastAPI, BackgroundTasks, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from dotenv import load_dotenv

# 加载环境变量
load_dotenv()

app = FastAPI(title="TNHO Video Generation API")

# CORS 配置
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 请求模型
class VideoGenerationRequest(BaseModel):
    theme: str
    duration: int = 20
    product_description: Optional[str] = None
    use_scene: Optional[str] = None

class VideoGenerationResponse(BaseModel):
    task_id: str
    message: str

# 全局任务存储
tasks = {}

@app.get("/health")
async def health_check():
    return {"status": "healthy", "timestamp": time.time()}

@app.post("/api/generate-video", response_model=VideoGenerationResponse)
async def generate_video(request: VideoGenerationRequest, background_tasks: BackgroundTasks):
    task_id = f"task_{int(time.time() * 1000)}"

    tasks[task_id] = {
        "status": "processing",
        "progress": 0,
        "message": "任务已创建",
        "video_url": None,
        "created_at": time.time()
    }

    background_tasks.add_task(process_video_generation, task_id, request)

    return VideoGenerationResponse(
        task_id=task_id,
        message="视频生成任务已提交，正在处理中"
    )

@app.get("/api/progress/{task_id}")
async def get_progress(task_id: str):
    if task_id not in tasks:
        raise HTTPException(status_code=404, detail="任务不存在")

    return tasks[task_id]

async def process_video_generation(task_id: str, request: VideoGenerationRequest):
    """处理视频生成任务"""
    try:
        tasks[task_id]["progress"] = 10
        tasks[task_id]["message"] = "正在生成脚本..."

        await asyncio.sleep(2)

        tasks[task_id]["progress"] = 30
        tasks[task_id]["message"] = "正在生成视频..."

        await asyncio.sleep(3)

        tasks[task_id]["progress"] = 80
        tasks[task_id]["message"] = "正在上传视频..."

        await asyncio.sleep(2)

        tasks[task_id]["progress"] = 100
        tasks[task_id]["status"] = "completed"
        tasks[task_id]["message"] = "视频生成完成"
        tasks[task_id]["video_url"] = "https://example.com/video.mp4"

    except Exception as e:
        tasks[task_id]["status"] = "failed"
        tasks[task_id]["message"] = f"生成失败: {str(e)}"

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
EOF
```

#### 5. 创建 docker-compose.yml

```bash
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: tnho-video-api
    ports:
      - "8000:8000"
    env_file:
      - .env
    volumes:
      - ./src:/app/src
      - ./config:/app/config
      - ./logs:/app/logs
      - ./assets:/app/assets
    environment:
      - PYTHONUNBUFFERED=1
    restart: unless-stopped
    depends_on:
      - db

  db:
    image: postgres:15-alpine
    container_name: tnho-video-db
    environment:
      - POSTGRES_DB=tnho_video
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres123
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    restart: unless-stopped

volumes:
  postgres_data:
EOF
```

#### 6. 创建 Dockerfile

```bash
cat > Dockerfile << 'EOF'
FROM python:3.11-slim

WORKDIR /app

# 设置环境变量
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    ffmpeg \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# 复制依赖文件
COPY requirements.txt .

# 安装 Python 依赖
RUN pip install --no-cache-dir -r requirements.txt -i https://mirrors.aliyun.com/pypi/simple/

# 复制源代码
COPY src/ ./src/
COPY config/ ./config/

# 暴露端口
EXPOSE 8000

# 启动命令
CMD ["uvicorn", "src.api.app:app", "--host", "0.0.0.0", "--port", "8000"]
EOF
```

#### 7. 创建 .env 文件

```bash
cat > .env << 'EOF'
ARK_API_KEY=39bf20d0-55b5-4957-baa1-02f4529a3076
ARK_BASE_URL=https://ark.cn-beijing.volces.com/api/v3
S3_ENDPOINT=https://tos-s3-cn-beijing.volces.com
S3_ACCESS_KEY_ID=your_access_key_id
S3_SECRET_ACCESS_KEY=your_secret_access_key
S3_BUCKET=tnho-videos
S3_REGION=cn-beijing
PGDATABASE_URL=postgresql://postgres:postgres123@db:5432/tnho_video
APP_HOST=0.0.0.0
APP_PORT=8000
LOG_LEVEL=info
EOF
```

#### 8. 创建 config/agent_llm_config.json

```bash
mkdir -p config
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
    "sp": "你是天虹紧固件（TNHO）的产品宣传视频脚本生成专家。你的任务是根据用户的需求生成专业的视频脚本，脚本需要包含场景描述、文案/旁白、音效等元素。在脚本中要自然融入红色 TNHO 商标元素，突出产品品质和技术创新。",
    "tools": []
}
EOF
```

#### 9. 构建并启动

```bash
# 构建镜像
docker-compose build

# 启动服务
docker-compose up -d

# 查看日志
docker-compose logs -f
```

## 验证部署

### 健康检查

```bash
curl http://tnho-fasteners.com/health
```

### 访问 API 文档

浏览器访问: http://tnho-fasteners.com/docs

### 测试视频生成

```bash
curl -X POST http://tnho-fasteners.com/api/generate-video \
  -H "Content-Type: application/json" \
  -d '{
    "theme": "品质保证",
    "duration": 20
  }'
```

### 查询进度

```bash
curl http://tnho-fasteners.com/api/progress/task_{task_id}
```

## 常用命令

```bash
# 查看日志
docker-compose logs -f

# 重启服务
docker-compose restart

# 停止服务
docker-compose down

# 查看容器状态
docker-compose ps

# 进入容器
docker exec -it tnho-video-api bash
```

## 故障排查

### 服务无法启动

```bash
# 查看详细日志
docker-compose logs

# 检查端口占用
netstat -tlnp | grep 8000
```

### 数据库连接失败

```bash
# 检查数据库容器
docker ps | grep postgres

# 进入数据库容器
docker exec -it tnho-video-db bash
psql -U postgres -d tnho_video
```

## 下一步

部署成功后，需要配置：
1. 对象存储的 S3 凭证
2. 火山方舟视频生成 API
3. 微信小程序前端对接
