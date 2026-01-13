#!/usr/bin/env python3
"""
服务器API测试脚本
测试图片上传、视频生成、进度查询等接口
"""
import requests
import json
import time
from pathlib import Path

# 测试配置
# 开发环境使用HTTP地址（可忽略域名校验）
# 生产环境使用HTTPS地址（需要配置合法域名和正式SSL证书）
API_BASE_URL = "http://47.110.72.148"  # 开发环境
# API_BASE_URL = "https://tnho-fasteners.com"  # 生产环境

# 测试图片路径（如果没有，可以换成其他图片）
TEST_IMAGE_PATH = "assets/test_image.png"

def print_section(title):
    """打印分节标题"""
    print(f"\n{'='*60}")
    print(f"  {title}")
    print('='*60)

def test_health_check():
    """测试健康检查接口"""
    print_section("1. 测试健康检查接口")
    try:
        response = requests.get(f"{API_BASE_URL}/health", timeout=10)
        print(f"状态码: {response.status_code}")
        print(f"响应内容: {response.json()}")
        return response.status_code == 200
    except Exception as e:
        print(f"❌ 健康检查失败: {e}")
        return False

def test_upload_image():
    """测试图片上传接口"""
    print_section("2. 测试图片上传接口")

    # 创建测试图片（如果不存在）
    test_image = Path(TEST_IMAGE_PATH)
    if not test_image.exists():
        print(f"⚠️  测试图片不存在: {TEST_IMAGE_PATH}")
        print("跳过图片上传测试...")
        return None

    try:
        with open(test_image, 'rb') as f:
            files = {'file': ('test_image.png', f, 'image/png')}
            response = requests.post(
                f"{API_BASE_URL}/api/upload-image",
                files=files,
                timeout=30
            )

        print(f"状态码: {response.status_code}")
        result = response.json()
        print(f"响应内容: {json.dumps(result, indent=2, ensure_ascii=False)}")

        if result.get('success'):
            print(f"✅ 图片上传成功！")
            print(f"图片URL: {result.get('image_url')}")
            return result.get('image_url')
        else:
            print(f"❌ 图片上传失败: {result.get('message')}")
            return None
    except Exception as e:
        print(f"❌ 图片上传异常: {e}")
        return None

def test_generate_video(image_url=None):
    """测试视频生成接口"""
    print_section("3. 测试视频生成接口")

    request_data = {
        "product_name": "六角螺栓",
        "theme": "品质保证",
        "duration": 10,
        "type": "video",
        "scenario": "机械设备紧固"
    }

    if image_url:
        request_data["product_image_url"] = image_url
        print("包含产品图片URL进行图生视频测试")

    try:
        response = requests.post(
            f"{API_BASE_URL}/api/generate-video",
            json=request_data,
            headers={'Content-Type': 'application/json'},
            timeout=10
        )

        print(f"状态码: {response.status_code}")
        result = response.json()
        print(f"响应内容: {json.dumps(result, indent=2, ensure_ascii=False)}")

        if result.get('success'):
            print(f"✅ 视频生成任务创建成功！")
            print(f"任务ID: {result.get('task_id')}")
            return result.get('task_id')
        else:
            print(f"❌ 视频生成任务创建失败: {result.get('message')}")
            return None
    except Exception as e:
        print(f"❌ 视频生成异常: {e}")
        return None

def test_generate_script():
    """测试脚本生成接口"""
    print_section("4. 测试脚本生成接口")

    request_data = {
        "product_name": "六角螺栓",
        "theme": "品质保证",
        "duration": 20,
        "type": "script",
        "scenario": "机械设备紧固"
    }

    try:
        response = requests.post(
            f"{API_BASE_URL}/api/generate-video",
            json=request_data,
            headers={'Content-Type': 'application/json'},
            timeout=120  # 脚本生成可能需要较长时间
        )

        print(f"状态码: {response.status_code}")
        result = response.json()
        print(f"响应内容: {json.dumps(result, indent=2, ensure_ascii=False)}")

        if result.get('success') and result.get('script_content'):
            print(f"✅ 脚本生成成功！")
            print(f"\n脚本内容预览:\n{result.get('script_content')[:500]}...")
            return True
        else:
            print(f"❌ 脚本生成失败: {result.get('message')}")
            return False
    except Exception as e:
        print(f"❌ 脚本生成异常: {e}")
        return False

def test_progress_polling(task_id):
    """测试进度查询接口"""
    print_section("5. 测试进度查询接口（轮询3分钟）")

    if not task_id:
        print("⚠️  没有任务ID，跳过进度查询测试...")
        return False

    max_attempts = 90  # 90次 × 2秒 = 180秒 = 3分钟
    poll_interval = 2  # 每2秒轮询一次

    print(f"任务ID: {task_id}")
    print(f"开始轮询进度（最多3分钟）...\n")

    for attempt in range(1, max_attempts + 1):
        try:
            response = requests.get(
                f"{API_BASE_URL}/api/progress/{task_id}",
                timeout=10
            )

            if response.status_code == 200:
                result = response.json()

                status = result.get('status')
                progress = result.get('progress', 0)
                current_step = result.get('current_step', '')

                print(f"[{attempt:3d}/{max_attempts}] 状态: {status:12} | 进度: {progress:3}% | {current_step}")

                # 检查是否完成
                if status == 'completed':
                    print(f"\n✅ 任务完成！")
                    print(f"生成的视频URL: {result.get('merged_video_url')}")
                    print(f"所有视频段URL: {result.get('video_urls')}")
                    return True
                elif status == 'failed':
                    print(f"\n❌ 任务失败: {result.get('error_message')}")
                    return False

                # 等待
                time.sleep(poll_interval)
            else:
                print(f"[{attempt:3d}/{max_attempts}] 查询失败，状态码: {response.status_code}")
                time.sleep(poll_interval)

        except Exception as e:
            print(f"[{attempt:3d}/{max_attempts}] 查询异常: {e}")
            time.sleep(poll_interval)

    print(f"\n⚠️  轮询超时，请稍后手动查询任务进度")
    return False

def main():
    """主测试流程"""
    print("\n" + "="*60)
    print("  天虹紧固件视频生成 API 测试")
    print("="*60)
    print(f"\n测试服务器: {API_BASE_URL}\n")

    # 1. 健康检查
    health_ok = test_health_check()
    if not health_ok:
        print("\n❌ 服务器无法访问，请检查：")
        print("   1. 服务器是否启动（python app.py）")
        print("   2. 防火墙是否允许8000端口访问")
        print("   3. 网络是否通畅")
        return

    # 2. 图片上传
    image_url = test_upload_image()

    # 3. 视频生成
    task_id = test_generate_video(image_url)

    # 4. 脚本生成
    test_generate_script()

    # 5. 进度查询（如果有视频任务）
    if task_id:
        test_progress_polling(task_id)

    print("\n" + "="*60)
    print("  测试完成")
    print("="*60 + "\n")

if __name__ == "__main__":
    main()
