"""
视频拼接工具
使用 moviepy 将两段视频拼接成一段完整视频
"""
import os
import json
import tempfile
import requests
from pathlib import Path
from typing import List, Optional, Callable
from datetime import datetime
import uuid

try:
    import moviepy
    VideoFileClip = moviepy.VideoFileClip
    concatenate_videoclips = moviepy.concatenate_videoclips
except ImportError as e:
    print(f"警告: moviepy 未正确安装，视频拼接功能将不可用: {e}")
    VideoFileClip = None
    concatenate_videoclips = None

# 导入对象存储上传工具
try:
    from tools.storage_upload_tool import upload_and_get_url
except ImportError as e:
    print(f"警告: 无法导入对象存储上传工具: {e}")
    upload_and_get_url = None

def download_video(video_url: str, download_dir: str) -> str:
    """
    从URL下载视频到本地

    Args:
        video_url: 视频URL
        download_dir: 下载目录

    Returns:
        下载的本地文件路径
    """
    try:
        # 发送请求下载视频
        response = requests.get(video_url, stream=True, timeout=60)
        response.raise_for_status()

        # 从URL中提取文件名
        filename = video_url.split('/')[-1]
        if not filename.endswith('.mp4'):
            filename = f"{filename}.mp4"

        # 构建本地文件路径
        local_path = os.path.join(download_dir, filename)

        # 保存视频文件
        with open(local_path, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                if chunk:
                    f.write(chunk)

        return local_path
    except Exception as e:
        raise Exception(f"下载视频失败: {str(e)}")

def merge_videos(video_urls: List[str], output_dir: Optional[str] = None) -> str:
    """
    拼接多个视频成一段完整视频

    Args:
        video_urls: 视频URL列表
        output_dir: 输出目录，默认使用临时目录

    Returns:
        拼接后的视频URL
    """
    try:
        # 创建临时下载目录
        if output_dir is None:
            temp_dir = tempfile.mkdtemp()
        else:
            temp_dir = output_dir
            Path(temp_dir).mkdir(parents=True, exist_ok=True)

        download_dir = os.path.join(temp_dir, "downloads")
        Path(download_dir).mkdir(parents=True, exist_ok=True)

        # 下载所有视频
        video_clips = []
        for i, url in enumerate(video_urls):
            print(f"下载第 {i+1} 个视频: {url}")
            local_path = download_video(url, download_dir)
            clip = VideoFileClip(local_path)
            video_clips.append(clip)
            print(f"第 {i+1} 个视频时长: {clip.duration}秒")

            # 更新下载进度（70-80%）
            download_progress = 70 + int(((i + 1) / len(video_urls)) * 10)
            print(f"下载第 {i+1}/{len(video_urls)} 个视频...")

        # 拼接视频
        print("开始拼接视频...")
        final_clip = concatenate_videoclips(video_clips, method="compose")

        # 导出拼接后的视频
        output_filename = f"merged_video_{id(final_clip)}.mp4"
        output_path = os.path.join(temp_dir, output_filename)
        final_clip.write_videofile(output_path, codec='libx264', audio_codec='aac')

        print("视频导出完成")

        # 关闭所有视频剪辑
        final_clip.close()
        for clip in video_clips:
            clip.close()

        print(f"视频拼接完成: {output_path}")
        print(f"拼接后视频时长: {final_clip.duration}秒")

        return output_path

    except Exception as e:
        print(f"视频拼接失败: {str(e)}")
        raise Exception(f"视频拼接失败: {str(e)}")

def merge_videos_from_urls(video_urls: List[str], output_dir: Optional[str] = None, auto_upload: bool = True) -> str:
    """
    从URL列表拼接视频并返回结果

    Args:
        video_urls: 视频URL列表
        output_dir: 输出目录
        auto_upload: 是否自动上传到对象存储（默认True）

    Returns:
        JSON格式的拼接结果
    """
    try:
        merged_path = merge_videos(video_urls, output_dir)

        result = {
            "success": True,
            "merged_video_path": merged_path,
            "message": "视频拼接成功"
        }

        # 如果启用了自动上传且上传工具可用
        if auto_upload and upload_and_get_url:
            try:
                update_progress(95, "正在上传到对象存储...")
                print("开始上传拼接后的视频到对象存储...")
                # 生成唯一的文件名
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                unique_id = str(uuid.uuid4())[:8]
                file_name = f"tnho_promo_video_{timestamp}_{unique_id}.mp4"

                # 上传并获取签名URL
                signed_url = upload_and_get_url(merged_path, file_name)

                result["merged_video_url"] = signed_url
                result["video_key"] = f"videos/{file_name}"
                result["message"] = "视频拼接并上传成功"

                update_progress(100, "视频上传成功")
                print(f"视频上传成功: {signed_url}")

            except Exception as upload_error:
                # 上传失败，但拼接成功
                result["upload_error"] = str(upload_error)
                result["merged_video_url"] = ""
                result["message"] = f"视频拼接成功但上传失败: {upload_error}"
                print(f"视频上传失败: {upload_error}")
        else:
            # 不上传，只返回本地路径
            result["merged_video_url"] = ""
            if not auto_upload:
                result["message"] = "视频拼接成功（未启用自动上传）"
            else:
                result["message"] = "视频拼接成功（对象存储不可用）"

        return json.dumps(result, ensure_ascii=False, indent=2)

    except Exception as e:
        return json.dumps({
            "success": False,
            "error": str(e),
            "message": f"视频拼接失败: {str(e)}"
        }, ensure_ascii=False, indent=2)


if __name__ == "__main__":
    # 测试视频拼接
    test_urls = [
        "https://example.com/video1.mp4",
        "https://example.com/video2.mp4"
    ]
    result = merge_videos_from_urls(test_urls)
    print(result)
