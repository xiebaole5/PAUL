# 轻量部署方案 - 服务器手动部署指南

由于服务器配置较低（2核/1.6GB/磁盘IO受限），采用轻量部署方案：
- **数据库**：使用 Docker 容器运行 PostgreSQL
- **应用**：直接使用 Python 运行（不使用 Docker）

## 前提条件

1. 服务器已安装 Docker
2. 服务器已安装 Git
3. 有 root 权限

## 部署步骤

### 步骤 1: 安装系统依赖

```bash
# 安装必要的系统包
apt-get update
apt-get install -y python3-venv python3-dev libpq-dev ffmpeg postgresql-client git
```

### 步骤 2: 克隆或更新代码

```bash
# 进入工作目录
cd /root

# 如果是首次部署，克隆代码
git clone https://github.com/xiebaole5/PAUL.git tnho-video

# 如果已存在，更新代码
cd /root/tnho-video
git pull
```

### 步骤 3: 创建 Python 虚拟环境

```bash
cd /root/tnho-video

# 创建虚拟环境
python3 -m venv venv

# 激活虚拟环境
source venv/bin/activate

# 升级 pip
pip install --upgrade pip -i https://mirrors.aliyun.com/pypi/simple/
```

### 步骤 4: 安装 Python 依赖

```bash
# 确保虚拟环境已激活
source venv/bin/activate

# 安装依赖包（使用阿里云镜像源）
pip install -r requirements.txt -i https://mirrors.aliyun.com/pypi/simple/
```

### 步骤 5: 配置 .env 文件

```bash
cd /root/tnho-video

# 创建 .env 文件
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
PGDATABASE_URL=postgresql://postgres:postgres123@localhost:5432/tnho_video

# 应用配置
APP_HOST=0.0.0.0
APP_PORT=8000
LOG_LEVEL=info
EOF

# 修改配置
nano .env
# 或
vim .env
```

**必须修改的配置项：**
- `S3_ACCESS_KEY_ID`: 你的火山引擎对象存储访问密钥 ID
- `S3_SECRET_ACCESS_KEY`: 你的火山引擎对象存储访问密钥
- `S3_BUCKET`: 你的存储桶名称

### 步骤 6: 启动数据库容器

```bash
# 停止旧容器（如果存在）
docker stop tnho-db 2>/dev/null || true
docker rm tnho-db 2>/dev/null || true

# 启动新容器
docker run -d \
  --name tnho-db \
  -e POSTGRES_DB=tnho_video \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres123 \
  -p 5432:5432 \
  postgres:15-alpine

# 等待数据库启动
sleep 10

# 检查数据库状态
docker ps | grep tnho-db

# 测试数据库连接
docker exec -it tnho-db psql -U postgres -c "SELECT 1;"
```

### 步骤 7: 初始化数据库表

```bash
cd /root/tnho-video
source venv/bin/activate

# 初始化数据库
python3 -c "
import sys
sys.path.insert(0, '.')
from src.storage.database.init_db import init_db
init_db()
print('数据库初始化完成')
"
```

### 步骤 8: 启动应用服务

```bash
cd /root/tnho-video

# 确保虚拟环境已激活
source venv/bin/activate

# 创建日志目录
mkdir -p logs

# 停止旧服务（如果存在）
pkill -f "uvicorn" || true

# 启动服务（后台运行）
nohup venv/bin/python -m uvicorn app:app --host 0.0.0.0 --port 8000 > logs/app.log 2>&1 &

# 记录 PID
echo $! > logs/app.pid

# 等待服务启动
sleep 10

# 检查服务状态
curl http://localhost:8000/health
```

### 步骤 9: 验证部署

```bash
# 测试健康检查
curl http://localhost:8000/health

# 测试 API 文档
curl http://localhost:8000/docs

# 查看应用日志
tail -f logs/app.log

# 查看进程状态
ps aux | grep uvicorn
```

## 常用管理命令

### 查看日志
```bash
tail -f /root/tnho-video/logs/app.log
```

### 重启服务
```bash
cd /root/tnho-video
pkill -f uvicorn
source venv/bin/activate
nohup venv/bin/python -m uvicorn app:app --host 0.0.0.0 --port 8000 > logs/app.log 2>&1 &
```

### 停止服务
```bash
pkill -f uvicorn
```

### 更新代码
```bash
cd /root/tnho-video
source venv/bin/activate
git pull
pip install -r requirements.txt -i https://mirrors.aliyun.com/pypi/simple/
pkill -f uvicorn
nohup venv/bin/python -m uvicorn app:app --host 0.0.0.0 --port 8000 > logs/app.log 2>&1 &
```

### 查看数据库状态
```bash
docker ps | grep tnho-db
docker logs -f tnho-db
```

### 连接数据库
```bash
docker exec -it tnho-db psql -U postgres -d tnho_video
```

## Nginx 配置

确保 Nginx 反向代理已配置：
- 文件：`/etc/nginx/conf.d/tnho-api.conf`
- 监听端口：80（HTTP）和 443（HTTPS）
- 代理到：`http://127.0.0.1:8000`

测试 Nginx 配置：
```bash
nginx -t
nginx -s reload
```

## 故障排查

### 服务无法启动
```bash
# 查看日志
tail -n 100 /root/tnho-video/logs/app.log

# 检查端口占用
netstat -tlnp | grep 8000

# 手动测试启动
cd /root/tnho-video
source venv/bin/activate
python -m uvicorn app:app --host 0.0.0.0 --port 8000
```

### 数据库连接失败
```bash
# 检查数据库容器
docker ps | grep tnho-db

# 测试连接
docker exec -it tnho-db psql -U postgres -c "SELECT 1;"

# 查看数据库日志
docker logs tnho-db
```

### 端口被占用
```bash
# 查找占用进程
lsof -i:8000

# 杀死进程
kill -9 <PID>
```

## 性能优化建议

由于服务器配置较低，建议：
1. **限制并发数**：在 `app.py` 中配置适当的并发限制
2. **日志轮转**：配置 logrotate 避免日志文件过大
3. **定期清理**：清理临时文件和旧日志
4. **监控资源**：使用 `htop` 监控 CPU 和内存使用

## 备份策略

### 数据库备份
```bash
# 备份数据库
docker exec tnho-db pg_dump -U postgres tnho_video > backup_$(date +%Y%m%d).sql

# 恢复数据库
docker exec -i tnho-db psql -U postgres tnho_video < backup_20250101.sql
```

### 代码备份
```bash
# 使用 Git 进行版本控制
git add .
git commit -m "backup"
git push origin main
```
