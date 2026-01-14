#!/bin/bash
# 天虹紧固件视频生成服务 - 重启脚本

echo "=========================================="
echo "天虹紧固件视频生成服务 - 重启"
echo "=========================================="

# 执行停止脚本
bash /root/PAUL/scripts/stop-service.sh

# 等待 2 秒
sleep 2

# 执行启动脚本
bash /root/PAUL/scripts/start-service.sh
