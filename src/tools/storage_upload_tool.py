"""
对象存储上传工具
使用 S3SyncStorage 上传文件到对象存储
"""
import os
from coze_coding_dev_sdk.s3 import S3SyncStorage

def get_storage():
    """
    获取对象存储客户端实例

    Returns:
        S3SyncStorage 实例
    """
    return S3SyncStorage(
        endpoint_url=os.getenv("COZE_BUCKET_ENDPOINT_URL"),
        access_key="",
        secret_key="",
        bucket_name=os.getenv("COZE_BUCKET_NAME"),
        region="cn-beijing",
    )

def upload_video_file(file_path: str, file_name: str = None) -> str:
    """
    上传视频文件到对象存储

    Args:
        file_path: 本地视频文件路径
        file_name: 上传后的文件名（可选，默认使用原文件名）

    Returns:
        对象存储的 key（文件路径）

    Raises:
        Exception: 上传失败时抛出异常
    """
    try:
        storage = get_storage()

        # 如果没有指定文件名，从路径中提取
        if file_name is None:
            file_name = os.path.basename(file_path)

        # 使用流式上传（适用于大文件）
        with open(file_path, 'rb') as f:
            key = storage.stream_upload_file(
                fileobj=f,
                file_name=file_name,
                content_type="video/mp4",
                multipart_chunksize=5 * 1024 * 1024,  # 5MB 分片
                multipart_threshold=5 * 1024 * 1024,   # 5MB 触发分片
                use_threads=False
            )

        print(f"视频上传成功，key: {key}")
        return key

    except Exception as e:
        print(f"视频上传失败: {str(e)}")
        raise Exception(f"视频上传失败: {str(e)}")

def generate_presigned_url(file_key: str, expire_time: int = 1800) -> str:
    """
    生成视频文件的签名访问URL

    Args:
        file_key: 对象存储中的文件key
        expire_time: URL过期时间（秒），默认30分钟

    Returns:
        签名URL字符串

    Raises:
        Exception: 生成失败时抛出异常
    """
    try:
        storage = get_storage()

        signed_url = storage.generate_presigned_url(
            key=file_key,
            expire_time=expire_time
        )

        print(f"签名URL生成成功: {signed_url}")
        return signed_url

    except Exception as e:
        print(f"签名URL生成失败: {str(e)}")
        raise Exception(f"签名URL生成失败: {str(e)}")

def upload_and_get_url(file_path: str, file_name: str = None, expire_time: int = 1800) -> str:
    """
    上传视频文件并返回签名URL

    Args:
        file_path: 本地视频文件路径
        file_name: 上传后的文件名（可选）
        expire_time: URL过期时间（秒）

    Returns:
        签名URL字符串

    Raises:
        Exception: 上传或生成URL失败时抛出异常
    """
    try:
        # 上传文件
        file_key = upload_video_file(file_path, file_name)

        # 生成签名URL
        signed_url = generate_presigned_url(file_key, expire_time)

        return signed_url

    except Exception as e:
        raise Exception(f"上传并获取URL失败: {str(e)}")
