#!/bin/bash

# 配置更新脚本 - 更新 docker-compose.yml 环境变量

# 备份原文件
cp docker-compose.yml docker-compose.yml.backup.$(date +%Y%m%d_%H%M%S)

# 更新环境变量
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  # FastAPI 后端服务
  api:
    build: .
    container_name: tnho-video-api
    ports:
      - "8000:8000"
    environment:
      - COZE_WORKSPACE_PATH=/app
      - COZE_INTEGRATION_MODEL_BASE_URL=https://ark.cn-beijing.volces.com/api/v3
      - COZE_WORKLOAD_IDENTITY_API_KEY=39bf20d0-55b5-4957-baa1-02f4529a3076
      - EXTERNAL_BASE_URL=https://tnho-fasteners.com
      - ARK_API_KEY=39bf20d0-55b5-4957-baa1-02f4529a3076
      - ARK_BASE_URL=https://ark.cn-beijing.volces.com/api/v3
    volumes:
      - ./src:/app/src
      - ./config:/app/config
      - ./assets:/app/assets
      - ./logs:/app/logs
      - ./src/config:/app/src/config
    restart: unless-stopped
    networks:
      - tnho-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

  # Nginx 反向代理
  nginx:
    image: nginx:alpine
    container_name: tnho-nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
      - ./nginx/logs:/var/log/nginx
      - ./assets:/var/www/assets
      - /etc/letsencrypt:/etc/letsencrypt:ro
    depends_on:
      - api
    restart: unless-stopped
    networks:
      - tnho-network

networks:
  tnho-network:
    driver: bridge

volumes:
  assets:
  logs:
EOF

echo "✅ docker-compose.yml 已更新"
echo "📁 备份文件: docker-compose.yml.backup.*"
