from langchain.tools import tool, ToolRuntime
import requests
import time
import json
import os
import tempfile
from pathlib import Path
from typing import List, Optional
try:
    from .video_merge_tool import merge_videos_from_urls
except ImportError:
    from tools.video_merge_tool import merge_videos_from_urls


@tool
def generate_fastener_promo_video(
    product_name: str,
    theme: str = "品质保证",
    duration: int = 20,
    scenario: str = "",
    product_image_url: str = "",
    runtime: ToolRuntime = None
) -> str:
    """
    Generate a promotional video specifically for fastener products using Doubao Seedance model.

    This tool creates a tailored promotional video for fastener products
    by combining product name, theme, and optional image reference.
    The video will incorporate TNHO trademark (red color) throughout.

    IMPORTANT: The trademark is TNHO (天虹), NOT TOHO. Always ensure correct spelling.

    NEW FEATURE: Image-to-Video support using doubao-seedance-1-5-pro-251215 model.
    If you provide a product image URL, the model will use it as a reference to generate
    a more accurate and realistic video that matches the product's appearance.

    NOTE: Due to model limitations (max 12 seconds per video), if the requested duration
    is over 12 seconds, two videos will be generated and merged automatically.

    Args:
        product_name: Name of fastener product (e.g., "高强度螺栓", "不锈钢螺丝")
        theme: Theme of promotional video (e.g., "品质保证", "技术创新", "工业应用", "品牌形象")
        duration: Video duration in seconds (default: 20, recommended range: 5-30)
        scenario: Usage scenario description (e.g., "用于汽车制造中的高强度连接场景")
        product_image_url: URL of product image for reference (optional, recommended for better results)

    Returns:
        JSON string containing video URL and generation details
    """
    # 根据主题生成不同的视频描述
    # 注意：商标是 TNHO（天虹），不是 TOHO

    # 构建场景描述（如果提供）
    scenario_text = f"，使用场景：{scenario}" if scenario else ""

    theme_prompts = {
        "品质保证": f"高品质{product_name}在工业应用中的可靠性能展示{scenario_text}。特写镜头展现精密的制造工艺和严格的质检流程，产品在机械结构中的稳固连接，强调强度、耐用性和零缺陷的质量标准。专业工业摄影，光影效果突出产品细节，16:9宽屏。视频中必须融入醒目的红色TNHO商标元素，商标拼写为：T-N-H-O（天虹）。在关键位置（如产品特写、品牌展示时）显示红色TNHO四个英文字母，字体清晰醒目，注意商标是TNHO不是TOHO，务必使用正确拼写T-N-H-O，体现天虹品牌形象。",

        "技术创新": f"创新技术驱动的{product_name}制造过程{scenario_text}。展现先进的自动化生产线、精密加工设备和智能化质量控制系统。产品在极端环境下的性能测试场景，突显技术创新带来的卓越性能。科技感十足的视觉风格，动态运镜，展现产品的高科技属性。视频中必须巧妙融入红色TNHO商标，商标拼写为：T-N-H-O（天虹）。在科技感场景中以动态方式出现，强化品牌科技感。注意商标是TNHO不是TOHO，必须使用正确拼写T-N-H-O。",

        "工业应用": f"{product_name}在各类工业领域的广泛应用{scenario_text}。场景包括汽车制造、航空航天、桥梁建设、机械设备等。展现产品在不同应用场景下的关键作用和可靠性。全景和特写交替使用，体现产品的多场景适应性和工业价值。专业纪录片风格。视频中必须在关键场景融入红色TNHO商标，商标拼写为：T-N-H-O（天虹）。展现品牌在工业领域的专业地位。注意商标是TNHO不是TOHO，务必使用正确拼写T-N-H-O。",

        "品牌形象": f"{product_name}品牌形象宣传片{scenario_text}。展现企业的现代化工厂、研发实力、严格的质量管理体系和国际认证标准。强调品牌的行业领导地位和客户信任。高端大气的视觉效果，企业品牌展示风格。红色TNHO商标应在视频中显著展示，商标拼写为：T-N-H-O（天虹），作为品牌识别的核心元素，强化品牌识别度。注意商标是TNHO不是TOHO，必须使用正确拼写T-N-H-O。"
    }

    # 获取对应主题的提示词
    base_prompt = theme_prompts.get(theme, theme_prompts["品质保证"])

    # 计算视频分段策略
    # 模型最大支持12秒，根据请求时长计算分段
    MAX_DURATION_PER_VIDEO = 12

    def calculate_video_segments(requested_duration: int, max_per_segment: int = 12) -> List:
        """
        计算视频分段时长

        Args:
            requested_duration: 请求的总时长
            max_per_segment: 每段最大时长（默认12秒）

        Returns:
            分段时长列表
        """
        segments = []

        if requested_duration <= max_per_segment:
            # 单段视频
            segments = [requested_duration]
        elif requested_duration == 15:
            # 15秒：8秒 + 7秒
            segments = [8, 7]
        elif requested_duration == 20:
            # 20秒：10秒 + 10秒
            segments = [10, 10]
        elif requested_duration == 25:
            # 25秒：8秒 + 8秒 + 9秒
            segments = [8, 8, 9]
        elif requested_duration == 30:
            # 30秒：10秒 + 10秒 + 10秒
            segments = [10, 10, 10]
        else:
            # 其他时长：动态计算
            if requested_duration <= 20:
                half = requested_duration // 2
                if requested_duration % 2 == 1:
                    segments = [half + 1, half]  # 奇数秒：8+7
                else:
                    segments = [half, half]
            else:
                third = requested_duration // 3
                remainder = requested_duration % 3
                if remainder == 0:
                    segments = [third, third, third]
                elif remainder == 1:
                    segments = [third + 1, third, third]
                else:  # remainder == 2
                    segments = [third + 1, third + 1, third]

        # 确保每段不超过最大时长
        segments = [min(s, max_per_segment) for s in segments]

        return segments

    # 计算分段
    segments = calculate_video_segments(duration, MAX_DURATION_PER_VIDEO)

    # 如果需要多段视频
    if len(segments) > 1:


        # 为每段视频生成不同的提示词
        video_parts = []
        for i, segment_duration in enumerate(segments):
            part_num = i + 1
            total_parts = len(segments)

            # 计算当前进度：生成阶段占 70%
            base_progress = int((i / total_parts) * 70)


            if part_num == 1:
                # 第一段：产品特写和工艺展示
                part_prompt = f"{base_prompt} 第{part_num}部分：{product_name}的特写展示，展现产品的精细工艺和质量特点。镜头聚焦产品细节，特写螺纹、材质质感，红色TNHO商标在产品特写时以醒目方式出现。时长{segment_duration}秒。"
            elif part_num == total_parts:
                # 最后一段：品牌展示和总结
                part_prompt = f"{base_prompt} 第{part_num}部分：{product_name}品牌形象总结，展现企业在行业中的领先地位和客户信任。红色TNHO商标以醒目方式展示，强化品牌识别度。时长{segment_duration}秒。"
            else:
                # 中间段：应用场景展示
                part_prompt = f"{base_prompt} 第{part_num}部分：{product_name}在应用场景中的展示，展现产品的实际使用效果和可靠性。镜头展示产品在机械结构中的连接作用，红色TNHO商标以动态方式强化品牌印象。时长{segment_duration}秒。"

            # 生成视频
            print(f"开始生成第{part_num}段视频（{segment_duration}秒）...")
            result = generate_promo_video_internal(
                prompt=part_prompt,
                duration=segment_duration,
                logo_url=product_image_url,
                return_last_frame=False
            )
            result_data = json.loads(result)

            if not result_data.get("success"):

                return json.dumps({
                    "error": f"第{part_num}段视频生成失败",
                    "status": "failed",
                    "details": result_data
                }, ensure_ascii=False, indent=2)

            video_url = result_data.get("video_url")
            video_parts.append({
                "part": part_num,
                "duration": segment_duration,
                "video_url": video_url,
                "task_id": result_data.get("task_id")
            })
            print(f"第{part_num}段视频生成成功: {video_url}")

            # 更新已完成的段数进度
            completed_progress = int(((part_num) / total_parts) * 70)


        # 收集所有视频URL
        video_urls = [part["video_url"] for part in video_parts]

        # 拼接视频
        print(f"开始拼接 {len(video_urls)} 段视频...")

        try:
            merge_result = merge_videos_from_urls(video_urls)
            merge_data = json.loads(merge_result)

            if merge_data.get("success"):
                # 拼接成功
                merged_video_url = merge_data.get("merged_video_url", "")
                merged_video_path = merge_data.get("merged_video_path", "")

                # 如果成功上传，返回合并后的视频URL
                if merged_video_url:
                    main_video_url = merged_video_url
                    message = f"已生成 {len(video_parts)} 段视频并拼接，总时长约 {sum(segments)} 秒，已上传到对象存储。"

                else:
                    # 上传失败，返回第一段视频URL
                    main_video_url = video_parts[0]["video_url"]
                    message = f"已生成 {len(video_parts)} 段视频并拼接，总时长约 {sum(segments)} 秒。注意：拼接后的视频未成功上传到对象存储，当前返回第一段视频。"


                return json.dumps({
                    "success": True,
                    "video_url": main_video_url,
                    "video_urls": video_urls,
                    "merged_video_path": merged_video_path,
                    "merged_video_url": merged_video_url,
                    "status": "succeeded",
                    "message": message,
                    "model": "doubao-seedance-1-5-pro-251215 (多段拼接)",
                    "duration": sum(segments),
                    "parts": video_parts
                }, ensure_ascii=False, indent=2)
            else:
                # 拼接失败，返回第一段视频

                return json.dumps({
                    "success": True,
                    "video_url": video_parts[0]["video_url"],
                    "video_urls": video_urls,
                    "status": "partial_success",
                    "message": f"已生成 {len(video_parts)} 段视频但拼接失败。当前返回第一段视频（{video_parts[0]['duration']}秒）。",
                    "error": merge_data.get("error"),
                    "model": "doubao-seedance-1-5-pro-251215 (多段未拼接)",
                    "duration": video_parts[0]['duration']
                }, ensure_ascii=False, indent=2)

        except Exception as e:
            # 拼接过程出错，返回第一段视频

            return json.dumps({
                "success": True,
                "video_url": video_parts[0]["video_url"],
                "video_urls": video_urls,
                "status": "partial_success",
                "message": f"已生成 {len(video_parts)} 段视频但拼接过程中出现错误。当前返回第一段视频（{video_parts[0]['duration']}秒）。",
                "error": str(e),
                "model": "doubao-seedance-1-5-pro-251215 (多段未拼接)",
                "duration": video_parts[0]['duration']
            }, ensure_ascii=False, indent=2)
    else:
        # 单段视频，直接生成
        result = generate_promo_video_internal(
            prompt=base_prompt,
            duration=duration,
            logo_url=product_image_url,
            return_last_frame=False
        )
        result_data = json.loads(result)

        if result_data.get("success"):
            pass
        else:
            pass

        return result


def generate_promo_video_internal(prompt: str, duration: int = 20, logo_url: str = None, return_last_frame: bool = False) -> str:
    """Internal function to generate video using HTTP API"""
    MODEL_NAME = "doubao-seedance-1-5-pro-251215"

    # 获取 API Key（使用视频生成的专用 API Key）
    api_key = os.getenv("ARK_VIDEO_API_KEY") or "39bf20d0-55b5-4957-baa1-02f4529a3076"

    headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer " + api_key
    }

    # 构建提示词，将 duration 等参数集成到文本中
    # 新API格式：--duration 5 --camerafixed false --watermark true
    full_prompt = f"{prompt}  --duration {duration} --camerafixed false --watermark true"

    # 构建内容列表
    content_items = [
        {
            "type": "text",
            "text": full_prompt
        }
    ]

    # 如果提供了图片 URL，添加到内容项中（图生视频功能）
    if logo_url:
        content_items.append({
            "type": "image_url",
            "image_url": {
                "url": logo_url
            }
        })

    # 构建请求参数（使用新的图生视频API接口）
    # 新API不再需要独立的 duration 和 return_last_frame 参数
    # 这些参数已经集成到文本提示词中
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

        # 获取任务 ID
        task_id = result.get("id")
        if not task_id:
            return json.dumps({
                "error": "视频生成任务创建失败，未返回任务ID",
                "status": "failed",
                "response": result
            }, ensure_ascii=False, indent=2)

        # 轮询任务状态
        max_wait_time = 300  # 最多等待5分钟
        start_time = time.time()
        last_progress_update = 0

        while time.time() - start_time < max_wait_time:
            try:
                # 查询任务状态
                status_response = requests.get(
                    f'https://ark.cn-beijing.volces.com/api/v3/contents/generations/tasks/{task_id}',
                    headers=headers,
                    timeout=30
                )
                status_response.raise_for_status()

                status_data = status_response.json()

                # 检查错误信息
                if status_data.get('error'):
                    return json.dumps({
                        "error": f"视频生成失败: {status_data.get('error', {}).get('message')}",
                        "status": "failed",
                        "task_id": task_id,
                        "response": status_data
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
                    # 视频生成中，等待2秒后轮询状态
                    # 每隔一段时间更新进度（模拟进度）
                    elapsed = time.time() - start_time
                    simulated_progress = int(min((elapsed / 60) * 50, 50))  # 模拟0-50%的进度

                    if simulated_progress > last_progress_update:
                        last_progress_update = simulated_progress
                        if status == 'queued':
                            pass
                        else:
                            pass

                    time.sleep(2)
                    continue
                elif status == 'succeeded':
                    # 视频生成成功，提取URL
                    video_url = status_data.get('content', {}).get('video_url')
                    last_frame_url = status_data.get('content', {}).get('last_frame_url', '') if return_last_frame else ''

                    return json.dumps({
                        "success": True,
                        "video_url": video_url,
                        "last_frame_url": last_frame_url,
                        "status": "succeeded",
                        "task_id": task_id,
                        "model": MODEL_NAME,
                        "duration": status_data.get('duration'),
                        "resolution": status_data.get('resolution'),
                        "ratio": status_data.get('ratio'),
                        "usage": status_data.get('usage', {}),
                        "full_response": status_data
                    }, ensure_ascii=False, indent=2)
                else:
                    return json.dumps({
                        "error": f"视频生成状态未知: {status}",
                        "status": "unknown",
                        "task_id": task_id,
                        "response": status_data
                    }, ensure_ascii=False, indent=2)

            except requests.exceptions.RequestException as e:
                # 网络错误，重试
                time.sleep(2)
                continue
            except Exception as e:
                return json.dumps({
                    "error": f"视频生成状态轮询失败: {str(e)}",
                    "status": "failed",
                    "task_id": task_id,
                    "exception_type": type(e).__name__
                }, ensure_ascii=False, indent=2)

        # 超时
        return json.dumps({
            "error": "视频生成超时",
            "status": "timeout",
            "task_id": task_id,
            "wait_time": max_wait_time
        }, ensure_ascii=False, indent=2)

    except requests.exceptions.HTTPError as e:
        return json.dumps({
            "error": f"HTTP错误: {e.response.status_code} - {e.response.text}",
            "status": "failed",
            "exception_type": "HTTPError"
        }, ensure_ascii=False)
    except Exception as e:
        return json.dumps({
            "error": f"视频生成失败: {str(e)}",
            "status": "failed",
            "exception_type": type(e).__name__
        }, ensure_ascii=False)


@tool
def check_task_status(task_id: str, runtime: ToolRuntime = None) -> str:
    """
    Check status of a video generation task.

    This tool allows you to query current status of a previously
    created video generation task without waiting for completion.

    Args:
        task_id: The ID of video generation task to check

    Returns:
        JSON string containing current task status
    """
    # 注意：由于现在使用同步生成接口，这个工具保留用于兼容性
    # 但实际上不会返回有意义的状态

    return json.dumps({
        "status": "not_applicable",
        "message": "视频生成使用同步接口，不返回任务ID。请直接查看视频生成工具的响应。",
        "task_id": task_id
    }, ensure_ascii=False)
