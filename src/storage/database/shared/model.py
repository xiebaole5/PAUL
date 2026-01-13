from sqlalchemy import Column, Integer, String, DateTime, Text, JSON, func
from sqlalchemy.orm import DeclarativeBase
from typing import Optional

class Base(DeclarativeBase):
    pass

class VideoGenerationTask(Base):
    """视频生成任务进度表"""
    __tablename__ = "video_generation_tasks"

    id = Column(Integer, primary_key=True, autoincrement=True, comment="主键ID")
    task_id = Column(String(64), unique=True, nullable=False, index=True, comment="任务ID")
    session_id = Column(String(64), nullable=True, index=True, comment="会话ID")
    product_name = Column(String(255), nullable=False, comment="产品名称")
    theme = Column(String(50), nullable=False, comment="主题（品质保证/技术创新/工业应用/品牌形象）")
    duration = Column(Integer, nullable=False, comment="视频时长（秒）")
    type = Column(String(20), nullable=False, comment="类型（video/script）")
    
    # 进度状态
    status = Column(String(30), nullable=False, server_default="pending", comment="状态（pending/generating/merging/uploading/completed/failed）")
    progress = Column(Integer, nullable=False, server_default="0", comment="进度百分比（0-100）")
    current_step = Column(String(255), nullable=True, comment="当前步骤描述")
    
    # 多段视频信息
    total_parts = Column(Integer, nullable=False, server_default="1", comment="总段数")
    completed_parts = Column(Integer, nullable=False, server_default="0", comment="已完成段数")
    video_urls = Column(JSON, nullable=True, comment="生成的视频URL列表")
    
    # 结果
    merged_video_url = Column(Text, nullable=True, comment="拼接后的视频URL")
    script_content = Column(Text, nullable=True, comment="脚本内容（script类型）")
    
    # 错误信息
    error_message = Column(Text, nullable=True, comment="错误信息")
    
    # 时间戳
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False, comment="创建时间")
    updated_at = Column(DateTime(timezone=True), onupdate=func.now(), nullable=True, comment="更新时间")
    completed_at = Column(DateTime(timezone=True), nullable=True, comment="完成时间")

