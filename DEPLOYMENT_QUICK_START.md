# 🚀 TNHO 视频生成服务部署指南

## 📦 已准备好的资源

✅ **完整代码**: `/workspace/projects` (1.2MB)
✅ **GitHub 仓库**: https://github.com/xiebaole5/PAUL.git
✅ **部署脚本**: 
   - `scripts/push_to_github.sh` - 推送到 GitHub
   - `scripts/deploy_from_github.sh` - 服务器部署
   - `scripts/upload_and_deploy.ps1` - Windows 上传脚本
✅ **部署文档**:
   - `docs/GITHUB_DEPLOYMENT_GUIDE.md` - GitHub 部署完整指南
   - `docs/SERVER_MANUAL_DEPLOY.md` - 服务器手动部署指南

---

## 🎯 快速开始

### 方案 1: GitHub 部署（推荐）

**第一步：推送代码到 GitHub**

您需要将代码推送到 GitHub 仓库。由于需要您的 GitHub 凭证，请选择以下方式之一：

#### 方式 A: 使用 SSH 密钥

```bash
# 1. 生成 SSH 密钥（如果还没有）
ssh-keygen -t ed25519 -C "your_email@example.com"

# 2. 查看公钥
cat ~/.ssh/id_ed25519.pub

# 3. 将公钥添加到 GitHub
# 访问: https://github.com/settings/keys
# 点击 "New SSH key"，粘贴公钥

# 4. 推送代码
cd /workspace/projects
git remote set-url origin git@github.com:xiebaole5/PAUL.git
git push -u origin main
```

#### 方式 B: 使用 Personal Access Token

```bash
# 1. 生成 Token
# 访问: https://github.com/settings/tokens
# 点击 "Generate new token (classic)"
# 勾选 "repo" 权限并生成

# 2. 推送代码（替换 YOUR_TOKEN）
git push https://YOUR_TOKEN@github.com/xiebaole5/PAUL.git main
```

#### 方式 C: 使用推送脚本

```bash
cd /workspace/projects
chmod +x scripts/push_to_github.sh
./scripts/push_to_github.sh
```

---

**第二步：在服务器上部署**

SSH 登录服务器后执行：

```bash
# 1. 克隆代码
cd /root
git clone git@github.com:xiebaole5/PAUL.git tnho-video
cd tnho-video

# 2. 配置 .env 文件
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

# 3. 部署
chmod +x scripts/deploy_from_github.sh
./scripts/deploy_from_github.sh
```

---

### 方案 2: 直接上传代码压缩包（备用）

如果您不想使用 Git，可以直接上传代码压缩包到服务器：

**在服务器上执行：**

```bash
# 1. 创建项目目录
mkdir -p /root/tnho-video
cd /root/tnho-video

# 2. 下载代码压缩包（如果可以从某个地方下载）
# 或者使用 scp 从本地上传：
# scp /tmp/tnho-complete-code.tar.gz root@47.110.72.148:/root/tnho-video/

# 3. 解压
tar -xzf tnho-complete-code.tar.gz

# 4. 配置 .env 并部署（同方案 1）
```

**代码压缩包位置**: `/tmp/tnho-complete-code.tar.gz` (1.2MB)

---

## ✅ 验证部署

部署完成后，执行以下验证：

```bash
# 健康检查
curl http://tnho-fasteners.com/health

# 访问 API 文档
# 浏览器打开: http://tnho-fasteners.com/docs

# 测试视频生成
curl -X POST http://tnho-fasteners.com/api/generate-video \
  -H "Content-Type: application/json" \
  -d '{"theme": "品质保证", "duration": 20}'
```

---

## 📚 详细文档

- **GitHub 部署指南**: [docs/GITHUB_DEPLOYMENT_GUIDE.md](docs/GITHUB_DEPLOYMENT_GUIDE.md)
- **手动部署指南**: [docs/SERVER_MANUAL_DEPLOY.md](docs/SERVER_MANUAL_DEPLOY.md)
- **部署说明**: [DEPLOYMENT.md](DEPLOYMENT.md)

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
```

### 代码更新

```bash
# 拉取最新代码
git pull origin main

# 重新部署
docker-compose up -d --build
```

---

## 🐛 故障排查

### 问题 1: 无法克隆仓库

```bash
# 检查 SSH 密钥
ls -la ~/.ssh/

# 生成 SSH 密钥
ssh-keygen -t ed25519

# 添加公钥到 GitHub
cat ~/.ssh/id_ed25519.pub
```

### 问题 2: 服务启动失败

```bash
# 查看日志
docker-compose logs

# 重新构建
docker-compose build --no-cache
docker-compose up -d
```

---

## 📞 下一步

部署成功后，需要配置：

1. **对象存储**: 在 `.env` 中配置 S3 凭证
2. **视频生成 API**: 确认火山方舟视频模型可用
3. **微信小程序**: 前端对接 API

---

## 💡 提示

- 推荐使用方案 1（GitHub 部署），便于代码管理和版本控制
- 如遇问题，请查看详细文档或日志
- `.env` 文件中的敏感信息请勿提交到 Git

---

**最后更新**: 2025-01-13
