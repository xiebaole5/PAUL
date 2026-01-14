#!/bin/bash
# TNHO 问题排查脚本
# 用于快速诊断服务器问题

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目目录
PROJECT_DIR="/root/tnho-fasteners"

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}TNHO 问题排查脚本${NC}"
echo -e "${BLUE}==========================================${NC}"
echo ""

# 检查函数
check_service() {
    local service_name=$1
    local check_command=$2
    local expected_result=$3

    echo -n "检查 $service_name ... "
    if eval "$check_command" | grep -q "$expected_result"; then
        echo -e "${GREEN}✓ 正常${NC}"
        return 0
    else
        echo -e "${RED}✗ 异常${NC}"
        return 1
    fi
}

# 检查 1: 系统资源
echo -e "${YELLOW}[1/15] 系统资源检查${NC}"
echo "----------------------------------------"
echo "CPU 使用率:"
top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}'
echo ""
echo "内存使用情况:"
free -h
echo ""
echo "磁盘使用情况:"
df -h | grep -E "/$"
echo ""

# 检查 2: FastAPI 应用运行状态
echo -e "${YELLOW}[2/15] FastAPI 应用检查${NC}"
echo "----------------------------------------"
if pgrep -f "uvicorn.*app.main:app" > /dev/null; then
    echo -e "${GREEN}✓ FastAPI 应用正在运行${NC}"
    ps aux | grep -E "uvicorn.*app.main:app" | grep -v grep
    APP_PID=$(pgrep -f "uvicorn.*app.main:app" | head -1)
    APP_PORT=$(ps aux | grep -E "uvicorn.*app.main:app.*--port" | grep -oP '(?<=--port )[0-9]+' | head -1)
    echo "应用进程ID: $APP_PID"
    echo "应用端口: ${APP_PORT:-9000}"
else
    echo -e "${RED}✗ FastAPI 应用未运行${NC}"
fi
echo ""

# 检查 3: FastAPI 应用健康状态
echo -e "${YELLOW}[3/15] FastAPI 健康检查${NC}"
echo "----------------------------------------"
APP_PORT=$(ps aux | grep -E "uvicorn.*app.main:app.*--port" | grep -oP '(?<=--port )[0-9]+' | head -1)
APP_PORT=${APP_PORT:-9000}

if curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:$APP_PORT/health 2>/dev/null | grep -q "200"; then
    echo -e "${GREEN}✓ FastAPI 健康检查通过${NC}"
    curl -s http://127.0.0.1:$APP_PORT/health
    echo ""
else
    echo -e "${RED}✗ FastAPI 健康检查失败${NC}"
fi
echo ""

# 检查 4: FastAPI API 接口
echo -e "${YELLOW}[4/15] FastAPI API 接口检查${NC}"
echo "----------------------------------------"
if curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:$APP_PORT/api/themes 2>/dev/null | grep -q "200"; then
    echo -e "${GREEN}✓ API 接口正常${NC}"
    curl -s http://127.0.0.1:$APP_PORT/api/themes | python3 -m json.tool | head -20
else
    echo -e "${RED}✗ API 接口异常${NC}"
fi
echo ""

# 检查 5: PostgreSQL 数据库
echo -e "${YELLOW}[5/15] PostgreSQL 数据库检查${NC}"
echo "----------------------------------------"
if docker ps | grep -q postgres; then
    echo -e "${GREEN}✓ PostgreSQL 容器正在运行${NC}"
    docker ps --filter "name=postgres" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
else
    echo -e "${RED}✗ PostgreSQL 容器未运行${NC}"
    if docker ps -a | grep -q postgres; then
        echo "已停止的容器："
        docker ps -a --filter "name=postgres" --format "table {{.Names}}\t{{.Status}}"
    fi
fi
echo ""

# 检查 6: 数据库连接
echo -e "${YELLOW}[6/15] 数据库连接检查${NC}"
echo "----------------------------------------"
if docker ps | grep -q postgres; then
    CONTAINER_NAME=$(docker ps --filter "name=postgres" --format "{{.Names}}" | head -1)
    if docker exec $CONTAINER_NAME psql -U postgres -c "SELECT version();" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ 数据库连接正常${NC}"
        docker exec $CONTAINER_NAME psql -U postgres -c "\dt" | grep video_generation_tasks
    else
        echo -e "${RED}✗ 数据库连接失败${NC}"
    fi
else
    echo -e "${YELLOW}⚠ 跳过数据库连接检查（容器未运行）${NC}"
fi
echo ""

# 检查 7: Nginx 服务
echo -e "${YELLOW}[7/15] Nginx 服务检查${NC}"
echo "----------------------------------------"
if command -v nginx &> /dev/null; then
    echo -e "${GREEN}✓ Nginx 已安装${NC}"
    nginx -v
else
    echo -e "${RED}✗ Nginx 未安装${NC}"
fi
echo ""

# 检查 8: Nginx 运行状态
echo -e "${YELLOW}[8/15] Nginx 运行状态检查${NC}"
echo "----------------------------------------"
if pgrep nginx > /dev/null; then
    echo -e "${GREEN}✓ Nginx 正在运行${NC}"
    ps aux | grep nginx | grep -v grep
else
    echo -e "${RED}✗ Nginx 未运行${NC}"
fi
echo ""

# 检查 9: Nginx 配置
echo -e "${YELLOW}[9/15] Nginx 配置检查${NC}"
echo "----------------------------------------"
if nginx -t 2>&1 | grep -q "successful"; then
    echo -e "${GREEN}✓ Nginx 配置正确${NC}"
    nginx -t
else
    echo -e "${RED}✗ Nginx 配置错误${NC}"
    nginx -t
fi
echo ""

# 检查 10: Nginx 端口监听
echo -e "${YELLOW}[10/15] Nginx 端口监听检查${NC}"
echo "----------------------------------------"
if netstat -tlnp 2>/dev/null | grep -q nginx; then
    echo -e "${GREEN}✓ Nginx 端口监听正常${NC}"
    netstat -tlnp 2>/dev/null | grep nginx
else
    echo -e "${YELLOW}⚠ 使用 ss 命令检查${NC}"
    ss -tlnp | grep nginx
fi
echo ""

# 检查 11: HTTP 访问（IP）
echo -e "${YELLOW}[11/15] HTTP IP 访问检查${NC}"
echo "----------------------------------------"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://47.110.72.148/health 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓ HTTP IP 访问正常${NC}"
    curl -s http://47.110.72.148/health
    echo ""
elif [ "$HTTP_CODE" = "301" ]; then
    echo -e "${YELLOW}⚠ HTTP IP 访问被重定向（可能配置问题）${NC}"
else
    echo -e "${RED}✗ HTTP IP 访问失败 (HTTP $HTTP_CODE)${NC}"
fi
echo ""

# 检查 12: SSL 证书
echo -e "${YELLOW}[12/15] SSL 证书检查${NC}"
echo "----------------------------------------"
if [ -f "/etc/letsencrypt/live/tnho-fasteners.com/fullchain.pem" ]; then
    echo -e "${GREEN}✓ Let's Encrypt 证书已安装${NC}"
    CERT_INFO=$(openssl x509 -in /etc/letsencrypt/live/tnho-fasteners.com/fullchain.pem -noout -subject -dates)
    echo "$CERT_INFO"
else
    echo -e "${YELLOW}⚠ Let's Encrypt 证书未安装${NC}"
    echo "HTTPS 功能将无法使用，但 HTTP IP 访问仍然可用"
fi
echo ""

# 检查 13: 环境变量
echo -e "${YELLOW}[13/15] 环境变量检查${NC}"
echo "----------------------------------------"
if [ -f "$PROJECT_DIR/.env" ]; then
    echo -e "${GREEN}✓ .env 文件存在${NC}"
    echo "关键配置项（部分隐藏）:"
    grep -E "(ARK_API_KEY|PGDATABASE_URL|OSS_)" "$PROJECT_DIR/.env" | sed 's/=.*/=***/'
else
    echo -e "${RED}✗ .env 文件不存在${NC}"
fi
echo ""

# 检查 14: 日志文件
echo -e "${YELLOW}[14/15] 日志文件检查${NC}"
echo "----------------------------------------"
echo "应用日志（最后 20 行）:"
if [ -f "$PROJECT_DIR/app.log" ]; then
    tail -20 "$PROJECT_DIR/app.log"
else
    echo -e "${YELLOW}⚠ 应用日志文件不存在${NC}"
fi
echo ""
echo "Nginx 错误日志（最后 20 行）:"
if [ -f "/var/log/nginx/error.log" ]; then
    tail -20 /var/log/nginx/error.log
else
    echo -e "${YELLOW}⚠ Nginx 错误日志文件不存在${NC}"
fi
echo ""

# 检查 15: 快速测试
echo -e "${YELLOW}[15/15] 快速功能测试${NC}"
echo "----------------------------------------"
echo "测试 1: 健康检查接口"
curl -s -o /dev/null -w "HTTP 状态码: %{http_code}\n" http://47.110.72.148/health
echo ""
echo "测试 2: 主题列表接口"
curl -s -o /dev/null -w "HTTP 状态码: %{http_code}\n" http://47.110.72.148/api/themes
echo ""

# 总结
echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}排查完成${NC}"
echo -e "${BLUE}==========================================${NC}"
echo ""
echo "建议操作:"
echo ""
echo "1. 如果 FastAPI 应用未运行："
echo "   cd $PROJECT_DIR && nohup python3 -m uvicorn app.main:app --host 0.0.0.0 --port 9000 > app.log 2>&1 &"
echo ""
echo "2. 如果数据库未运行："
echo "   cd $PROJECT_DIR && docker-compose up -d db"
echo ""
echo "3. 如果 Nginx 配置错误："
echo "   运行部署脚本: ./scripts/server_full_setup.sh"
echo ""
echo "4. 如果 HTTP IP 访问失败："
echo "   检查 Nginx 配置文件: cat /etc/nginx/sites-available/tnho-https.conf"
echo ""
echo "5. 查看完整日志："
echo "   应用日志: tail -f $PROJECT_DIR/app.log"
echo "   Nginx 日志: tail -f /var/log/nginx/error.log"
echo ""
