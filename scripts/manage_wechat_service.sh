#!/bin/bash
# 企业微信服务管理脚本

case "$1" in
    start)
        echo "启动企业微信服务..."
        cd /workspace/projects
        python3 app.py > /tmp/fastapi.log 2>&1 &
        echo "服务已启动，PID: $!"
        echo "查看日志: tail -f /tmp/fastapi.log"
        ;;
    stop)
        echo "停止企业微信服务..."
        pkill -f 'python3 app.py'
        echo "服务已停止"
        ;;
    restart)
        echo "重启企业微信服务..."
        pkill -f 'python3 app.py'
        sleep 2
        cd /workspace/projects
        python3 app.py > /tmp/fastapi.log 2>&1 &
        echo "服务已重启，PID: $!"
        echo "查看日志: tail -f /tmp/fastapi.log"
        ;;
    status)
        echo "服务状态:"
        ps aux | grep 'python3 app.py' | grep -v grep
        echo ""
        echo "健康检查:"
        curl -s http://localhost:8080/api/wechat/test
        echo ""
        ;;
    test)
        echo "测试企业微信 URL 验证接口..."
        curl -s http://localhost:8080/api/wechat/test
        echo ""
        ;;
    logs)
        echo "查看最近 50 行日志:"
        tail -50 /tmp/fastapi.log
        ;;
    *)
        echo "用法: $0 {start|stop|restart|status|test|logs}"
        echo ""
        echo "示例:"
        echo "  $0 start    # 启动服务"
        echo "  $0 stop     # 停止服务"
        echo "  $0 restart  # 重启服务"
        echo "  $0 status   # 查看状态"
        echo "  $0 test     # 测试接口"
        echo "  $0 logs     # 查看日志"
        exit 1
        ;;
esac
