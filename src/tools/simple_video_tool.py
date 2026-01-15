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

    这是简洁版视频生成工具，流程如下：
    1. 接收用户提供的视频脚本
    2. 根据脚本生成20秒的宣传视频
    3. 支持上传首帧图片（视频开头）和尾帧图片（视频结尾）
    4. 自动融入红色TNHO商标元素

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

    headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer " + API_KEY
    }

    # 构建提示词（简化版，去掉复杂的分段逻辑）
    base_prompt = f"""根据以下脚本生成20秒的紧固件宣传视频：

脚本内容：
{script}

产品名称：{product_name}
时长：20秒
视频风格：专业工业摄影，光影效果突出产品细节，16:9宽屏

重要要求：
1. 视频中必须融入醒目的红色TNHO商标元素
2. 商标拼写为：T-N-H-O（天虹）
3. 注意商标是TNHO不是TOHO，务必使用正确拼写T-N-H-O
4. 在关键位置显示红色TNHO四个英文字母，字体清晰醒目
5. 体现天虹品牌形象和专业品质

--duration 20 --camerafixed false --watermark true"""

    # 构建内容列表
    content_items = [
        {
            "type": "text",
            "text": base_prompt
        }
    ]

    # 添加首帧图片（如果提供）
    if first_frame_image:
        content_items.append({
            "type": "image_url",
            "image_url": {
                "url": first_frame_image
            }
        })

    # 添加尾帧图片（如果提供）
    if last_frame_image:
        content_items.append({
            "type": "image_url",
            "image_url": {
                "url": last_frame_image
            }
        })

    # 构建请求
    request = {
        "model": MODEL_NAME,
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
                        "model": MODEL_NAME,
                        "duration": status_data.get('duration'),
                        "resolution": status_data.get('resolution'),
                        "ratio": status_data.get('ratio')
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
    # 简洁的脚本模板
    script = f"""📝 视频脚本（20秒）

**主题**：{theme}

**场景1**（0-5秒）：
- 画面：{product_name}产品特写，展现精细工艺
- 旁白：天虹紧固件，30年专业制造经验

**场景2**（5-12秒）：
- 画面：产品在工业应用中的展示，红色TNHO商标醒目显示
- 旁白：专注高难度、特殊紧固件，品质可靠

**场景3**（12-20秒）：
- 画面：现代化工厂全景，品牌形象展示
- 旁白：浙江天虹紧固件，您值得信赖的合作伙伴

💡 商标提醒：所有场景中融入红色TNHO商标（T-N-H-O）"""

    return json.dumps({
        "success": True,
        "script": script,
        "theme": theme,
        "product_name": product_name,
        "duration": 20
    }, ensure_ascii=False, indent=2)
