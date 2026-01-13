import requests
import json
import time

api_key = "39bf20d0-55b5-4957-baa1-02f4529a3076"
headers = {
    "Content-Type": "application/json",
    "Authorization": f"Bearer {api_key}"
}

# 使用之前创建的任务ID
task_id = "cgt-20260113203948-qpc8l"

print(f"轮询任务状态: {task_id}")

max_wait_time = 300  # 5分钟
start_time = time.time()

while time.time() - start_time < max_wait_time:
    try:
        response = requests.get(
            f'https://ark.cn-beijing.volces.com/api/v3/contents/generations/tasks/{task_id}',
            headers=headers,
            timeout=30
        )

        status_data = response.json()
        status = status_data.get('status')

        elapsed = int(time.time() - start_time)
        print(f"[{elapsed}s] 状态: {status}")

        if status == 'succeeded':
            print("\n视频生成成功！")
            video_url = status_data.get('content', {}).get('video_url')
            print(f"视频URL: {video_url}")
            print(json.dumps(status_data, ensure_ascii=False, indent=2))
            break
        elif status == 'failed':
            print("\n视频生成失败！")
            print(json.dumps(status_data, ensure_ascii=False, indent=2))
            break
        elif status in ['queued', 'running']:
            time.sleep(5)
            continue
        else:
            print(f"\n未知状态: {status}")
            print(json.dumps(status_data, ensure_ascii=False, indent=2))
            break

    except Exception as e:
        print(f"错误: {e}")
        time.sleep(5)

else:
    print(f"\n等待超时（{max_wait_time}秒）")
