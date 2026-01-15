"""
FastAPI 后端服务 - 微信小程序视频生成 API
提供 RESTful API 供微信小程序调用
"""
from fastapi import FastAPI, HTTPException, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
from typing import Optional
import uvicorn
import json
import os
import logging
from dotenv import load_dotenv

# 加载环境变量
load_dotenv()

# 配置日志
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# 导入小程序 Agent
from agents.miniprogram_video_agent import build_agent
from tools.miniprogram_video_tool import (
    generate_ad_script,
    generate_frame_images,
    generate_miniprogram_video
)

# 导入企业微信路由
from api.wechat_callback_simple import router as wechat_callback_router
from api.enterprise_wechat import router as enterprise_wechat_router

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

# 挂载静态文件目录 - 用于访问上传的图片
assets_dir = os.path.join(os.path.dirname(__file__), '..', 'assets')
if not os.path.exists(assets_dir):
    os.makedirs(assets_dir, exist_ok=True)
app.mount("/assets", StaticFiles(directory=assets_dir), name="assets")

# 注册企业微信路由
app.include_router(wechat_callback_router)
app.include_router(enterprise_wechat_router)

# 全局异常处理器
@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    logger.error(f"全局异常: {str(exc)}")
    logger.error(f"请求路径: {request.url}")
    import traceback
    logger.error(f"错误堆栈:\n{traceback.format_exc()}")
    raise HTTPException(status_code=500, detail=str(exc))

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
    logger.info("========== 上传图片函数被调用 ==========")
    try:
        logger.info(f"文件名: {file.filename}, 文件类型: {file.content_type}")

        # 读取文件内容
        content = await file.read()
        logger.info(f"文件大小: {len(content)} bytes")

        file_extension = file.filename.split('.')[-1] if file.filename and '.' in file.filename else 'jpg'
        logger.info(f"文件扩展名: {file_extension}")

        # 生成唯一文件名
        import uuid
        unique_filename = f"{uuid.uuid4().hex}.{file_extension}"
        logger.info(f"唯一文件名: {unique_filename}")

        # 保存到本地 assets 目录
        assets_dir = os.path.join(os.path.dirname(__file__), '..', 'assets', 'uploads')
        logger.info(f"目标目录: {assets_dir}")

        os.makedirs(assets_dir, exist_ok=True)
        file_path = os.path.join(assets_dir, unique_filename)
        logger.info(f"完整文件路径: {file_path}")

        with open(file_path, 'wb') as f:
            f.write(content)

        logger.info("文件保存成功")

        # 返回图片 URL（使用相对路径，让小程序根据当前apiBaseUrl拼接）
        image_url = f"/assets/uploads/{unique_filename}"

        return {
            "code": 0,
            "message": "图片上传成功",
            "data": {
                "image_url": image_url,
                "file_key": unique_filename
            }
        }
    except Exception as e:
        import traceback
        logger.error(f"错误: {str(e)}")
        logger.error(f"错误堆栈:\n{traceback.format_exc()}")
        raise HTTPException(status_code=500, detail=f"图片上传失败: {str(e)}")

# ==================== 启动服务 ====================

if __name__ == "__main__":
    print("🚀 启动 FastAPI 服务...")
    print("📡 服务地址: http://0.0.0.0:8000")
    print("📚 API 文档: http://0.0.0.0:8000/docs")
    uvicorn.run(app, host="0.0.0.0", port=8000)
