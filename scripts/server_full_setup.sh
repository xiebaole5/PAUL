#!/bin/bash
# TNHO 服务器完整配置脚本
# 用于修复开发环境HTTPS访问问题

set -e  # 遇到错误立即退出

echo "=========================================="
echo "TNHO 服务器完整配置脚本"
echo "=========================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 项目目录
PROJECT_DIR="/root/tnho-fasteners"
NGINX_CONF_DIR="/etc/nginx/sites-available"
NGINX_ENABLED_DIR="/etc/nginx/sites-enabled"

echo -e "${GREEN}[步骤 1/10] 检查项目目录${NC}"
if [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${RED}错误: 项目目录不存在: $PROJECT_DIR${NC}"
    exit 1
fi
cd "$PROJECT_DIR"
echo -e "${GREEN}✓ 项目目录确认: $PROJECT_DIR${NC}"

echo -e "\n${GREEN}[步骤 2/10] 检查 FastAPI 应用运行状态${NC}"
if pgrep -f "uvicorn.*app.main:app" > /dev/null; then
    echo -e "${GREEN}✓ FastAPI 应用正在运行${NC}"
    # 获取运行端口
    APP_PORT=$(ps aux | grep -E "uvicorn.*app.main:app.*--port" | grep -oP '(?<=--port )[0-9]+' | head -1)
    if [ -z "$APP_PORT" ]; then
        APP_PORT=9000  # 默认端口
    fi
    echo -e "${GREEN}✓ 应用端口: $APP_PORT${NC}"
else
    echo -e "${YELLOW}⚠ FastAPI 应用未运行${NC}"
    echo "启动应用: cd $PROJECT_DIR && nohup python3 -m uvicorn app.main:app --host 0.0.0.0 --port 9000 > app.log 2>&1 &"
    read -p "是否现在启动应用? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        nohup python3 -m uvicorn app.main:app --host 0.0.0.0 --port 9000 > app.log 2>&1 &
        echo -e "${GREEN}✓ 应用已启动，端口: 9000${NC}"
        sleep 3
    else
        echo -e "${RED}✗ 跳过启动应用${NC}"
        exit 1
    fi
    APP_PORT=9000
fi

echo -e "\n${GREEN}[步骤 3/10] 检查 FastAPI 应用健康状态${NC}"
HEALTH_CHECK=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:$APP_PORT/health 2>/dev/null || echo "000")
if [ "$HEALTH_CHECK" = "200" ]; then
    echo -e "${GREEN}✓ FastAPI 应用健康检查通过${NC}"
    curl -s http://127.0.0.1:$APP_PORT/health
    echo
else
    echo -e "${RED}✗ FastAPI 应用健康检查失败 (HTTP $HEALTH_CHECK)${NC}"
    echo "应用日志: tail -50 $PROJECT_DIR/app.log"
fi

echo -e "\n${GREEN}[步骤 4/10] 检查 Nginx 服务${NC}"
if command -v nginx &> /dev/null; then
    echo -e "${GREEN}✓ Nginx 已安装${NC}"
else
    echo -e "${YELLOW}⚠ Nginx 未安装${NC}"
    echo "安装 Nginx: apt update && apt install -y nginx"
    exit 1
fi

echo -e "\n${GREEN}[步骤 5/10] 检查数据库运行状态${NC}"
if docker ps | grep -q postgres; then
    echo -e "${GREEN}✓ PostgreSQL 容器正在运行${NC}"
    DB_PORT=$(docker ps --filter "name=postgres" --format "{{.Ports}}" | grep -oP '(?::)[0-9]+(?->)' | head -1)
    if [ -z "$DB_PORT" ]; then
        DB_PORT=5432
    fi
    echo -e "${GREEN}✓ 数据库端口: $DB_PORT${NC}"
else
    echo -e "${YELLOW}⚠ PostgreSQL 容器未运行${NC}"
    echo "启动数据库: cd $PROJECT_DIR && docker-compose up -d db"
    read -p "是否现在启动数据库? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cd $PROJECT_DIR
        docker-compose up -d db
        echo -e "${GREEN}✓ 数据库已启动${NC}"
        sleep 5
    else
        echo -e "${YELLOW}⚠ 跳过启动数据库${NC}"
    fi
fi

echo -e "\n${GREEN}[步骤 6/10] 部署 Nginx 配置文件${NC}"
# 检查配置文件是否存在
if [ -f "$PROJECT_DIR/etc/nginx/sites-available/tnho-https.conf" ]; then
    echo -e "${GREEN}✓ 配置文件存在${NC}"
    
    # 复制到系统目录
    cp "$PROJECT_DIR/etc/nginx/sites-available/tnho-https.conf" "$NGINX_CONF_DIR/tnho-https.conf"
    echo -e "${GREEN}✓ 配置文件已复制到系统目录${NC}"
    
    # 更新配置文件中的端口（如果需要）
    if [ "$APP_PORT" != "9000" ]; then
        sed -i "s/127.0.0.1:9000/127.0.0.1:$APP_PORT/g" "$NGINX_CONF_DIR/tnho-https.conf"
        echo -e "${GREEN}✓ 配置文件端口已更新为 $APP_PORT${NC}"
    fi
else
    echo -e "${RED}✗ 配置文件不存在: $PROJECT_DIR/etc/nginx/sites-available/tnho-https.conf${NC}"
    exit 1
fi

echo -e "\n${GREEN}[步骤 7/10] 创建 Nginx 配置符号链接${NC}"
# 确保配置文件链接到 sites-enabled
if [ ! -L "$NGINX_ENABLED_DIR/tnho-https.conf" ]; then
    ln -s "$NGINX_CONF_DIR/tnho-https.conf" "$NGINX_ENABLED_DIR/tnho-https.conf"
    echo -e "${GREEN}✓ 符号链接已创建${NC}"
else
    echo -e "${GREEN}✓ 符号链接已存在${NC}"
fi

# 删除默认配置（避免冲突）
if [ -L "$NGINX_ENABLED_DIR/default" ]; then
    rm "$NGINX_ENABLED_DIR/default"
    echo -e "${GREEN}✓ 默认配置已删除${NC}"
fi

echo -e "\n${GREEN}[步骤 8/10] 检查 SSL 证书${NC}"
# 检查 Let's Encrypt 证书
if [ -f "/etc/letsencrypt/live/tnho-fasteners.com/fullchain.pem" ]; then
    echo -e "${GREEN}✓ Let's Encrypt 证书已安装${NC}"
    CERT_EXPIRE=$(openssl x509 -in /etc/letsencrypt/live/tnho-fasteners.com/fullchain.pem -noout -enddate | cut -d= -f2)
    echo -e "${GREEN}✓ 证书有效期至: $CERT_EXPIRE${NC}"
else
    echo -e "${YELLOW}⚠ Let's Encrypt 证书未安装${NC}"
    echo "HTTPS 功能将无法使用，但 HTTP IP 访问仍然可用"
    echo "如需申请证书: certbot certonly --nginx -d tnho-fasteners.com -d www.tnho-fasteners.com"
fi

echo -e "\n${GREEN}[步骤 9/10] 测试 Nginx 配置${NC}"
if nginx -t 2>&1 | grep -q "successful"; then
    echo -e "${GREEN}✓ Nginx 配置测试通过${NC}"
else
    echo -e "${RED}✗ Nginx 配置测试失败${NC}"
    nginx -t
    exit 1
fi

echo -e "\n${GREEN}[步骤 10/10] 重启 Nginx 服务${NC}"
# 重启 Nginx
if nginx -s reload 2>&1; then
    echo -e "${GREEN}✓ Nginx 配置已重新加载${NC}"
elif service nginx restart 2>&1; then
    echo -e "${GREEN}✓ Nginx 服务已重启${NC}"
else
    echo -e "${RED}✗ Nginx 服务重启失败${NC}"
    echo "尝试手动启动: nginx"
    exit 1
fi

echo -e "\n=========================================="
echo -e "${GREEN}配置完成！${NC}"
echo "=========================================="
echo ""
echo "服务访问地址:"
echo "  开发环境（IP访问）: http://47.110.72.148"
echo "  生产环境（域名）:   https://tnho-fasteners.com（需完成ICP备案）"
echo ""
echo "测试命令:"
echo "  健康检查: curl http://47.110.72.148/health"
echo "  API测试:   curl http://47.110.72.148/api/themes"
echo ""
echo "监控命令:"
echo "  Nginx状态:  nginx -t"
echo "  应用状态:   ps aux | grep uvicorn"
echo "  应用日志:   tail -50 $PROJECT_DIR/app.log"
echo "  Nginx日志:  tail -50 /var/log/nginx/error.log"
echo ""
echo "⚠️  注意事项:"
echo "  1. 开发环境使用 IP 地址 HTTP 访问"
echo "  2. 生产环境必须完成 ICP 备案后才能使用域名 HTTPS 访问"
echo "  3. 小程序 API 地址应配置为: http://47.110.72.148"
echo ""
