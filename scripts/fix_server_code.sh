#!/bin/bash
# 服务器代码修复脚本 - 生成所有缺失的文件

set -e

PROJECT_DIR="/root/tnho-video-api"
cd "$PROJECT_DIR"

echo "======================================"
echo "修复服务器代码"
echo "======================================"

# 1. 创建缺失的目录
echo ""
echo "步骤 1: 创建目录结构..."
mkdir -p src/agents
mkdir -p src/api
mkdir -p src/storage/database
mkdir -p src/storage/s3

# 2. 更新 requirements.txt
echo ""
echo "步骤 2: 更新 requirements.txt..."
cat > requirements.txt << 'EOF'
fastapi==0.121.2
uvicorn[standard]==0.38.0
langchain==1.0.3
langchain-core==1.0.2
langchain-openai==1.0.1
langgraph==1.0.2
pydantic==2.12.3
requests==2.32.5
python-multipart==0.0.21
python-dotenv==1.2.1
moviepy==2.2.1
opencv-python==4.12.0.88
imageio-ffmpeg==0.6.0
imageio==2.37.2
psycopg2-binary==2.9.9
sqlalchemy==2.0.44
langgraph-checkpoint==3.0.0
langgraph-checkpoint-postgres==3.0.1
tenacity==9.1.2
orjson==3.11.5
tiktoken==0.12.0
coze-coding-dev-sdk==0.5.3
EOF

# 3. 创建 src/agents/agent.py
echo ""
echo "步骤 3: 创建 src/agents/agent.py..."
cat > src/agents/agent.py << 'AGENT_EOF'
import os
import json
from typing import Annotated
from langchain.agents import create_agent
from langchain_openai import ChatOpenAI
from langgraph.graph import MessagesState
from langgraph.graph.message import add_messages
from langchain_core.messages import AnyMessage

# 导入工具
from tools.video_generation_tool import generate_fastener_promo_video
from tools.video_script_generator import generate_fastener_promo_script
from storage.memory.memory_saver import get_memory_saver

LLM_CONFIG = "config/agent_llm_config.json"

# 默认保留最近 20 轮对话 (40 条消息)
MAX_MESSAGES = 40


def _windowed_messages(old, new):
    """滑动窗口: 只保留最近 MAX_MESSAGES 条消息"""
    return add_messages(old, new)[-MAX_MESSAGES:]


class AgentState(MessagesState):
    messages: Annotated[list[AnyMessage], _windowed_messages]


def build_agent(ctx=None):
    workspace_path = os.getenv("COZE_WORKSPACE_PATH", "/app")
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
        generate_fastener_promo_script
    ]

    return create_agent(
        model=llm,
        system_prompt=cfg.get("sp"),
        tools=tools,
        checkpointer=get_memory_saver(),
        state_schema=AgentState,
    )
AGENT_EOF

# 4. 创建 src/api/app.py
echo ""
echo "步骤 4: 创建 src/api/app.py..."
echo "注意：这个文件很大，请稍等..."
cat > src/api/app.py << 'APP_EOF'
"""
FastAPI 后端服务
为微信小程序提供视频生成接口
"""
import os
import sys
import json
import base64
import tempfile
from pathlib import Path

# 添加项目根目录和 src 目录到 Python 路径
workspace_path = os.getenv("COZE_WORKSPACE_PATH", "/app")
src_path = os.path.join(workspace_path, "src")

if workspace_path not in sys.path:
    sys.path.insert(0, workspace_path)
if src_path not in sys.path:
    sys.path.insert(0, src_path)

from fastapi import FastAPI, HTTPException, UploadFile, File, Form, BackgroundTasks
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
from typing import Optional
import asyncio
import uuid

from agents.agent import build_agent
from langgraph.types import RunnableConfig
from storage.database.db import get_session
from storage.database.video_task_manager import VideoTaskManager, VideoTaskCreate, VideoTaskResponse

# 初始化 FastAPI 应用
app = FastAPI(
    title="天虹紧固件视频生成 API",
    description="为微信小程序提供AI视频生成服务",
    version="1.1.0"
)

# 挂载静态文件服务
assets_path = Path(workspace_path) / "assets"
assets_path.mkdir(parents=True, exist_ok=True)
app.mount("/assets", StaticFiles(directory=str(assets_path)), name="assets")

# 请求模型
class VideoGenerateRequest(BaseModel):
    product_name: str
    theme: str = "品质保证"
    duration: int = 20
    type: str = "video"
    scenario: str = ""
    product_image_url: str = ""
    session_id: Optional[str] = None

# 响应模型
class VideoGenerateResponse(BaseModel):
    success: bool
    message: str
    video_url: Optional[str] = None
    video_url_part1: Optional[str] = None
    video_url_part2: Optional[str] = None
    merged_video_path: Optional[str] = None
    merged_video_url: Optional[str] = None
    video_urls: Optional[list] = None
    script_content: Optional[str] = None
    session_id: Optional[str] = None
    task_id: Optional[str] = None
    type: Optional[str] = None

# 进度查询响应模型
class ProgressResponse(BaseModel):
    success: bool
    task_id: Optional[str] = None
    status: Optional[str] = None
    progress: Optional[int] = None
    current_step: Optional[str] = None
    total_parts: Optional[int] = None
    completed_parts: Optional[int] = None
    video_urls: Optional[list] = None
    merged_video_url: Optional[str] = None
    script_content: Optional[str] = None
    error_message: Optional[str] = None
    message: Optional[str] = None

# 全局 Agent 实例
_agent_instance = None

def get_agent():
    global _agent_instance
    if _agent_instance is None:
        _agent_instance = build_agent()
    return _agent_instance


@app.get("/")
async def root():
    return {
        "status": "running",
        "service": "天虹紧固件视频生成 API",
        "version": "1.1.0"
    }


@app.get("/health")
async def health_check():
    return {"status": "ok"}


@app.post("/api/generate-video", response_model=VideoGenerateResponse)
async def generate_video(request: VideoGenerateRequest, background_tasks: BackgroundTasks):
    try:
        valid_themes = ["品质保证", "技术创新", "工业应用", "品牌形象"]
        if request.theme not in valid_themes:
            return VideoGenerateResponse(
                success=False,
                message=f"主题无效，可选主题：{', '.join(valid_themes)}"
            )

        valid_types = ["video", "script"]
        if request.type not in valid_types:
            return VideoGenerateResponse(
                success=False,
                message=f"类型无效，可选类型：{', '.join(valid_types)}"
            )

        # 生成任务ID
        task_id = str(uuid.uuid4())

        # 计算分段数量
        def calculate_total_parts(duration: int) -> int:
            if duration <= 12:
                return 1
            elif duration <= 20:
                return 2
            elif duration <= 30:
                return 3
            else:
                return 3

        total_parts = calculate_total_parts(request.duration)

        # 创建任务记录
        db = get_session()
        try:
            mgr = VideoTaskManager()
            task_create = VideoTaskCreate(
                task_id=task_id,
                session_id=request.session_id,
                product_name=request.product_name,
                theme=request.theme,
                duration=request.duration,
                type=request.type
            )
            mgr.create_task(db, task_create, total_parts=total_parts)
        except Exception as e:
            print(f"创建任务记录失败: {e}")
        finally:
            db.close()

        return VideoGenerateResponse(
            success=True,
            message="任务已创建，请使用 task_id 查询进度",
            task_id=task_id,
            session_id=request.session_id,
            type=request.type
        )

    except Exception as e:
        return VideoGenerateResponse(
            success=False,
            message=f"创建任务失败: {str(e)}"
        )


@app.get("/api/progress/{task_id}", response_model=ProgressResponse)
async def get_progress(task_id: str):
    try:
        db = get_session()
        try:
            mgr = VideoTaskManager()
            task = mgr.get_task(db, task_id)
            if not task:
                return ProgressResponse(
                    success=False,
                    message="任务不存在"
                )

            return ProgressResponse(
                success=True,
                task_id=task.task_id,
                status=task.status,
                progress=task.progress,
                current_step=task.current_step,
                total_parts=task.total_parts,
                completed_parts=task.completed_parts,
                video_urls=task.video_urls,
                merged_video_url=task.merged_video_url,
                script_content=task.script_content,
                error_message=task.error_message,
                message="查询成功"
            )
        except Exception as e:
            return ProgressResponse(
                success=False,
                message=f"查询失败: {str(e)}"
            )
        finally:
            db.close()
    except Exception as e:
        return ProgressResponse(
            success=False,
            message=f"查询失败: {str(e)}"
        )


@app.post("/api/upload-image", response_model=dict)
async def upload_image(file: UploadFile = File(...)):
    try:
        allowed_types = ["image/jpeg", "image/png", "image/jpg"]
        if file.content_type not in allowed_types:
            return {
                "success": False,
                "message": "仅支持 JPG、PNG 格式的图片"
            }

        max_size = 5 * 1024 * 1024
        file_size = 0
        for chunk in file.file:
            file_size += len(chunk)
            if file_size > max_size:
                return {
                    "success": False,
                    "message": "图片大小不能超过 5MB"
                }
        file.file.seek(0)

        upload_dir = Path(workspace_path) / "assets" / "uploads"
        upload_dir.mkdir(parents=True, exist_ok=True)

        file_extension = Path(file.filename).suffix
        unique_filename = f"{uuid.uuid4()}{file_extension}"
        file_path = upload_dir / unique_filename

        with open(file_path, "wb") as f:
            content = await file.read()
            f.write(content)

        base_url = os.getenv("EXTERNAL_BASE_URL", "http://47.110.72.148")
        image_url = f"{base_url}/assets/uploads/{unique_filename}"

        return {
            "success": True,
            "message": "图片上传成功",
            "image_url": image_url,
            "filename": unique_filename
        }
    except Exception as e:
        import traceback
        traceback.print_exc()
        return {
            "success": False,
            "message": f"图片上传失败: {str(e)}"
        }
APP_EOF

echo "✅ src/api/app.py 已创建"

# 5. 重新构建并启动容器
echo ""
echo "步骤 5: 重新构建并启动容器..."
docker-compose down
docker-compose build --no-cache
docker-compose up -d

# 6. 等待启动
echo ""
echo "等待容器启动 (15秒)..."
sleep 15

# 7. 检查容器状态
echo ""
echo "======================================"
echo "容器状态:"
docker ps | grep tnho

# 8. 检查 API 端点
echo ""
echo "======================================"
echo "检查 API 端点:"
curl -s http://localhost:8000/openapi.json | python3 -c "
import sys, json
data = json.load(sys.stdin)
paths = data.get('paths', {})
print(f'总路由数: {len(paths)}')
for k in sorted(paths.keys()):
    print(f'  {k}')
"

echo ""
echo "======================================"
echo "修复完成！"
echo "======================================"
