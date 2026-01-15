"""
微信小程序专用视频生成工具
完整流程：脚本生成 → 首尾帧图片生成 → 视频生成
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
def generate_ad_script(
    product_name: str,
    product_image_url: str,
    usage_scenario: str,
    theme_direction: str,
    runtime: ToolRuntime = None
) -> str:
    """
    根据用户输入的必填信息生成20秒紧固件广告营销脚本。

    工作流程：
    1. 接收产品名称、产品图片、使用场景、主题方向
    2. AI分析图片内容和文本信息
    3. 生成20秒的广告营销脚本

    Args:
        product_name: 紧固件产品名称（必填，如"高强度螺栓"）
        product_image_url: 紧固件产品图片URL（必填）
        usage_scenario: 客户使用场景描述（必填，如"用于汽车底盘连接，承受高强度拉力"）
        theme_direction: 宣传主题方向（必填，如"品质保证"、"技术创新"、"工业应用"）

    Returns:
        JSON字符串，包含生成的20秒广告营销脚本
    """
    # 构建脚本
    script = f"""📝 20秒「{product_name}」广告营销脚本

【产品信息】
- 产品名称：{product_name}
- 客户使用场景：{usage_scenario}
- 宣传主题方向：{theme_direction}

【第一段】（0-10秒）：产品引入
- 画面：{product_name}产品特写，展现产品细节和品质感。根据产品图片展示{product_name}的核心特征（如螺纹精度、金属质感、表面处理等）。特写镜头聚焦产品在{usage_scenario}中的关键作用。
- 旁白：天虹紧固件，30年专业制造经验，品质值得信赖。
- 视觉元素：红色TNHO商标（T-N-H-O）在产品特写时以醒目方式出现。

【第二段】（10-20秒）：应用与信任
- 画面：{product_name}在{usage_scenario}中的实际应用场景，展现产品的可靠性和专业性。配合现代化工厂全景，展示天虹的智能制造能力。
- 旁白：专注高难度、特殊紧固件，{theme_direction}。浙江天虹紧固件，您值得信赖的合作伙伴。
- 视觉元素：红色TNHO商标（T-N-H-O）以醒目方式展示，强化品牌印象。

💡 商标提醒：所有场景中融入红色TNHO商标（T-N-H-O），注意拼写正确"""

    return json.dumps({
        "success": True,
        "script": script,
        "product_name": product_name,
        "usage_scenario": usage_scenario,
        "theme_direction": theme_direction,
        "duration": 20
    }, ensure_ascii=False, indent=2)


@tool
def generate_frame_images(
    script: str,
    product_name: str = "紧固件",
    product_image_url: str = "",
    runtime: ToolRuntime = None
) -> str:
    """
    根据脚本生成首尾帧图片（各2张供用户选择）。

    工作流程：
    1. 解析脚本内容
    2. 生成2张首帧图片（用于视频开头）
    3. 生成2张尾帧图片（用于视频结尾）

    Args:
        script: 视频脚本内容
        product_name: 产品名称
        product_image_url: 产品图片URL（作为参考）

    Returns:
        JSON字符串，包含首尾帧图片URL
    """
    # 使用生图集成
    from coze_coding_dev_sdk import ImageGenerationClient
    from coze_coding_utils.runtime_ctx.context import new_context

    ctx = new_context(method="generate")
    client = ImageGenerationClient(ctx=ctx)

    # 生成2张首帧图片（视频开头：产品特写）
    first_frame_prompt = f"""{product_name}产品特写，展现高品质紧固件的精细工艺。
风格：专业工业摄影，光影效果突出产品细节。
背景：简洁的工业环境，突出产品主体。
要求：融入红色TNHO商标元素，商标拼写为T-N-H-O。"""

    # 生成2张尾帧图片（视频结尾：品牌形象）
    last_frame_prompt = f"""天虹紧固件品牌形象展示，现代化工厂全景。
风格：高端大气，展现企业实力和品牌形象。
背景：现代化工厂，智能制造场景。
要求：红色TNHO商标醒目显示，强化品牌识别，商标拼写为T-N-H-O。"""

    first_frame_urls = []
    last_frame_urls = []

    # 生成2张首帧图片
    for i in range(2):
        try:
            response = client.generate(
                prompt=first_frame_prompt,
                size="2K",
                watermark=False
            )
            if response.success and response.image_urls:
                first_frame_urls.append(response.image_urls[0])
                print(f"首帧图片{i+1}生成成功")
        except Exception as e:
            print(f"首帧图片{i+1}生成失败: {e}")

    # 生成2张尾帧图片
    for i in range(2):
        try:
            response = client.generate(
                prompt=last_frame_prompt,
                size="2K",
                watermark=False
            )
            if response.success and response.image_urls:
                last_frame_urls.append(response.image_urls[0])
                print(f"尾帧图片{i+1}生成成功")
        except Exception as e:
            print(f"尾帧图片{i+1}生成失败: {e}")

    return json.dumps({
        "success": True,
        "first_frames": first_frame_urls,  # 2张首帧图片
        "last_frames": last_frame_urls,    # 2张尾帧图片
        "product_name": product_name,
        "message": f"生成首帧图片{len(first_frame_urls)}张，尾帧图片{len(last_frame_urls)}张"
    }, ensure_ascii=False, indent=2)


@tool
def generate_miniprogram_video(
    script: str,
    product_name: str,
    product_image_url: str,
    selected_first_frame: str,
    selected_last_frame: str,
    runtime: ToolRuntime = None
) -> str:
    """
    根据脚本、产品图片、首尾帧图片生成20秒广告视频。

    工作流程：
    1. 将20秒脚本分成两段（各10秒）
    2. 第一段使用产品图片+首帧图片生成
    3. 第二段使用尾帧图片生成
    4. 自动拼接两段视频
    5. 上传到对象存储，返回URL

    Args:
        script: 20秒视频脚本
        product_name: 产品名称
        product_image_url: 产品图片URL
        selected_first_frame: 用户选择的首帧图片URL
        selected_last_frame: 用户选择的尾帧图片URL

    Returns:
        JSON字符串，包含生成的视频URL
    """
    MODEL_NAME = "doubao-seedance-1-5-pro-251215"
    API_KEY = os.getenv("ARK_VIDEO_API_KEY") or "39bf20d0-55b5-4957-baa1-02f4529a3076"

    # 解析脚本，分成两段
    script_parts = split_script(script)

    # 生成第一段视频（0-10秒）：使用产品图片和首帧图片
    print("生成第一段视频（0-10秒）...")
    first_prompt = f"""{script_parts['first_part']}

重要要求：
1. 时长：10秒
2. 这是视频的开头部分，要吸引眼球
3. 展现{product_name}的产品特写和品质
4. 视频中必须融入醒目的红色TNHO商标元素
5. 商标拼写为：T-N-H-O（天虹）
6. 注意商标是TNHO不是TOHO，务必使用正确拼写T-N-H-O

--duration 10 --camerafixed false --watermark true"""

    first_video_result = generate_video_internal(
        prompt=first_prompt,
        image_url=product_image_url,  # 使用产品图片
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
    print(f"第一段视频生成成功")

    # 生成第二段视频（10-20秒）：使用尾帧图片
    print("生成第二段视频（10-20秒）...")
    second_prompt = f"""{script_parts['second_part']}

重要要求：
1. 时长：10秒
2. 这是视频的结尾部分，要总结和升华
3. 展现{product_name}在应用场景中的可靠性和品牌形象
4. 视频中必须融入醒目的红色TNHO商标元素
5. 商标拼写为：T-N-H-O（天虹）
6. 注意商标是TNHO不是TOHO，务必使用正确拼写T-N-H-O

--duration 10 --camerafixed false --watermark true"""

    second_video_result = generate_video_internal(
        prompt=second_prompt,
        image_url=selected_last_frame,  # 使用尾帧图片
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
    print(f"第二段视频生成成功")

    # 拼接两段视频
    print("拼接两段视频...")
    merge_result = merge_videos_from_urls([first_video_url, second_video_url])
    merge_data = json.loads(merge_result)

    if merge_data.get("success"):
        merged_url = merge_data.get("merged_video_url", "")
        if merged_url:
            return json.dumps({
                "success": True,
                "video_url": merged_url,
                "status": "succeeded",
                "message": "20秒广告视频生成成功",
                "duration": 20,
                "first_part": first_video_url,
                "second_part": second_video_url,
                "selected_first_frame": selected_first_frame,
                "selected_last_frame": selected_last_frame
            }, ensure_ascii=False, indent=2)
        else:
            # 拼接成功但上传失败，返回第一段视频
            return json.dumps({
                "success": True,
                "video_url": first_video_url,
                "status": "partial_success",
                "message": "两段视频生成成功，但上传失败，返回第一段视频",
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


def split_script(script: str) -> dict:
    """将20秒脚本分成两段"""
    lines = script.split('\n')

    first_part_lines = []
    second_part_lines = []

    current_scene = 1

    for line in lines:
        if "第一段" in line or "0-10秒" in line:
            current_scene = 1
            first_part_lines.append(line)
        elif "第二段" in line or "10-20秒" in line:
            current_scene = 2
            second_part_lines.append(line)
        else:
            if current_scene == 1:
                first_part_lines.append(line)
            else:
                second_part_lines.append(line)

    # 如果没有明确标记，简单分割
    if not first_part_lines:
        mid = len(lines) // 2
        first_part_lines = lines[:mid]
        second_part_lines = lines[mid:]

    return {
        "first_part": '\n'.join(first_part_lines) if first_part_lines else script,
        "second_part": '\n'.join(second_part_lines) if second_part_lines else script
    }


def generate_video_internal(prompt: str, image_url: str = "", api_key: str = "", model: str = "") -> str:
    """内部视频生成函数"""
    headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer " + api_key
    }

    content_items = [
        {"type": "text", "text": prompt}
    ]

    if image_url:
        content_items.append({
            "type": "image_url",
            "image_url": {"url": image_url}
        })

    request = {"model": model, "content": content_items}

    try:
        response = requests.post(
            'https://ark.cn-beijing.volces.com/api/v3/contents/generations/tasks',
            json=request,
            headers=headers,
            timeout=60
        )

        response.raise_for_status()
        result = response.json()

        task_id = result.get("id")
        if not task_id:
            return json.dumps({
                "error": "任务创建失败",
                "status": "failed"
            }, ensure_ascii=False)

        # 轮询状态
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

                if status_data.get('error'):
                    return json.dumps({
                        "error": f"生成失败: {status_data.get('error', {}).get('message')}",
                        "status": "failed"
                    }, ensure_ascii=False)

                status = status_data.get('status')

                if status == 'succeeded':
                    video_url = status_data.get('content', {}).get('video_url')
                    return json.dumps({
                        "success": True,
                        "video_url": video_url,
                        "status": "succeeded"
                    }, ensure_ascii=False)
                elif status in ['failed', 'cancelled']:
                    return json.dumps({
                        "error": f"任务{status}",
                        "status": status
                    }, ensure_ascii=False)
                else:
                    time.sleep(2)
                    continue

            except Exception as e:
                time.sleep(2)
                continue

        return json.dumps({"error": "超时", "status": "timeout"}, ensure_ascii=False)

    except Exception as e:
        return json.dumps({"error": str(e), "status": "failed"}, ensure_ascii=False)
