"""
测试微信小程序后端API功能
"""
import sys
import os
import json
import requests
import time
import tempfile
from pathlib import Path

# 添加项目根目录到 Python 路径
workspace_path = os.getenv("COZE_WORKSPACE_PATH", "/workspace/projects")
if workspace_path not in sys.path:
    sys.path.insert(0, workspace_path)

# API 基础URL
# 尝试HTTPS，如果失败则使用HTTP
API_BASE_URL = "http://47.110.72.148"  # "https://tnho-fasteners.com" 或 "http://47.110.72.148"

print("=" * 60)
print("测试微信小程序后端API")
print("=" * 60)
print(f"API 地址: {API_BASE_URL}")
print(f"注意：使用HTTP而非HTTPS，因为自签名证书可能导致连接问题\n")

def test_health_check():
    """测试健康检查接口"""
    print("\n测试1: 健康检查接口")
    print("-" * 60)

    try:
        response = requests.get(f"{API_BASE_URL}/health", timeout=10)
        if response.status_code == 200:
            data = response.json()
            print(f"✓ 健康检查通过")
            print(f"  响应: {data}")
            return True
        else:
            print(f"✗ 健康检查失败: HTTP {response.status_code}")
            return False
    except Exception as e:
        print(f"✗ 健康检查异常: {str(e)}")
        return False

def test_upload_image():
    """测试图片上传功能"""
    print("\n测试2: 图片上传功能")
    print("-" * 60)

    try:
        # 创建一个测试图片（1x1像素的PNG）
        import base64
        png_data = base64.b64decode(
            "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg=="
        )

        # 使用临时文件
        with tempfile.NamedTemporaryFile(suffix=".png", delete=False) as f:
            f.write(png_data)
            temp_path = f.name

        try:
            # 上传图片
            with open(temp_path, 'rb') as f:
                files = {'file': ('test.png', f, 'image/png')}
                response = requests.post(
                    f"{API_BASE_URL}/api/upload-image",
                    files=files,
                    timeout=10
                )

            if response.status_code == 200:
                data = response.json()
                if data.get("success"):
                    print(f"✓ 图片上传成功")
                    print(f"  图片URL: {data.get('image_url')}")
                    print(f"  文件名: {data.get('filename')}")
                    return data.get("image_url")
                else:
                    print(f"✗ 图片上传失败: {data.get('message')}")
                    return None
            else:
                print(f"✗ 图片上传失败: HTTP {response.status_code}")
                print(f"  响应: {response.text}")
                return None
        finally:
            # 清理临时文件
            if os.path.exists(temp_path):
                os.remove(temp_path)

    except Exception as e:
        print(f"✗ 图片上传异常: {str(e)}")
        import traceback
        traceback.print_exc()
        return None

def test_generate_video():
    """测试视频生成功能（短视频，5秒）"""
    print("\n测试3: 视频生成功能（5秒短视频）")
    print("-" * 60)

    try:
        request_data = {
            "product_name": "测试高强度螺栓",
            "theme": "品质保证",
            "duration": 5,
            "type": "video",
            "scenario": "用于测试的产品",
            "product_image_url": ""
        }

        print(f"请求数据: {json.dumps(request_data, ensure_ascii=False, indent=2)}")

        response = requests.post(
            f"{API_BASE_URL}/api/generate-video",
            json=request_data,
            headers={"Content-Type": "application/json"},
            timeout=10
        )

        if response.status_code == 200:
            data = response.json()
            if data.get("success"):
                print(f"✓ 视频生成任务创建成功")
                print(f"  任务ID: {data.get('task_id')}")
                print(f"  消息: {data.get('message')}")
                return data.get("task_id")
            else:
                print(f"✗ 视频生成失败: {data.get('message')}")
                return None
        else:
            print(f"✗ 视频生成失败: HTTP {response.status_code}")
            print(f"  响应: {response.text}")
            return None

    except Exception as e:
        print(f"✗ 视频生成异常: {str(e)}")
        import traceback
        traceback.print_exc()
        return None

def test_generate_script():
    """测试脚本生成功能"""
    print("\n测试4: 脚本生成功能")
    print("-" * 60)

    try:
        request_data = {
            "product_name": "测试不锈钢螺丝",
            "theme": "技术创新",
            "duration": 20,
            "type": "script",
            "scenario": "用于机械设备连接"
        }

        print(f"请求数据: {json.dumps(request_data, ensure_ascii=False, indent=2)}")

        response = requests.post(
            f"{API_BASE_URL}/api/generate-video",
            json=request_data,
            headers={"Content-Type": "application/json"},
            timeout=30  # 脚本生成可能需要更长时间
        )

        if response.status_code == 200:
            data = response.json()
            if data.get("success"):
                print(f"✓ 脚本生成成功")
                print(f"  脚本长度: {len(data.get('script_content', ''))} 字符")
                print(f"  脚本预览: {data.get('script_content', '')[:100]}...")
                return True
            else:
                print(f"✗ 脚本生成失败: {data.get('message')}")
                return False
        else:
            print(f"✗ 脚本生成失败: HTTP {response.status_code}")
            print(f"  响应: {response.text}")
            return False

    except Exception as e:
        print(f"✗ 脚本生成异常: {str(e)}")
        import traceback
        traceback.print_exc()
        return False

def test_poll_progress(task_id, max_wait_time=120):
    """测试进度查询功能"""
    if not task_id:
        print("\n测试5: 跳过进度查询（无任务ID）")
        print("-" * 60)
        return False

    print(f"\n测试5: 进度查询功能（任务ID: {task_id}）")
    print("-" * 60)
    print(f"⚠ 注意：视频生成可能需要 {max_wait_time} 秒，请耐心等待...")

    start_time = time.time()
    poll_count = 0
    max_polls = 60  # 最多轮询60次（每2秒一次）

    while time.time() - start_time < max_wait_time and poll_count < max_polls:
        poll_count += 1

        try:
            response = requests.get(
                f"{API_BASE_URL}/api/progress/{task_id}",
                timeout=10
            )

            if response.status_code == 200:
                data = response.json()
                if data.get("success"):
                    status = data.get("status")
                    progress = data.get("progress", 0)
                    message = data.get("message", "")

                    print(f"  轮询 #{poll_count}: 状态={status}, 进度={progress}%, 消息={message}")

                    if status == "completed":
                        print(f"\n✓ 任务完成！")
                        print(f"  视频URL: {data.get('video_urls')}")
                        print(f"  拼接后URL: {data.get('merged_video_url')}")
                        return True
                    elif status == "failed":
                        print(f"\n✗ 任务失败")
                        print(f"  错误信息: {data.get('error_message')}")
                        return False
                    elif status in ["pending", "generating", "merging", "uploading"]:
                        # 继续等待
                        time.sleep(2)
                        continue
                    else:
                        print(f"\n⚠ 未知状态: {status}")
                        time.sleep(2)
                        continue
                else:
                    print(f"✗ 查询失败: {data.get('message')}")
                    return False
            else:
                print(f"✗ 查询失败: HTTP {response.status_code}")
                print(f"  响应: {response.text}")
                time.sleep(2)
                continue

        except Exception as e:
            print(f"✗ 查询异常: {str(e)}")
            time.sleep(2)
            continue

    print(f"\n⚠ 超时：任务在 {max_wait_time} 秒内未完成")
    return False

# 主测试流程
if __name__ == "__main__":
    results = []

    # 测试1: 健康检查
    results.append(("健康检查", test_health_check()))

    # 测试2: 图片上传
    image_url = test_upload_image()
    results.append(("图片上传", image_url is not None))

    # 测试3: 视频生成（5秒短视频，快速测试）
    task_id = test_generate_video()
    results.append(("视频生成", task_id is not None))

    # 如果视频生成成功，测试进度查询
    if task_id:
        poll_result = test_poll_progress(task_id, max_wait_time=120)
        results.append(("进度查询", poll_result))

    # 测试4: 脚本生成
    results.append(("脚本生成", test_generate_script()))

    # 打印测试结果汇总
    print("\n" + "=" * 60)
    print("测试结果汇总")
    print("=" * 60)

    for test_name, result in results:
        status = "✓ 通过" if result else "✗ 失败"
        print(f"  {test_name}: {status}")

    passed = sum(1 for _, result in results if result)
    total = len(results)
    print(f"\n总计: {passed}/{total} 通过")

    if passed == total:
        print("\n🎉 所有测试通过！")
    else:
        print("\n⚠ 部分测试失败，请检查上述错误信息")
