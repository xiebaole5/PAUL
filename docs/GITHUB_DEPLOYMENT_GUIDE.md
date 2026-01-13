# TNHO 视频生成服务 - GitHub 部署完整指南

## 📋 前提条件

- 本地代码已完整
- GitHub 仓库: https://github.com/xiebaole5/PAUL.git
- 服务器: 47.110.72.148
- 域名: tnho-fasteners.com

## 🚀 部署步骤

### 第一阶段：推送代码到 GitHub

#### 方法 1: 使用 SSH 密钥（推荐）

**1. 在本地生成 SSH 密钥**

如果您有 SSH 密钥，跳过此步骤。

```bash
# 在您的 Windows 本地或 Linux 环境中执行
ssh-keygen -t ed25519 -C "your_email@example.com"
```

**2. 查看公钥**

```bash
cat ~/.ssh/id_ed25519.pub
```

**3. 将公钥添加到 GitHub**

- 访问 https://github.com/settings/keys
- 点击 "New SSH key"
- 粘贴公钥内容
- 点击 "Add SSH key"

**4. 推送代码**

```bash
cd /workspace/projects
git remote set-url origin git@github.com:xiebaole5/PAUL.git
git push -u origin main
```

#### 方法 2: 使用 Personal Access Token

**1. 生成 Personal Access Token**

- 访问 https://github.com/settings/tokens
- 点击 "Generate new token" -> "Generate new token (classic)"
- 勾选 `repo` 权限
- 点击 "Generate token" 并复制 token（注意：token 只显示一次）

**2. 推送代码**

```bash
cd /workspace/projects
# 使用 token 推送（将 YOUR_TOKEN 替换为实际的 token）
git push https://YOUR_TOKEN@github.com/xiebaole5/PAUL.git main
```

或者使用推送脚本：

```bash
chmod +x scripts/push_to_github.sh
./scripts/push_to_github.sh
```

---

### 第二阶段：在服务器上部署

#### 步骤 1: SSH 登录服务器

```bash
ssh root@47.110.72.148
```

#### 步骤 2: 配置 SSH 密钥（如果使用 SSH 克隆）

**生成 SSH 密钥**

```bash
ssh-keygen -t ed25519 -C "root@tnho-server"
# 按回车使用默认设置
```

**查看公钥**

```bash
cat ~/.ssh/id_ed25519.pub
```

**添加到 GitHub**

- 访问 https://github.com/settings/keys
- 点击 "New SSH key"
- 粘贴公钥内容
- 点击 "Add SSH key"

**测试 SSH 连接**

```bash
ssh -T git@github.com
```

#### 步骤 3: 克隆代码并部署

**方法 1: 使用自动化脚本（推荐）**

```bash
# 在服务器上执行
cd /root
git clone git@github.com:xiebaole5/PAUL.git tnho-video
cd tnho-video

# 复制部署脚本
chmod +x scripts/deploy_from_github.sh

# 执行部署
./scripts/deploy_from_github.sh
```

**方法 2: 手动部署**

```bash
# 克隆代码
cd /root
rm -rf tnho-video
git clone git@github.com:xiebaole5/PAUL.git tnho-video
cd tnho-video

# 检查并创建 .env 文件
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

预期返回：
```json
{"status":"healthy","timestamp":1234567890.123}
```

### 访问 API 文档

浏览器访问: http://tnho-fasteners.com/docs

### 测试视频生成

```bash
curl -X POST http://tnho-fasteners.com/api/generate-video \
  -H "Content-Type: application/json" \
  -d '{
    "theme": "品质保证",
    "duration": 20
  }'
```

预期返回：
```json
{
  "task_id": "task_1234567890123",
  "message": "视频生成任务已提交，正在处理中"
}
```

### 查询任务进度

```bash
curl http://tnho-fasteners.com/api/progress/task_1234567890123
```

---

## 🔧 常用命令

### 服务管理

```bash
# 查看日志
docker-compose logs -f

# 查看特定服务日志
docker-compose logs -f app
docker-compose logs -f db

# 重启服务
docker-compose restart

# 停止服务
docker-compose down

# 停止并删除数据卷
docker-compose down -v

# 查看容器状态
docker-compose ps

# 进入容器
docker exec -it tnho-video-api bash
```

### 代码更新

```bash
# 拉取最新代码
git pull origin main

# 重新构建并启动
docker-compose up -d --build

# 或者使用部署脚本
./scripts/deploy_from_github.sh
```

### 数据库操作

```bash
# 进入数据库容器
docker exec -it tnho-video-db bash

# 连接数据库
psql -U postgres -d tnho_video

# 查看所有表
\dt

# 退出
\q
```

---

## 🐛 故障排查

### 问题 1: 无法克隆仓库

**错误信息**: `Permission denied (publickey)`

**解决方案**:
1. 检查 SSH 密钥是否存在: `ls -la ~/.ssh/`
2. 生成 SSH 密钥: `ssh-keygen -t ed25519`
3. 将公钥添加到 GitHub
4. 测试连接: `ssh -T git@github.com`

### 问题 2: 服务启动失败

**错误信息**: 容器无法启动

**解决方案**:
```bash
# 查看详细日志
docker-compose logs

# 检查端口占用
netstat -tlnp | grep 8000

# 检查配置文件
cat .env

# 重新构建
docker-compose build --no-cache
docker-compose up -d
```

### 问题 3: API 返回 500 错误

**解决方案**:
```bash
# 查看应用日志
docker-compose logs app

# 进入容器调试
docker exec -it tnho-video-api bash

# 检查环境变量
env | grep ARK
```

### 问题 4: 数据库连接失败

**错误信息**: `could not connect to server`

**解决方案**:
```bash
# 检查数据库容器
docker ps | grep postgres

# 检查数据库日志
docker-compose logs db

# 测试数据库连接
docker exec -it tnho-video-db psql -U postgres -d tnho_video
```

---

## 📊 监控和日志

### 日志位置

```bash
# Docker 日志
docker-compose logs app

# 应用日志文件
ls -lh logs/

# Nginx 访问日志
tail -f /var/log/nginx/access.log

# Nginx 错误日志
tail -f /var/log/nginx/error.log
```

### 性能监控

```bash
# 查看容器资源使用
docker stats

# 查看系统资源
top
htop
```

---

## 🔄 更新和回滚

### 更新代码

```bash
cd /root/tnho-video

# 备份当前版本
git tag backup-$(date +%Y%m%d-%H%M%S)

# 拉取最新代码
git pull origin main

# 重新部署
./scripts/deploy_from_github.sh
```

### 回滚到之前版本

```bash
# 查看标签
git tag

# 回滚到指定标签
git checkout backup-20250113-170000

# 重新部署
docker-compose down
docker-compose build
docker-compose up -d
```

---

## 📞 技术支持

如遇到问题，请提供以下信息：

1. 错误信息截图
2. 相关日志输出
3. 系统环境信息:
   ```bash
   uname -a
   docker --version
   docker-compose --version
   ```
