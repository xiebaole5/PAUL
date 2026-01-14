#!/bin/bash
# TNHO Video Service Management Script

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PROJECT_DIR="/workspace/projects"
cd $PROJECT_DIR

LOG_DIR="$PROJECT_DIR/logs"
mkdir -p $LOG_DIR

PORT=${PORT:-8080}

PID_FILE="$LOG_DIR/app.pid"
LOG_FILE="$LOG_DIR/app.log"

check_status() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat $PID_FILE)
        if ps -p $PID > /dev/null 2>&1; then
            echo -e "${GREEN}Service running (PID: $PID, Port: $PORT)${NC}"
            return 0
        else
            echo -e "${YELLOW}Service not running (PID file exists but process not found)${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}Service not running (no PID file)${NC}"
        return 1
    fi
}

start_service() {
    if check_status > /dev/null 2>&1; then
        echo -e "${YELLOW}Service already running${NC}"
        return 0
    fi

    echo -e "${GREEN}Starting service...${NC}"
    PORT=$PORT nohup python3 app.py > $LOG_FILE 2>&1 &
    echo $! > $PID_FILE

    sleep 3

    if check_status > /dev/null 2>&1; then
        echo -e "${GREEN}Service started successfully!${NC}"
        echo "Log file: $LOG_FILE"
        return 0
    else
        echo -e "${RED}Service failed to start, check log: ${NC}"
        tail -20 $LOG_FILE
        return 1
    fi
}

stop_service() {
    if ! check_status > /dev/null 2>&1; then
        echo -e "${YELLOW}Service not running${NC}"
        return 0
    fi

    PID=$(cat $PID_FILE)
    echo -e "${YELLOW}Stopping service (PID: $PID)...${NC}"
    kill $PID

    for i in {1..10}; do
        if ! ps -p $PID > /dev/null 2>&1; then
            rm -f $PID_FILE
            echo -e "${GREEN}Service stopped${NC}"
            return 0
        fi
        sleep 1
    done

    echo -e "${YELLOW}Force killing process...${NC}"
    kill -9 $PID
    rm -f $PID_FILE
    echo -e "${GREEN}Service force stopped${NC}"
    return 0
}

restart_service() {
    echo -e "${GREEN}Restarting service...${NC}"
    stop_service
    sleep 2
    start_service
}

view_logs() {
    if [ -f "$LOG_FILE" ]; then
        tail -f $LOG_FILE
    else
        echo -e "${RED}Log file not found: $LOG_FILE${NC}"
        return 1
    fi
}

test_service() {
    echo -e "${GREEN}Testing service...${NC}"
    
    echo -n "Health check: "
    HEALTH=$(curl -s http://localhost:$PORT/health 2>/dev/null)
    if [ "$?" -eq 0 ]; then
        echo -e "${GREEN}OK${NC} - $HEALTH"
    else
        echo -e "${RED}FAILED${NC}"
        return 1
    fi

    echo -n "API test: "
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$PORT/ 2>/dev/null)
    if [ "$STATUS" -eq 200 ]; then
        echo -e "${GREEN}OK${NC} (HTTP $STATUS)"
    else
        echo -e "${RED}FAILED${NC} (HTTP $STATUS)"
        return 1
    fi

    echo -e "${GREEN}All tests passed!${NC}"
    return 0
}

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
            echo "Usage: $0 {start|stop|restart|status|logs|test}"
            echo ""
            echo "Commands:"
            echo "  start   - Start service"
            echo "  stop    - Stop service"
            echo "  restart - Restart service"
            echo "  status  - Check service status"
            echo "  logs    - View service logs (real-time)"
            echo "  test    - Test service health"
            exit 1
            ;;
    esac
}

main "$@"
