#!/bin/bash
# TNHO 视频生成服务管理脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 项目路径
PROJECT_DIR="/workspace/projects"
cd $PROJECT_DIR

# 日志目录
LOG_DIR="$PROJECT_DIR/logs"
mkdir -p $LOG_DIR

# 服务端口
PORT=${PORT:-8080}

# PID 文件
PID_FILE="$LOG_DIR/app.pid"

# 日志文件
LOG_FILE="$LOG_DIR/app.log"

# 函数：检查服务状态
check_status() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat $PID_FILE)
        if ps -p $PID > /dev/null 2>&1; then
            echo -e "${GREEN}服务正在运行 (PID: $PID, Port: $PORT)${NC}"
            return 0
        else
            echo -e "${YELLOW}服务未运行 (PID 文件存在但进程不存在)${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}服务未运行 (PID 文件不存在)${NC}"
        return 1
    fi
}

# 函数：启动服务
start_service() {
    if check_status > /dev/null 2>&1; then
        echo -e "${YELLOW}服务已在运行，无需启动${NC}"
        return 0
    fi

    echo -e "${GREEN}正在启动服务...${NC}"
    PORT=$PORT nohup python3 app.py > $LOG_FILE 2>&1 &
    echo $! > $PID_FILE

    sleep 3

    if check_status > /dev/null 2>&1; then
        echo -e "${GREEN}服务启动成功！${NC}"
        echo "日志文件: $LOG_FILE"
        return 0
    else
        echo -e "${RED}服务启动失败，请查看日志：${NC}"
        tail -20 $LOG_FILE
        return 1
    fi
}

# 函数：停止服务
stop_service() {
    if ! check_status > /dev/null 2>&1; then
        echo -e "${YELLOW}服务未运行${NC}"
        return 0
    fi

    PID=$(cat $PID_FILE)
    echo -e "${YELLOW}正在停止服务 (PID: $PID)...${NC}"
    kill $PID

    # 等待进程结束
    for i in {1..10}; do
        if ! ps -p $PID > /dev/null 2>&1; then
            rm -f $PID_FILE
            echo -e "${GREEN}服务已停止${NC}"
            return 0
        fi
        sleep 1
    done

    # 如果进程仍在运行，强制结束
    echo -e "${YELLOW}强制结束进程...${NC}"
    kill -9 $PID
    rm -f $PID_FILE
    echo -e "${GREEN}服务已强制停止${NC}"
    return 0
}

# 函数：重启服务
restart_service() {
    echo -e "${GREEN}正在重启服务...${NC}"
    stop_service
    sleep 2
    start_service
}

# 函数：查看日志
view_logs() {
    if [ -f "$LOG_FILE" ]; then
        tail -f $LOG_FILE
    else
        echo -e "${RED}日志文件不存在：$LOG_FILE${NC}"
        return 1
    fi
}

# 函数：测试服务
test_service() {
    echo -e "${GREEN}正在测试服务...${NC}"
    
    # 测试健康检查
    echo -n "健康检查: "
    HEALTH=$(curl -s http://localhost:$PORT/health 2>/dev/null)
    if [ "$?" -eq 0 ]; then
        echo -e "${GREEN}OK${NC} - $HEALTH"
    else
        echo -e "${RED}FAILED${NC}"
        return 1
    fi

    # 测试 API
    echo -n "API 测试: "
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$PORT/ 2>/dev/null)
    if [ "$STATUS" -eq 200 ]; then
        echo -e "${GREEN}OK${NC} (HTTP $STATUS)"
    else
        echo -e "${RED}FAILED${NC} (HTTP $STATUS)"
        return 1
    fi

    echo -e "${GREEN}所有测试通过！${NC}"
    return 0
}

# 主函数
main() {
    case "${1:-}" in
        start)
            start_service
            ;;
        stop)
            stop_service
            ;;
        restart)
            restart_service
            ;;
        status)
            check_status
            ;;
        logs)
            view_logs
            ;;
        test)
            test_service
            ;;
        *)
            echo "用法: $0 {start|stop|restart|status|logs|test}"
            echo ""
            echo "命令说明:"
            echo "  start   - 启动服务"
            echo "  stop    - 停止服务"
            echo "  restart - 重启服务"
            echo "  status  - 查看服务状态"
            echo "  logs    - 查看服务日志（实时）"
            echo "  test    - 测试服务健康状态"
            exit 1
            ;;
    esac
}

main "$@"
