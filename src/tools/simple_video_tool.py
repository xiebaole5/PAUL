"""
简洁版视频生成工具
支持：根据脚本生成20秒视频 + 首尾帧图片上传
"""
from langchain.tools import tool, ToolRuntime
import requests
import time
import json
import os
from typing import Optional

try:
    from .video_merge_tool import merge_videos_from_urls
except ImportError:
    from tools.video_merge_tool import merge_videos_from_urls


@tool
def generate_video_with_script(
    script: str,
    product_name: str = "紧固件",
    first_frame_image: str = "",
    last_frame_image: str = "",
    runtime: ToolRuntime = None
) -> str:
    """
    根据脚本生成20秒紧固件宣传视频，支持首尾帧图片上传。

    工作流程：
    1. 将20秒脚本分成两段：第一段10秒，第二段10秒
    2. 第一段视频使用首帧图片（如果提供）作为参考
    3. 第二段视频使用尾帧图片（如果提供）作为参考
    4. 自动拼接两段视频，确保逻辑连贯
    5. 上传到对象存储，返回可访问的URL

    Args:
        script: 视频脚本，包含场景描述和旁白（20秒时长）
        product_name: 产品名称（如"高强度螺栓"、"不锈钢螺丝"）
        first_frame_image: 首帧图片URL（视频开头使用的图片，可选）
        last_frame_image: 尾帧图片URL（视频结尾使用的图片，可选）

    Returns:
        JSON字符串，包含视频URL和生成结果
    """
    MODEL_NAME = "doubao-seedance-1-5-pro-251215"
    API_KEY = os.getenv("ARK_VIDEO_API_KEY") or "39bf20d0-55b5-4957-baa1-02f4529a3076"

    # 将20秒脚本分成两段
    # 第一段：0-10秒（开头部分）
    # 第二段：10-20秒（结尾部分）

    # 解析脚本，提取关键信息
    script_parts = split_script_into_two_parts(script)

    # 生成第一段视频（10秒，使用首帧图片）
    print("开始生成第一段视频（0-10秒）...")
    first_prompt = f"""{script_parts['first_part']}

重要要求：
1. 时长：10秒
2. 这是视频的开头部分，要吸引眼球
3. 视频中必须融入醒目的红色TNHO商标元素
4. 商标拼写为：T-N-H-O（天虹）
5. 注意商标是TNHO不是TOHO，务必使用正确拼写T-N-H-O
6. 体现天虹品牌形象和专业品质

--duration 10 --camerafixed false --watermark true"""

    first_video_result = generate_video_internal(
        prompt=first_prompt,
        image_url=first_frame_image,  # 首帧图片在第一段
        api_key=API_KEY,
        model=MODEL_NAME
    )
    first_video_data = json.loads(first_video_result)

    if not first_video_data.get("success"):
        return json.dumps({
            "error": "第一段视频生成失败",
            "status": "failed",
            "details": first_video_data
        }, ensure_ascii=False, indent=2)

    first_video_url = first_video_data.get("video_url")
    print(f"第一段视频生成成功: {first_video_url}")

    # 生成第二段视频（10秒，使用尾帧图片）
    print("开始生成第二段视频（10-20秒）...")
    second_prompt = f"""{script_parts['second_part']}

重要要求：
1. 时长：10秒
2. 这是视频的结尾部分，要总结和升华
3. 视频中必须融入醒目的红色TNHO商标元素
4. 商标拼写为：T-N-H-O（天虹）
5. 注意商标是TNHO不是TOHO，务必使用正确拼写T-N-H-O
6. 体现天虹品牌形象和专业品质

--duration 10 --camerafixed false --watermark true"""

    second_video_result = generate_video_internal(
        prompt=second_prompt,
        image_url=last_frame_image,  # 尾帧图片在第二段
        api_key=API_KEY,
        model=MODEL_NAME
    )
    second_video_data = json.loads(second_video_result)

    if not second_video_data.get("success"):
        return json.dumps({
            "error": "第二段视频生成失败",
            "status": "failed",
            "details": second_video_data
        }, ensure_ascii=False, indent=2)

    second_video_url = second_video_data.get("video_url")
    print(f"第二段视频生成成功: {second_video_url}")

    # 拼接两段视频
    print("开始拼接两段视频...")
    merge_result = merge_videos_from_urls([first_video_url, second_video_url])
    merge_data = json.loads(merge_result)

    if merge_data.get("success"):
        merged_url = merge_data.get("merged_video_url", "")
        if merged_url:
            return json.dumps({
                "success": True,
                "video_url": merged_url,
                "status": "succeeded",
                "message": "20秒视频生成成功（已拼接）",
                "duration": 20,
                "first_part": first_video_url,
                "second_part": second_video_url
            }, ensure_ascii=False, indent=2)
        else:
            # 拼接成功但上传失败，返回第一段视频
            return json.dumps({
                "success": True,
                "video_url": first_video_url,
                "status": "partial_success",
                "message": "两段视频生成成功，但拼接后上传失败，返回第一段视频",
                "first_part": first_video_url,
                "second_part": second_video_url
            }, ensure_ascii=False, indent=2)
    else:
        # 拼接失败，返回第一段视频
        return json.dumps({
            "success": True,
            "video_url": first_video_url,
            "status": "partial_success",
            "message": "两段视频生成成功，但拼接失败，返回第一段视频",
            "first_part": first_video_url,
            "second_part": second_video_url,
            "error": merge_data.get("error")
        }, ensure_ascii=False, indent=2)


def split_script_into_two_parts(script: str) -> dict:
    """
    将20秒脚本分成两段（每段10秒）

    Args:
        script: 完整的20秒脚本

    Returns:
        包含两段脚本的字典
    """
    # 简单处理：按行分割
    lines = script.split('\n')

    first_part_lines = []
    second_part_lines = []

    # 查找场景标记
    current_scene = 1

    for line in lines:
        # 检测场景标记
        if "场景1" in line or "0-5秒" in line or "0-10秒" in line:
            current_scene = 1
            first_part_lines.append(line)
        elif "场景2" in line or "5-12秒" in line or "10-20秒" in line:
            current_scene = 2
            second_part_lines.append(line)
        elif "场景3" in line or "12-20秒" in line:
            current_scene = 2
            second_part_lines.append(line)
        else:
            if current_scene == 1:
                first_part_lines.append(line)
            else:
                second_part_lines.append(line)

    # 如果没有明确的场景标记，简单按行数分割
    if not first_part_lines:
        mid = len(lines) // 2
        first_part_lines = lines[:mid]
        second_part_lines = lines[mid:]

    return {
        "first_part": '\n'.join(first_part_lines) if first_part_lines else script,
        "second_part": '\n'.join(second_part_lines) if second_part_lines else script
    }


def generate_video_internal(prompt: str, image_url: str = "", api_key: str = "", model: str = "") -> str:
    """
    内部视频生成函数

    Args:
        prompt: 提示词
        image_url: 图片URL（可选）
        api_key: API密钥
        model: 模型名称

    Returns:
        JSON字符串
    """
    headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer " + api_key
    }

    # 构建内容列表
    content_items = [
        {
            "type": "text",
            "text": prompt
        }
    ]

    # 如果提供了图片，添加到内容项中
    if image_url:
        content_items.append({
            "type": "image_url",
            "image_url": {
                "url": image_url
            }
        })

    # 构建请求
    request = {
        "model": model,
        "content": content_items
    }

    # 创建视频生成任务
    try:
        response = requests.post(
            'https://ark.cn-beijing.volces.com/api/v3/contents/generations/tasks',
            json=request,
            headers=headers,
            timeout=60
        )

        response.raise_for_status()
        result = response.json()

        # 获取任务ID
        task_id = result.get("id")
        if not task_id:
            return json.dumps({
                "error": "视频生成任务创建失败，未返回任务ID",
                "status": "failed",
                "response": result
            }, ensure_ascii=False, indent=2)

        # 轮询任务状态（最多等待5分钟）
        max_wait_time = 300
        start_time = time.time()

        while time.time() - start_time < max_wait_time:
            try:
                status_response = requests.get(
                    f'https://ark.cn-beijing.volces.com/api/v3/contents/generations/tasks/{task_id}',
                    headers=headers,
                    timeout=30
                )
                status_response.raise_for_status()
                status_data = status_response.json()

                # 检查错误
                if status_data.get('error'):
                    return json.dumps({
                        "error": f"视频生成失败: {status_data.get('error', {}).get('message')}",
                        "status": "failed",
                        "task_id": task_id
                    }, ensure_ascii=False, indent=2)

                status = status_data.get('status')

                if status == 'cancelled':
                    return json.dumps({
                        "error": "视频生成任务已取消",
                        "status": "cancelled",
                        "task_id": task_id
                    }, ensure_ascii=False, indent=2)
                elif status == 'failed':
                    return json.dumps({
                        "error": "视频生成失败",
                        "status": "failed",
                        "task_id": task_id,
                        "response": status_data
                    }, ensure_ascii=False, indent=2)
                elif status in ['queued', 'running']:
                    # 视频生成中，等待后继续轮询
                    time.sleep(2)
                    continue
                elif status == 'succeeded':
                    # 视频生成成功
                    video_url = status_data.get('content', {}).get('video_url')
                    return json.dumps({
                        "success": True,
                        "video_url": video_url,
                        "status": "succeeded",
                        "task_id": task_id,
                        "model": model
                    }, ensure_ascii=False, indent=2)
                else:
                    return json.dumps({
                        "error": f"视频生成状态未知: {status}",
                        "status": "unknown",
                        "task_id": task_id
                    }, ensure_ascii=False, indent=2)

            except requests.exceptions.RequestException as e:
                time.sleep(2)
                continue
            except Exception as e:
                return json.dumps({
                    "error": f"视频生成状态轮询失败: {str(e)}",
                    "status": "failed",
                    "task_id": task_id
                }, ensure_ascii=False, indent=2)

        # 超时
        return json.dumps({
            "error": "视频生成超时",
            "status": "timeout",
            "task_id": task_id
        }, ensure_ascii=False, indent=2)

    except requests.exceptions.HTTPError as e:
        return json.dumps({
            "error": f"HTTP错误: {e.response.status_code} - {e.response.text}",
            "status": "failed"
        }, ensure_ascii=False)
    except Exception as e:
        return json.dumps({
            "error": f"视频生成失败: {str(e)}",
            "status": "failed"
        }, ensure_ascii=False)


@tool
def generate_simple_script(
    theme: str,
    product_name: str = "紧固件",
    key_points: str = "",
    runtime: ToolRuntime = None
) -> str:
    """
    根据主题生成20秒的紧固件宣传视频脚本。

    这是简洁版脚本生成工具，根据用户提供的主题快速生成脚本。

    Args:
        theme: 主题描述（如"品质保证"、"技术创新"）
        product_name: 产品名称（如"高强度螺栓"）
        key_points: 关键点描述（可选，如"高强度、耐用、精密"）

    Returns:
        JSON字符串，包含生成的视频脚本
    """
    # 简洁的脚本模板（20秒，两段结构）
    script = f"""📝 视频脚本（20秒）

**主题**：{theme}

**第一段**（0-10秒）：
- 画面：{product_name}产品特写，展现精细工艺和品质
- 旁白：天虹紧固件，30年专业制造经验，品质值得信赖

**第二段**（10-20秒）：
- 画面：产品在工业应用中的展示，现代化工厂全景，红色TNHO商标醒目显示
- 旁白：专注高难度、特殊紧固件，浙江天虹紧固件，您值得信赖的合作伙伴

💡 商标提醒：所有场景中融入红色TNHO商标（T-N-H-O）"""

    return json.dumps({
        "success": True,
        "script": script,
        "theme": theme,
        "product_name": product_name,
        "duration": 20
    }, ensure_ascii=False, indent=2)
