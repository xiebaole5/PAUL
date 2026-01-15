"""
FastAPI 后端服务 - 微信小程序视频生成 API
提供 RESTful API 供微信小程序调用
"""
from fastapi import FastAPI, HTTPException, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
import uvicorn
import json
import os

# 导入小程序 Agent
from agents.miniprogram_video_agent import build_agent
from tools.miniprogram_video_tool import (
    generate_ad_script,
    generate_frame_images,
    generate_miniprogram_video
)

# 创建 FastAPI 应用
app = FastAPI(
    title="天虹紧固件视频生成 API",
    description="为微信小程序提供视频生成服务的后端 API",
    version="1.0.0"
)

# 配置 CORS - 允许微信小程序跨域调用
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 生产环境应该指定具体的小程序域名
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ==================== 请求模型定义 ====================

class ScriptRequest(BaseModel):
    """生成脚本请求"""
    product_name: str
    product_image_url: str
    usage_scenario: str
    theme_direction: str

class FrameImagesRequest(BaseModel):
    """生成首尾帧图片请求"""
    script: str
    product_name: str = "紧固件"
    product_image_url: str = ""

class VideoRequest(BaseModel):
    """生成视频请求"""
    script: str
    product_name: str
    product_image_url: str
    selected_first_frame: str
    selected_last_frame: str

# ==================== API 接口 ====================

@app.get("/")
async def root():
    """根路径 - API 状态检查"""
    return {
        "status": "running",
        "service": "天虹紧固件视频生成 API",
        "version": "1.0.0",
        "endpoints": {
            "/script": "生成广告脚本",
            "/frames": "生成首尾帧图片",
            "/video": "生成视频",
            "/health": "健康检查"
        }
    }

@app.get("/health")
async def health():
    """健康检查接口"""
    return {"status": "healthy"}

@app.post("/api/v1/generate-script")
async def generate_script(request: ScriptRequest):
    """
    生成 20 秒广告脚本

    参数：
    - product_name: 产品名称（必填）
    - product_image_url: 产品图片 URL（必填）
    - usage_scenario: 使用场景（必填）
    - theme_direction: 主题方向（必填）

    返回：
    - script: 生成的脚本内容
    - success: 是否成功
    """
    try:
        # 调用工具生成脚本
        result = generate_ad_script.invoke({
            "product_name": request.product_name,
            "product_image_url": request.product_image_url,
            "usage_scenario": request.usage_scenario,
            "theme_direction": request.theme_direction
        })

        # 解析返回的 JSON
        result_dict = json.loads(result)

        return {
            "code": 0,
            "message": "脚本生成成功",
            "data": result_dict
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"脚本生成失败: {str(e)}")

@app.post("/api/v1/generate-frames")
async def generate_frames(request: FrameImagesRequest):
    """
    生成首尾帧图片（各 2 张供用户选择）

    参数：
    - script: 视频脚本
    - product_name: 产品名称
    - product_image_url: 产品图片 URL

    返回：
    - first_frames: 首帧图片列表（2张）
    - last_frames: 尾帧图片列表（2张）
    - success: 是否成功
    """
    try:
        # 调用工具生成图片
        result = generate_frame_images.invoke({
            "script": request.script,
            "product_name": request.product_name,
            "product_image_url": request.product_image_url
        })

        # 解析返回的 JSON
        result_dict = json.loads(result)

        return {
            "code": 0,
            "message": "图片生成成功",
            "data": result_dict
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"图片生成失败: {str(e)}")

@app.post("/api/v1/generate-video")
async def generate_video(request: VideoRequest):
    """
    生成 20 秒广告视频

    参数：
    - script: 视频脚本
    - product_name: 产品名称
    - product_image_url: 产品图片 URL
    - selected_first_frame: 用户选择的首帧图片 URL
    - selected_last_frame: 用户选择的尾帧图片 URL

    返回：
    - video_url: 生成的视频 URL
    - first_part: 第一段视频 URL
    - second_part: 第二段视频 URL
    - status: 状态
    """
    try:
        # 调用工具生成视频
        result = generate_miniprogram_video.invoke({
            "script": request.script,
            "product_name": request.product_name,
            "product_image_url": request.product_image_url,
            "selected_first_frame": request.selected_first_frame,
            "selected_last_frame": request.selected_last_frame
        })

        # 解析返回的 JSON
        result_dict = json.loads(result)

        return {
            "code": 0,
            "message": "视频生成成功",
            "data": result_dict
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"视频生成失败: {str(e)}")

@app.post("/api/v1/upload-image")
async def upload_image(file: UploadFile = File(...)):
    """
    上传产品图片

    参数：
    - file: 图片文件

    返回：
    - image_url: 上传后的图片 URL
    """
    try:
        # 使用对象存储上传图片
        from coze_coding_dev_sdk.s3 import S3SyncStorage

        storage = S3SyncStorage(
            endpoint_url=os.getenv("COZE_BUCKET_ENDPOINT_URL"),
            access_key="",
            secret_key="",
            bucket_name=os.getenv("COZE_BUCKET_NAME"),
            region="cn-beijing",
        )

        # 读取文件内容
        content = await file.read()

        # 上传到对象存储
        file_name = f"miniprogram_images/{file.filename}"
        key = storage.upload_file(
            file_content=content,
            file_name=file_name,
            content_type=file.content_type
        )

        # 生成签名 URL
        image_url = storage.generate_presigned_url(key=key, expire_time=3600 * 24 * 7)  # 7天有效期

        return {
            "code": 0,
            "message": "图片上传成功",
            "data": {
                "image_url": image_url,
                "file_key": key
            }
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"图片上传失败: {str(e)}")

# ==================== 启动服务 ====================

if __name__ == "__main__":
    print("🚀 启动 FastAPI 服务...")
    print("📡 服务地址: http://0.0.0.0:8000")
    print("📚 API 文档: http://0.0.0.0:8000/docs")
    uvicorn.run(app, host="0.0.0.0", port=8000)
