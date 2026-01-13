# 🚀 TNHO 视频生成服务 - 服务器快速部署

## ✅ 代码已推送到 GitHub

GitHub 仓库: https://github.com/xiebaole5/PAUL.git

---

## 🎯 服务器部署步骤

### SSH 登录服务器

```bash
ssh root@47.110.72.148
```

### 一键部署

在服务器上执行以下命令：

```bash
cd /root
rm -rf tnho-video
git clone https://github.com/xiebaole5/PAUL.git tnho-video
cd tnho-video

# 创建 .env 文件
cat > .env << 'EOF'
ARK_API_KEY=39bf20d0-55b5-4957-baa1-02f4529a3076
ARK_BASE_URL=https://ark.cn-beijing.volces.com/api/v3
S3_ENDPOINT=https://tos-s3-cn-beijing.volces.com
S3_ACCESS_KEY_ID=your_access_key_id
S3_SECRET_ACCESS_KEY=your_secret_access_key
S3_BUCKET=tnho-videos
S3_REGION=cn-beijing
PGDATABASE_URL=postgresql://postgres:postgres123@db:5432/tnho_video
APP_HOST=0.0.0.0
APP_PORT=8000
LOG_LEVEL=info
EOF

# 构建并启动
docker-compose down
docker-compose build
docker-compose up -d

# 查看日志
docker-compose logs -f
```

---

## ✅ 验证部署

### 健康检查

```bash
curl http://tnho-fasteners.com/health
```

### 访问 API 文档

浏览器访问: http://tnho-fasteners.com/docs

### 测试视频生成

```bash
curl -X POST http://tnho-fasteners.com/api/generate-video \
  -H "Content-Type: application/json" \
  -d '{"theme": "品质保证", "duration": 20}'
```

---

## 🛠️ 常用命令

### 服务管理

```bash
# 查看日志
docker-compose logs -f

# 重启服务
docker-compose restart

# 停止服务
docker-compose down

# 查看容器状态
docker-compose ps

# 进入容器
docker exec -it tnho-video-api bash
```

### 代码更新

```bash
cd /root/tnho-video
git pull origin main
docker-compose up -d --build
```

---

## ⚠️ 注意事项

1. **配置文件**: 请根据实际情况修改 `.env` 文件中的 S3 配置
2. **端口占用**: 确保 8000 端口未被占用
3. **Docker**: 确保已安装 Docker 和 Docker Compose
4. **Nginx**: 确保 Nginx 已配置反向代理

---

## 📚 详细文档

- [GitHub 部署完整指南](docs/GITHUB_DEPLOYMENT_GUIDE.md)
- [服务器手动部署指南](docs/SERVER_MANUAL_DEPLOY.md)
- [快速开始指南](DEPLOYMENT_QUICK_START.md)

---

**最后更新**: 2025-01-13
