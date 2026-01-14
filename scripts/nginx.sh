#!/bin/bash

# Nginx 服务管理脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# 显示帮助信息
show_help() {
    echo "Usage: $0 {start|stop|restart|status|test|config}"
    echo ""
    echo "Commands:"
    echo "  start    - 启动 Nginx 服务"
    echo "  stop     - 停止 Nginx 服务"
    echo "  restart  - 重启 Nginx 服务"
    echo "  status   - 查看 Nginx 状态"
    echo "  test     - 测试 Nginx 配置"
    echo "  config   - 显示当前配置"
}

# 启动 Nginx
nginx_start() {
    echo -e "${GREEN}[INFO]${NC} 启动 Nginx 服务..."
    if pgrep -x "nginx" > /dev/null; then
        echo -e "${YELLOW}[WARN]${NC} Nginx 已经在运行"
        return 0
    fi

    nginx
    sleep 2

    if pgrep -x "nginx" > /dev/null; then
        echo -e "${GREEN}[SUCCESS]${NC} Nginx 启动成功"
        nginx_status
    else
        echo -e "${RED}[ERROR]${NC} Nginx 启动失败"
        exit 1
    fi
}

# 停止 Nginx
nginx_stop() {
    echo -e "${GREEN}[INFO]${NC} 停止 Nginx 服务..."
    if ! pgrep -x "nginx" > /dev/null; then
        echo -e "${YELLOW}[WARN]${NC} Nginx 未在运行"
        return 0
    fi

    nginx -s stop
    sleep 2

    if pgrep -x "nginx" > /dev/null; then
        echo -e "${RED}[ERROR]${NC} Nginx 停止失败，尝试强制停止..."
        pkill -9 nginx
        sleep 1
    fi

    echo -e "${GREEN}[SUCCESS]${NC} Nginx 已停止"
}

# 重启 Nginx
nginx_restart() {
    echo -e "${GREEN}[INFO]${NC} 重启 Nginx 服务..."
    nginx_stop
    nginx_start
}

# 查看状态
nginx_status() {
    echo -e "${GREEN}[INFO]${NC} Nginx 状态:"
    echo ""

    # 进程状态
    if pgrep -x "nginx" > /dev/null; then
        echo -e "  进程状态: ${GREEN}运行中${NC}"
        echo ""
        echo "  进程列表:"
        ps aux | grep nginx | grep -v grep | awk '{printf "    PID %s: %s\n", $2, $11}'
    else
        echo -e "  进程状态: ${RED}已停止${NC}"
    fi

    echo ""

    # 端口监听
    echo "  端口监听:"
    if command -v netstat > /dev/null; then
        netstat -tlnp 2>/dev/null | grep nginx | awk '{printf "    %s\n", $4}' | sed 's/^/      /' || echo "    未找到监听端口"
    elif command -v ss > /dev/null; then
        ss -tlnp 2>/dev/null | grep nginx | awk '{printf "    %s\n", $4}' | sed 's/^/      /' || echo "    未找到监听端口"
    else
        echo "    无法获取端口信息"
    fi

    echo ""

    # 配置测试
    echo "  配置测试:"
    if nginx -t 2>&1 | grep -q "successful"; then
        echo -e "    ${GREEN}配置文件正确${NC}"
    else
        echo -e "    ${RED}配置文件有误${NC}"
    fi
}

# 测试配置
nginx_test() {
    echo -e "${GREEN}[INFO]${NC} 测试 Nginx 配置..."
    nginx -t
}

# 显示配置
nginx_config() {
    echo -e "${GREEN}[INFO]${NC} 当前 Nginx 配置:"
    echo ""

    # HTTPS 配置
    if [ -f /etc/nginx/sites-available/tnho-https.conf ]; then
        echo "  HTTPS 配置: /etc/nginx/sites-available/tnho-https.conf"
        echo ""

        # SSL 证书信息
        if [ -f /etc/nginx/ssl/tnho-origin.crt ]; then
            echo "  SSL 证书: /etc/nginx/ssl/tnho-origin.crt"
            echo "  证书信息:"
            openssl x509 -in /etc/nginx/ssl/tnho-origin.crt -noout -subject -issuer -dates 2>/dev/null | sed 's/^/    /'
        fi

        echo ""

        # 端口映射
        echo "  端口映射:"
        echo "    HTTP (80)  -> HTTPS (443)"
        echo "    HTTPS (443) -> FastAPI (8080)"
        echo "    HTTP (8080) -> FastAPI (直接访问)"
    else
        echo -e "  ${RED}未找到 HTTPS 配置${NC}"
    fi

    echo ""

    # 测试访问
    echo "  测试访问:"
    echo -n "    HTTP: "
    if curl -s -o /dev/null -w "%{http_code}" http://localhost/health 2>/dev/null | grep -q "301"; then
        echo -e "${GREEN}重定向到 HTTPS${NC}"
    else
        echo -e "${RED}异常${NC}"
    fi

    echo -n "    HTTPS: "
    if curl -sk -o /dev/null -w "%{http_code}" https://localhost/health 2>/dev/null | grep -q "200"; then
        echo -e "${GREEN}正常${NC}"
    else
        echo -e "${RED}异常${NC}"
    fi
}

# 主函数
main() {
    case "$1" in
        start)
            nginx_start
            ;;
        stop)
            nginx_stop
            ;;
        restart)
            nginx_restart
            ;;
        status)
            nginx_status
            ;;
        test)
            nginx_test
            ;;
        config)
            nginx_config
            ;;
        *)
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
