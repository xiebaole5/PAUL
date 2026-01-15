"""
FastAPI 后端服务
为微信小程序提供视频生成接口
"""
from dotenv import load_dotenv
load_dotenv()  # 加载 .env 文件中的环境变量

import os
import sys
import json
import base64
import tempfile
from pathlib import Path

# 添加项目根目录和 src 目录到 Python 路径（必须在所有导入之前）
workspace_path = os.getenv("COZE_WORKSPACE_PATH", "/app")
src_path = os.path.join(workspace_path, "src")

# 同时添加 /app 和 /app/src 到 sys.path
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
from storage.database.session import get_db_session
from storage.database.video_task_manager import VideoTaskManager, VideoTaskCreate, VideoTaskResponse

# 导入企业微信模块
from src.api.wechat_callback_simple import router as wechat_callback_router
from src.api.enterprise_wechat import router as enterprise_wechat_router

# 导入请求日志中间件
from src.api.middleware import RequestLoggingMiddleware

# 初始化 FastAPI 应用
app = FastAPI(
    title="天虹紧固件视频生成 API",
    description="为微信小程序提供AI视频生成服务",
    version="1.1.0"
)

# 添加请求日志中间件
app.add_middleware(RequestLoggingMiddleware)

# 挂载静态文件服务
assets_path = Path(workspace_path) / "assets"
assets_path.mkdir(parents=True, exist_ok=True)
app.mount("/assets", StaticFiles(directory=str(assets_path)), name="assets")

# 注册企业微信路由
app.include_router(wechat_callback_router)
app.include_router(enterprise_wechat_router)

# 请求模型
class VideoGenerateRequest(BaseModel):
    product_name: str
    theme: str = "品质保证"
    duration: int = 20
    type: str = "video"  # video 或 script
    scenario: str = ""  # 使用场景描述
    product_image_url: str = ""  # 产品图片URL
    session_id: Optional[str] = None

# 响应模型
class VideoGenerateResponse(BaseModel):
    success: bool
    message: str
    video_url: Optional[str] = None
    video_url_part1: Optional[str] = None  # 第一段视频URL（如果生成两段视频）
    video_url_part2: Optional[str] = None  # 第二段视频URL（如果生成两段视频）
    merged_video_path: Optional[str] = None  # 拼接后的视频路径
    merged_video_url: Optional[str] = None  # 拼接后的视频URL（上传到对象存储后）
    video_urls: Optional[list] = None  # 所有生成的视频URL列表
    script_content: Optional[str] = None
    session_id: Optional[str] = None
    task_id: Optional[str] = None  # 任务ID
    type: Optional[str] = None  # video 或 script

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
    """获取或创建 Agent 实例"""
    global _agent_instance
    if _agent_instance is None:
        _agent_instance = build_agent()
    return _agent_instance

async def process_video_generation_task(
    task_id: str,
    request: VideoGenerateRequest,
    total_parts: int = 1
):
    """
    后台处理视频生成任务

    Args:
        task_id: 任务ID
        request: 视频生成请求
        total_parts: 总段数
    """
    from langchain.tools import tool, ToolRuntime

    # 创建进度回调函数
    def progress_callback(progress: int, message: str):
        """进度回调函数"""
        with get_db_session() as db:
            try:
                mgr = VideoTaskManager()
                mgr.update_progress(db, task_id, progress, message)
            except Exception as e:
                print(f"更新进度失败: {e}")

    # 获取 Agent
    agent = get_agent()

    try:
        # 更新状态为生成中
        progress_callback(0, "开始生成视频...")

        # 构造用户消息
        prompt_parts = [f"请为{request.product_name}生成一个{request.theme}主题的宣传视频，时长{request.duration}秒"]
        if request.scenario:
            prompt_parts.append(f"，使用场景：{request.scenario}")
        if request.product_image_url:
            prompt_parts.append(f"，参考产品图片：{request.product_image_url}")
        user_message = "".join(prompt_parts)

        # 配置运行时参数
        config = RunnableConfig(
            configurable={
                "thread_id": request.session_id or "default"
            }
        )

        # 调用 Agent
        response = await agent.ainvoke(
            {"messages": [("user", user_message)]},
            config=config
        )

        # 解析响应
        video_url = None
        video_url_part1 = None
        video_url_part2 = None
        merged_video_path = None
        merged_video_url = None
        video_urls = None
        content_text = ""

        # 遍历所有消息，查找视频生成工具的结果
        for msg in response["messages"]:
            msg_content = msg.content if hasattr(msg, 'content') else str(msg)
            content_text += str(msg_content)

            # 尝试解析 JSON
            if isinstance(msg_content, str) and msg_content.strip().startswith('{'):
                try:
                    response_data = json.loads(msg_content)
                    if "video_url" in response_data:
                        video_url = response_data.get("video_url")
                        video_url_part1 = response_data.get("video_url_part1")
                        video_url_part2 = response_data.get("video_url_part2")
                        merged_video_path = response_data.get("merged_video_path")
                        merged_video_url = response_data.get("merged_video_url")
                        video_urls = response_data.get("video_urls")
                        break
                except:
                    pass

        # 更新任务状态
        with get_db_session() as db:
            try:
                mgr = VideoTaskManager()
                if video_url:
                    result_data = {
                        "video_urls": video_urls or [video_url],
                        "merged_video_url": merged_video_url
                    }
                    mgr.mark_as_completed(db, task_id, result_data)
                else:
                    mgr.mark_as_failed(db, task_id, f"无法从响应中提取视频 URL。响应内容：{content_text}")
            except Exception as e:
                print(f"更新任务状态失败: {e}")

    except Exception as e:
        # 标记任务失败
        with get_db_session() as db:
            try:
                mgr = VideoTaskManager()
                mgr.mark_as_failed(db, task_id, str(e))
            except Exception as e2:
                print(f"标记任务失败时出错: {e2}")

@app.get("/")
async def root():
    """API 健康检查"""
    return {
        "status": "running",
        "service": "天虹紧固件视频生成 API",
        "version": "1.1.0"
    }

@app.get("/health")
async def health_check():
    """健康检查接口"""
    return {"status": "ok"}

@app.post("/api/upload-image", response_model=dict)
async def upload_image(file: UploadFile = File(...)):
    """
    上传产品图片

    参数:
        file: 图片文件

    返回:
        图片URL
    """
    try:
        # 检查文件类型
        allowed_types = ["image/jpeg", "image/png", "image/jpg"]
        if file.content_type not in allowed_types:
            return {
                "success": False,
                "message": "仅支持 JPG、PNG 格式的图片"
            }

        # 检查文件大小（限制为 5MB）
        max_size = 5 * 1024 * 1024  # 5MB
        file_size = 0
        for chunk in file.file:
            file_size += len(chunk)
            if file_size > max_size:
                return {
                    "success": False,
                    "message": "图片大小不能超过 5MB"
                }
        file.file.seek(0)  # 重置文件指针

        # 创建临时目录保存图片
        upload_dir = Path(workspace_path) / "assets" / "uploads"
        upload_dir.mkdir(parents=True, exist_ok=True)

        # 生成唯一文件名
        file_extension = Path(file.filename).suffix
        unique_filename = f"{uuid.uuid4()}{file_extension}"
        file_path = upload_dir / unique_filename

        # 保存图片
        with open(file_path, "wb") as f:
            content = await file.read()
            f.write(content)

        # 获取外部访问的 base URL（从环境变量或默认值）
        base_url = os.getenv("EXTERNAL_BASE_URL", "https://tnho-fasteners.com")

        # 返回图片 URL
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

@app.post("/api/generate-video", response_model=VideoGenerateResponse)
async def generate_video(request: VideoGenerateRequest, background_tasks: BackgroundTasks):
    """
    生成紧固件宣传视频或脚本

    参数:
        product_name: 产品名称
        theme: 主题 (品质保证|技术创新|工业应用|品牌形象)
        duration: 视频时长（秒，默认20秒，推荐范围5-30秒）
        type: 生成类型（video-生成视频，script-生成脚本）
        session_id: 可选的会话ID

    返回:
        success: 是否成功
        message: 消息
        task_id: 任务ID（用于查询进度）
        session_id: 会话ID
        type: 生成类型

    注意：
        - 视频生成是异步执行的，需要使用 /api/progress/{task_id} 查询进度
        - 对于 script 类型，仍然同步返回结果
    """
    try:
        # 验证主题
        valid_themes = ["品质保证", "技术创新", "工业应用", "品牌形象"]
        if request.theme not in valid_themes:
            return VideoGenerateResponse(
                success=False,
                message=f"主题无效，可选主题：{', '.join(valid_themes)}"
            )

        # 验证类型
        valid_types = ["video", "script"]
        if request.type not in valid_types:
            return VideoGenerateResponse(
                success=False,
                message=f"类型无效，可选类型：{', '.join(valid_types)}"
            )

        # 脚本生成仍然同步执行
        if request.type == "script":
            agent = get_agent()
            user_message = f"请为{request.product_name}生成一个{request.theme}主题的宣传视频脚本，时长{request.duration}秒，包含场景描述、文案/旁白、音效"
            if request.scenario:
                user_message += f"，使用场景：{request.scenario}"

            config = RunnableConfig(
                configurable={
                    "thread_id": request.session_id or "default"
                }
            )

            response = await agent.ainvoke(
                {"messages": [("user", user_message)]},
                config=config
            )

            script_content = ""
            for msg in response["messages"]:
                msg_content = msg.content if hasattr(msg, 'content') else str(msg)
                script_content += str(msg_content)

            return VideoGenerateResponse(
                success=True,
                message="脚本生成成功",
                script_content=script_content,
                session_id=request.session_id,
                type="script"
            )

        # 视频生成改为异步执行
        # 生成任务ID
        task_id = str(uuid.uuid4())

        # 计算分段数量
        def calculate_total_parts(duration: int) -> int:
            if duration <= 12:
                return 1
            elif duration == 15 or duration == 20:
                return 2
            elif duration == 25 or duration == 30:
                return 3
            else:
                if duration <= 20:
                    return 2
                else:
                    return 3

        total_parts = calculate_total_parts(request.duration)

        # 创建任务记录
        with get_db_session() as db:
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

        # 添加后台任务
        background_tasks.add_task(
            process_video_generation_task,
            task_id,
            request,
            total_parts
        )

        return VideoGenerateResponse(
            success=True,
            message=f"视频生成任务已创建，任务ID: {task_id}。请使用 /api/progress/{task_id} 查询进度。",
            task_id=task_id,
            session_id=request.session_id,
            type="video"
        )

    except Exception as e:
        import traceback
        traceback.print_exc()
        return VideoGenerateResponse(
            success=False,
            message=f"创建任务失败: {str(e)}"
        )

@app.get("/api/progress/{task_id}", response_model=ProgressResponse)
async def get_progress(task_id: str):
    """
    查询视频生成任务进度

    参数:
        task_id: 任务ID

    返回:
        success: 是否成功
        task_id: 任务ID
        status: 任务状态（pending/generating/merging/uploading/completed/failed）
        progress: 进度百分比（0-100）
        current_step: 当前步骤描述
        total_parts: 总段数
        completed_parts: 已完成段数
        video_urls: 生成的视频URL列表
        merged_video_url: 拼接后的视频URL
        script_content: 脚本内容（如果是script类型）
        error_message: 错误信息（如果失败）
        message: 消息
    """
    with get_db_session() as db:
        try:
            mgr = VideoTaskManager()
            task = mgr.get_task_by_id(db, task_id)

            if not task:
                return ProgressResponse(
                    success=False,
                    task_id=task_id,
                    message=f"任务不存在：{task_id}"
                )

            # 将任务转换为响应模型
            response_data = {
                "success": True,
                "task_id": task.task_id,
                "status": task.status,
                "progress": task.progress,
                "current_step": task.current_step,
                "total_parts": task.total_parts,
                "completed_parts": task.completed_parts,
                "video_urls": task.video_urls,
                "merged_video_url": task.merged_video_url,
                "script_content": task.script_content,
                "error_message": task.error_message,
                "message": _get_status_message(task.status, task.progress)
            }

            return ProgressResponse(**response_data)

        except Exception as e:
            import traceback
            traceback.print_exc()
            return ProgressResponse(
                success=False,
                task_id=task_id,
                message=f"查询进度失败: {str(e)}"
            )

def _get_status_message(status: str, progress: int) -> str:
    """根据状态生成友好的消息"""
    messages = {
        "pending": "任务等待中...",
        "generating": f"正在生成视频... ({progress}%)",
        "merging": f"正在拼接视频... ({progress}%)",
        "uploading": f"正在上传视频... ({progress}%)",
        "completed": "任务已完成！",
        "failed": "任务失败"
    }
    return messages.get(status, f"任务状态: {status}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
