# 快速部署命令列表

## 一键部署（推荐）

```bash
cd /root/tnho-video-generator

# 执行完整部署脚本
bash full_deployment.sh
```

## 手动部署步骤

### 1. 配置环境变量
```bash
cd /root/tnho-video-generator

cat > .env << 'EOF'
ARK_API_KEY=e1533511-efae-4131-aea9-b573a1be4ecf
ARK_BASE_URL=https://ark.cn-beijing.volces.com/api/v3
EXTERNAL_BASE_URL=https://tnho-fasteners.com
EOF
```

### 2. 验证文件
```bash
# 检查 agent.py
grep "from.*memory_saver" src/agents/agent.py

# 检查 app.py
grep -A 5 "添加项目根目录" src/api/app.py

# 检查 Dockerfile
grep "PYTHONPATH" Dockerfile
```

### 3. 重新构建
```bash
docker-compose down
docker-compose build --no-cache
```

### 4. 启动服务
```bash
docker-compose up -d
sleep 30
```

### 5. 检查状态
```bash
docker-compose ps
docker-compose logs --tail=50
curl http://localhost:8000/health
```

## 快速诊断命令

### 检查容器状态
```bash
docker-compose ps
```

### 查看 API 日志
```bash
docker-compose logs --tail=50 tnho-video-api
```

### 进入容器检查
```bash
docker-compose exec tnho-video-api /bin/bash

# 在容器内执行
echo $PYTHONPATH
ls -la /app/src/storage/memory/
python -c "from storage.memory.memory_saver import get_memory_saver; print('OK')"
```

### 测试 Python 导入
```bash
docker-compose exec tnho-video-api python -c "from storage.memory.memory_saver import get_memory_saver; print('导入成功')"
```

### 检查环境变量
```bash
docker-compose exec tnho-video-api env | grep -E "ARK|COZE"
```

## 服务管理命令

### 重启服务
```bash
docker-compose restart
```

### 停止服务
```bash
docker-compose down
```

### 查看实时日志
```bash
docker-compose logs -f
```

## 常见修复命令

### 修复 agent.py 导入语句
```bash
sed -i 's/from src\.storage\.memory\.memory_saver import/from storage.memory.memory_saver import/' src/agents/agent.py
```

### 重新构建镜像
```bash
docker-compose build --no-cache
```

### 强制重启
```bash
docker-compose down
docker-compose up -d --force-recreate
```

## 测试命令

### 测试健康检查
```bash
curl http://localhost:8000/health
```

### 测试 API 根路径
```bash
curl http://localhost:8000/
```

### 测试 Agent 响应
```bash
curl -X POST http://localhost:8000/agent/message \
  -H "Content-Type: application/json" \
  -d '{
    "message": "你好",
    "session_id": "test"
  }'
```

### 测试脚本生成
```bash
curl -X POST http://localhost:8000/api/generate-video \
  -H "Content-Type: application/json" \
  -d '{
    "product_name": "高强度螺栓",
    "theme": "品质保证",
    "duration": 20,
    "type": "script"
  }'
```

## 系统检查命令

### 检查 Docker 状态
```bash
docker ps -a
docker images
```

### 检查磁盘空间
```bash
df -h
```

### 检查内存使用
```bash
free -h
```

### 检查端口占用
```bash
netstat -tlnp | grep -E "80|8000"
```

## 清理命令

### 清理未使用的镜像
```bash
docker image prune -f
```

### 清理未使用的容器
```bash
docker container prune -f
```

### 完全清理（包括网络和卷）
```bash
docker-compose down -v
```

## 日志命令

### 查看最近 50 行日志
```bash
docker-compose logs --tail=50
```

### 查看最近 100 行日志
```bash
docker-compose logs --tail=100
```

### 实时跟踪日志
```bash
docker-compose logs -f
```

### 只查看 API 服务日志
```bash
docker-compose logs -f tnho-video-api
```

### 查看特定时间的日志
```bash
docker-compose logs --since 2025-01-12T10:00:00
```
