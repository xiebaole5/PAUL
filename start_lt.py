#!/usr/bin/env python3
import subprocess
import time
import signal
import sys

def start_lt():
    """启动localtunnel并保持运行"""
    print("🚀 启动 localtunnel 内网穿透...")
    print("📡 转发 8080 端口到公网")
    print()

    # 启动 lt 进程
    cmd = ["lt", "--port", "8080", "--subdomain", "tnho-wechat-verify"]
    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

    print("🔄 等待连接建立...")
    time.sleep(3)

    # 输出所有内容
    print("=" * 60)
    for line in process.stdout:
        print(line, end='')
        sys.stdout.flush()
    print("=" * 60)

if __name__ == "__main__":
    try:
        start_lt()
    except KeyboardInterrupt:
        print("\n\n⚠️  用户中断，停止服务")
        sys.exit(0)
