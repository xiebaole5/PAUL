"""
视频生成任务进度管理器
管理视频生成任务的创建、更新和查询
"""
from typing import List, Optional
from pydantic import BaseModel, Field
from datetime import datetime
from sqlalchemy.orm import Session

from storage.database.shared.model import VideoGenerationTask


# --- Pydantic Models ---
class VideoTaskCreate(BaseModel):
    """创建视频任务的数据模型"""
    task_id: str = Field(..., description="任务ID")
    session_id: Optional[str] = Field(None, description="会话ID")
    product_name: str = Field(..., description="产品名称")
    theme: str = Field(..., description="主题")
    duration: int = Field(..., description="视频时长（秒）")
    type: str = Field(..., description="类型（video/script）")


class VideoTaskUpdate(BaseModel):
    """更新视频任务的数据模型"""
    status: Optional[str] = Field(None, description="状态")
    progress: Optional[int] = Field(None, ge=0, le=100, description="进度百分比（0-100）")
    current_step: Optional[str] = Field(None, description="当前步骤描述")
    completed_parts: Optional[int] = Field(None, ge=0, description="已完成段数")
    video_urls: Optional[List[str]] = Field(None, description="生成的视频URL列表")
    merged_video_url: Optional[str] = Field(None, description="拼接后的视频URL")
    script_content: Optional[str] = Field(None, description="脚本内容")
    error_message: Optional[str] = Field(None, description="错误信息")


class VideoTaskResponse(BaseModel):
    """视频任务响应数据模型"""
    id: int
    task_id: str
    session_id: Optional[str]
    product_name: str
    theme: str
    duration: int
    type: str
    status: str
    progress: int
    current_step: Optional[str]
    total_parts: int
    completed_parts: int
    video_urls: Optional[List[str]]
    merged_video_url: Optional[str]
    script_content: Optional[str]
    error_message: Optional[str]
    created_at: datetime
    updated_at: Optional[datetime]
    completed_at: Optional[datetime]

    class Config:
        from_attributes = True


# --- Manager Class ---
class VideoTaskManager:
    """视频生成任务管理器"""

    def create_task(self, db: Session, task_in: VideoTaskCreate, total_parts: int = 1) -> VideoGenerationTask:
        """
        创建新的视频生成任务

        Args:
            db: 数据库会话
            task_in: 任务创建数据
            total_parts: 总段数（默认为1）

        Returns:
            创建的任务对象
        """
        task_data = task_in.model_dump()
        task_data["total_parts"] = total_parts

        db_task = VideoGenerationTask(**task_data)
        db.add(db_task)
        try:
            db.commit()
            db.refresh(db_task)
            return db_task
        except Exception:
            db.rollback()
            raise

    def get_task_by_id(self, db: Session, task_id: str) -> Optional[VideoGenerationTask]:
        """
        根据任务ID获取任务

        Args:
            db: 数据库会话
            task_id: 任务ID

        Returns:
            任务对象或None
        """
        return db.query(VideoGenerationTask).filter(VideoGenerationTask.task_id == task_id).first()

    def get_tasks_by_session(self, db: Session, session_id: str, skip: int = 0, limit: int = 10) -> List[VideoGenerationTask]:
        """
        根据会话ID获取任务列表

        Args:
            db: 数据库会话
            session_id: 会话ID
            skip: 跳过的记录数
            limit: 返回的最大记录数

        Returns:
            任务列表
        """
        return db.query(VideoGenerationTask)\
            .filter(VideoGenerationTask.session_id == session_id)\
            .order_by(VideoGenerationTask.created_at.desc())\
            .offset(skip)\
            .limit(limit)\
            .all()

    def update_task(self, db: Session, task_id: str, task_in: VideoTaskUpdate) -> Optional[VideoGenerationTask]:
        """
        更新任务状态

        Args:
            db: 数据库会话
            task_id: 任务ID
            task_in: 更新数据

        Returns:
            更新后的任务对象或None
        """
        db_task = self.get_task_by_id(db, task_id)
        if not db_task:
            return None

        update_data = task_in.model_dump(exclude_unset=True)

        # 如果状态更新为 completed，设置 completed_at
        if "status" in update_data and update_data["status"] == "completed" and not db_task.completed_at:
            update_data["completed_at"] = datetime.now()

        for field, value in update_data.items():
            if hasattr(db_task, field):
                setattr(db_task, field, value)

        db.add(db_task)
        try:
            db.commit()
            db.refresh(db_task)
            return db_task
        except Exception:
            db.rollback()
            raise

    def update_progress(self, db: Session, task_id: str, progress: int, current_step: str = None) -> Optional[VideoGenerationTask]:
        """
        快速更新任务进度

        Args:
            db: 数据库会话
            task_id: 任务ID
            progress: 进度百分比（0-100）
            current_step: 当前步骤描述（可选）

        Returns:
            更新后的任务对象或None
        """
        return self.update_task(db, task_id, VideoTaskUpdate(progress=progress, current_step=current_step))

    def increment_completed_parts(self, db: Session, task_id: str) -> Optional[VideoGenerationTask]:
        """
        增加已完成段数

        Args:
            db: 数据库会话
            task_id: 任务ID

        Returns:
            更新后的任务对象或None
        """
        db_task = self.get_task_by_id(db, task_id)
        if not db_task:
            return None

        new_count = db_task.completed_parts + 1
        # 计算进度：生成阶段 70%，拼接阶段 20%，上传阶段 10%
        if new_count <= db_task.total_parts:
            progress = int((new_count / db_task.total_parts) * 70)
        else:
            progress = 70

        return self.update_task(db, task_id, VideoTaskUpdate(completed_parts=new_count, progress=progress))

    def mark_as_failed(self, db: Session, task_id: str, error_message: str) -> Optional[VideoGenerationTask]:
        """
        标记任务为失败

        Args:
            db: 数据库会话
            task_id: 任务ID
            error_message: 错误信息

        Returns:
            更新后的任务对象或None
        """
        return self.update_task(db, task_id, VideoTaskUpdate(
            status="failed",
            error_message=error_message
        ))

    def mark_as_completed(self, db: Session, task_id: str, result: dict) -> Optional[VideoGenerationTask]:
        """
        标记任务为完成

        Args:
            db: 数据库会话
            task_id: 任务ID
            result: 结果数据（包含 video_urls, merged_video_url 或 script_content）

        Returns:
            更新后的任务对象或None
        """
        update_data = {
            "status": "completed",
            "progress": 100
        }

        if "video_urls" in result:
            update_data["video_urls"] = result["video_urls"]
        if "merged_video_url" in result:
            update_data["merged_video_url"] = result["merged_video_url"]
        if "script_content" in result:
            update_data["script_content"] = result["script_content"]

        return self.update_task(db, task_id, VideoTaskUpdate(**update_data))

    def to_response(self, task: VideoGenerationTask) -> VideoTaskResponse:
        """
        将任务对象转换为响应模型

        Args:
            task: 任务对象

        Returns:
            响应模型
        """
        return VideoTaskResponse.model_validate(task)
