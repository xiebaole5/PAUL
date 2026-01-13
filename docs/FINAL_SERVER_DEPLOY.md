# 服务器最终部署指南

## 问题解决

我已经在本地创建了两个缺失的关键文件：
1. **app.py** - 项目根目录的应用入口文件
2. **src/storage/database/init_db.py** - 数据库初始化文件

代码已提交到本地 Git 仓库。

## 步骤 1: 将代码推送到 GitHub

由于推送需要 GitHub 认证，请在本地 PowerShell 中执行：

### 方法 A: 使用 SSH（推荐，已配置 SSH 密钥）

```powershell
# 进入项目目录
cd C:\workspace\projects

# 添加远程仓库（如果还没配置）
git remote add origin git@github.com:xiebaole5/PAUL.git

# 推送到 GitHub
git push origin main
```

### 方法 B: 使用 HTTPS（需要 GitHub Personal Access Token）

```powershell
# 推送时会提示输入用户名和密码
# 用户名：你的 GitHub 用户名
# 密码：GitHub Personal Access Token（不是登录密码）

git push origin main
```

**如何创建 Personal Access Token：**
1. 访问 https://github.com/settings/tokens
2. 点击 "Generate new token" (classic)
3. 勾选 `repo` 权限
4. 点击 "Generate token"
5. 复制生成的 token（只显示一次）
6. 在 git push 时，用户名输入 GitHub 用户名，密码输入这个 token

### 方法 C: 使用 Git Credential Helper

```powershell
# 配置凭证助手
git config --global credential.helper store

# 推送（会提示输入一次）
git push origin main

# 后续推送就不需要再输入凭证了
```

## 步骤 2: 在服务器上重新克隆代码

### 2.1 备份现有配置

```bash
cd /root/tnho-video
cp .env .env.backup
```

### 2.2 删除不完整的代码

```bash
cd /root
rm -rf tnho-video
```

### 2.3 重新克隆完整代码

```bash
cd /root
git clone https://github.com/xiebaole5/PAUL.git tnho-video
cd tnho-video
```

### 2.4 验证代码完整性

```bash
# 检查关键文件是否存在
echo "检查关键文件："
test -f app.py && echo "✅ app.py 存在" || echo "❌ app.py 缺失"
test -f requirements.txt && echo "✅ requirements.txt 存在" || echo "❌ requirements.txt 缺失"
test -f src/storage/database/init_db.py && echo "✅ init_db.py 存在" || echo "❌ init_db.py 缺失"
```

预期结果应该都是 "✅"。

## 步骤 3: 恢复配置并初始化数据库

### 3.1 恢复 .env 配置

```bash
cd /root/tnho-video

# 方法 A: 恢复之前的配置（如果有备份）
cp ../.env.backup .env

# 方法 B: 创建新配置
cat > .env << 'EOF'
# 火山方舟配置
ARK_API_KEY=39bf20d0-55b5-4957-baa1-02f4529a3076
ARK_BASE_URL=https://ark.cn-beijing.volces.com/api/v3

# 对象存储配置
S3_ENDPOINT=https://tos-s3-cn-beijing.volces.com
S3_ACCESS_KEY_ID=your_access_key_id
S3_SECRET_ACCESS_KEY=your_secret_access_key
S3_BUCKET=tnho-videos
S3_REGION=cn-beijing

# 数据库配置
PGDATABASE_URL=postgresql://postgres:postgres123@localhost:5433/tnho_video

# 应用配置
APP_HOST=0.0.0.0
APP_PORT=8000
LOG_LEVEL=info
EOF
```

### 3.2 初始化数据库

```bash
cd /root/tnho-video

# 确保虚拟环境已激活
source venv/bin/activate

# 初始化数据库表
python3 -c "
import sys
sys.path.insert(0, '.')
from src.storage.database.init_db import init_db
init_db()
print('✅ 数据库初始化完成')
"
```

预期输出：
```
✅ 数据库表创建成功
✅ 表 video_generation_tasks 存在
✅ 数据库初始化完成
```

## 步骤 4: 启动应用

```bash
cd /root/tnho-video
source venv/bin/activate

# 创建日志目录
mkdir -p logs

# 停止旧服务
pkill -f uvicorn || true

# 启动服务
nohup venv/bin/python -m uvicorn app:app --host 0.0.0.0 --port 8000 > logs/app.log 2>&1 &

# 记录 PID
echo $! > logs/app.pid

# 等待服务启动
sleep 10
```

## 步骤 5: 验证服务

```bash
# 测试健康检查
curl http://localhost:8000/health

# 测试 API 文档
curl http://localhost:8000/docs

# 查看应用日志
tail -n 50 logs/app.log
```

预期输出：
```
{"status":"ok"}
```

如果健康检查返回 `{"status":"ok"}`，说明服务已成功启动！

## 步骤 6: 公网访问测试

```bash
# 测试公网访问
curl http://tnho-fasteners.com/health

# 测试 API 文档
curl http://tnho-fasteners.com/docs
```

## 常见问题

### Q1: 推送到 GitHub 失败

**问题**：`fatal: could not read Username for 'https://github.com'`

**解决**：
- 使用 SSH 推送：`git push origin main`（需要已配置 SSH 密钥）
- 或使用 Personal Access Token 进行 HTTPS 推送

### Q2: 数据库连接失败

**问题**：`Database connection failed` 或 `PGDATABASE_URL is not set`

**解决**：
1. 检查 .env 文件是否存在并包含 `PGDATABASE_URL`
2. 检查数据库容器是否运行：`docker ps | grep tnho-db`
3. 如果数据库未运行，启动它：
   ```bash
   docker run -d \
     --name tnho-db \
     -e POSTGRES_DB=tnho_video \
     -e POSTGRES_USER=postgres \
     -e POSTGRES_PASSWORD=postgres123 \
     -p 5433:5432 \
     postgres:15-alpine
   ```

### Q3: 应用启动失败

**问题**：`ERROR: Error loading ASGI app. Could not import module "app"`

**解决**：
1. 检查 app.py 是否存在：`ls -la app.py`
2. 检查虚拟环境是否已激活：`which python` 应该指向 `.../venv/bin/python`
3. 查看详细日志：`cat logs/app.log`

### Q4: 服务启动但健康检查失败

**问题**：`curl: (7) Failed to connect to localhost port 8000`

**解决**：
1. 等待更长时间：`sleep 20`
2. 检查进程是否运行：`ps aux | grep uvicorn`
3. 查看日志：`tail -n 100 logs/app.log`
4. 手动启动查看错误：
   ```bash
   source venv/bin/activate
   venv/bin/python -m uvicorn app:app --host 0.0.0.0 --port 8000
   ```

## 验证清单

完成部署后，确认以下项目：

- [ ] app.py 存在于项目根目录
- [ ] src/storage/database/init_db.py 存在
- [ ] .env 文件配置正确
- [ ] 数据库容器运行中（端口 5433）
- [ ] 虚拟环境已激活
- [ ] Python 依赖已安装
- [ ] 数据库初始化成功
- [ ] uvicorn 进程运行中
- [ ] 健康检查返回 `{"status":"ok"}`
- [ ] 公网访问正常：http://tnho-fasteners.com/health

## 后续操作

### 1. 修改对象存储配置

编辑 `.env` 文件，填入真实的 S3 配置：

```bash
nano /root/tnho-video/.env
```

修改以下配置：
- `S3_ACCESS_KEY_ID`: 你的火山引擎对象存储访问密钥 ID
- `S3_SECRET_ACCESS_KEY`: 你的火山引擎对象存储访问密钥
- `S3_BUCKET`: 你的存储桶名称

修改后重启服务：

```bash
cd /root/tnho-video
source venv/bin/activate
pkill -f uvicorn || true
nohup venv/bin/python -m uvicorn app:app --host 0.0.0.0 --port 8000 > logs/app.log 2>&1 &
```

### 2. 测试视频生成功能

使用 API 测试工具或微信小程序测试视频生成功能。

### 3. 监控服务状态

定期检查日志：

```bash
tail -f /root/tnho-video/logs/app.log
```

### 4. 配置日志轮转

创建 `/etc/logrotate.d/tnho-app` 文件：

```
/root/tnho-video/logs/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0644 root root
}
```

## 一键部署脚本（完整流程）

保存为 `/root/deploy_complete.sh`：

```bash
#!/bin/bash
set -e

echo "=========================================="
echo "TNHO 视频生成服务 - 完整部署"
echo "=========================================="
echo ""

# 步骤 1: 备份配置
echo "步骤 1: 备份配置文件..."
cd /root/tnho-video 2>/dev/null && cp .env .env.backup || true

# 步骤 2: 删除旧代码
echo "步骤 2: 删除旧代码..."
cd /root
rm -rf tnho-video

# 步骤 3: 克隆新代码
echo "步骤 3: 从 GitHub 克隆代码..."
git clone https://github.com/xiebaole5/PAUL.git tnho-video
cd tnho-video

# 步骤 4: 恢复配置
echo "步骤 4: 恢复配置文件..."
if [ -f "../.env.backup" ]; then
    cp ../.env.backup .env
else
    cat > .env << 'EOF'
ARK_API_KEY=39bf20d0-55b5-4957-baa1-02f4529a3076
ARK_BASE_URL=https://ark.cn-beijing.volces.com/api/v3
S3_ENDPOINT=https://tos-s3-cn-beijing.volces.com
S3_ACCESS_KEY_ID=your_access_key_id
S3_SECRET_ACCESS_KEY=your_secret_access_key
S3_BUCKET=tnho-videos
S3_REGION=cn-beijing
PGDATABASE_URL=postgresql://postgres:postgres123@localhost:5433/tnho_video
APP_HOST=0.0.0.0
APP_PORT=8000
LOG_LEVEL=info
EOF
    echo "⚠️  请编辑 .env 文件，修改 S3 配置项"
fi

# 步骤 5: 创建虚拟环境
echo "步骤 5: 创建虚拟环境..."
python3 -m venv venv
source venv/bin/activate

# 步骤 6: 安装依赖
echo "步骤 6: 安装 Python 依赖..."
pip install fastapi uvicorn python-multipart \
  langchain langchain-openai langgraph \
  langgraph-checkpoint-postgres \
  openai tiktoken \
  SQLAlchemy psycopg2-binary alembic \
  moviepy imageio-ffmpeg ImageIO opencv-python \
  coze-coding-dev-sdk volcengine-python-sdk boto3 \
  requests httpx python-dotenv pydantic pyyaml \
  APScheduler -i https://mirrors.aliyun.com/pypi/simple/ -q

# 步骤 7: 检查数据库
echo "步骤 7: 检查数据库状态..."
if ! docker ps | grep -q "tnho-db"; then
    echo "启动数据库容器..."
    docker run -d \
      --name tnho-db \
      -e POSTGRES_DB=tnho_video \
      -e POSTGRES_USER=postgres \
      -e POSTGRES_PASSWORD=postgres123 \
      -p 5433:5432 \
      postgres:15-alpine
    sleep 10
else
    echo "数据库容器已运行"
fi

# 步骤 8: 初始化数据库
echo "步骤 8: 初始化数据库..."
python3 -c "
import sys
sys.path.insert(0, '.')
from src.storage.database.init_db import init_db
init_db()
print('✅ 数据库初始化完成')
"

# 步骤 9: 启动应用
echo "步骤 9: 启动应用..."
pkill -f uvicorn || true
mkdir -p logs
nohup venv/bin/python -m uvicorn app:app --host 0.0.0.0 --port 8000 > logs/app.log 2>&1 &

# 步骤 10: 等待启动
echo "步骤 10: 等待服务启动..."
sleep 10

# 步骤 11: 测试服务
echo "步骤 11: 测试服务..."
if curl -f http://localhost:8000/health; then
    echo ""
    echo "=========================================="
    echo "✅ 部署成功！"
    echo "=========================================="
    echo ""
    echo "访问地址："
    echo "  API 文档: http://tnho-fasteners.com/docs"
    echo "  健康检查: http://tnho-fasteners.com/health"
    echo ""
else
    echo ""
    echo "=========================================="
    echo "❌ 部署失败"
    echo "=========================================="
    echo ""
    echo "查看日志："
    echo "  tail -n 100 /root/tnho-video/logs/app.log"
    echo ""
fi
```

执行一键部署：

```bash
chmod +x /root/deploy_complete.sh
bash /root/deploy_complete.sh
```

## 总结

1. **本地操作**：将代码推送到 GitHub
2. **服务器操作**：
   - 删除旧代码
   - 重新克隆完整代码
   - 初始化数据库
   - 启动应用
   - 验证服务

完成这些步骤后，服务应该就能正常运行了！
