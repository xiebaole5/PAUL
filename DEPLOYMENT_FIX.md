# 修复部署说明

## 问题根源

服务器部署失败的根本原因是 Python 模块导入路径配置问题：

1. **Dockerfile**：虽然已添加 `PYTHONPATH=/app:/app/src`，但需要确保镜像使用修改后的 Dockerfile
2. **app.py**：sys.path 的设置必须在所有导入语句之前，否则导入 agents.agent 时路径还未设置
3. **agent.py**：导入语句应该使用 `from storage.memory.memory_saver import get_memory_saver`（不带 src. 前缀）

## 已完成的修复

1. ✅ 修改 `src/api/app.py`：将 sys.path 设置移到导入语句之前
2. ✅ 修改 `src/agents/agent.py`：使用正确的导入语句（不带 src. 前缀）
3. ✅ 验证 `Dockerfile`：包含正确的 PYTHONPATH 配置

## 服务器部署步骤

请按以下步骤在服务器（47.110.72.148）上执行：

### 步骤 1：进入项目目录

```bash
cd /root/tnho-video-generator
```

### 步骤 2：验证修复（可选）

检查关键文件是否正确：

```bash
# 检查 Dockerfile
grep "PYTHONPATH" Dockerfile

# 检查 agent.py
grep "from.*memory_saver" src/agents/agent.py

# 检查 app.py（查看前 20 行，确保 sys.path 在导入之前）
head -20 src/api/app.py
```

预期输出：
- Dockerfile 应显示：`PYTHONPATH=/app:/app/src`
- agent.py 应显示：`from storage.memory.memory_saver import get_memory_saver`
- app.py 应显示 sys.path 设置在 from agents.agent 之前

### 步骤 3：停止并清理现有容器

```bash
docker-compose down
```

### 步骤 4：重新构建镜像（重要！）

```bash
docker-compose build --no-cache
```

**注意**：`--no-cache` 参数确保使用修改后的 Dockerfile 重新构建

### 步骤 5：启动服务

```bash
docker-compose up -d
```

### 步骤 6：等待服务启动（30秒）

```bash
sleep 30
```

### 步骤 7：检查容器状态

```bash
docker-compose ps
```

预期输出：
```
tnho-video-api   Up (health: starting)   0.0.0.0:8000->8000/tcp
tnho-nginx       Up                       0.0.0.0:80->80/tcp
```

### 步骤 8：查看容器日志

```bash
docker-compose logs --tail=30
```

**成功标志**：
- ✅ 没有 `ModuleNotFoundError` 错误
- ✅ 显示 `INFO:     Started server process` 或类似启动消息
- ✅ 健康检查状态为 `healthy` 而不是 `health: starting`

### 步骤 9：测试健康检查

```bash
curl http://localhost:8000/health
```

预期输出：
```json
{"status":"ok"}
```

### 步骤 10：测试 API 根路径

```bash
curl http://localhost:8000/
```

预期输出：
```json
{
  "status": "running",
  "service": "天虹紧固件视频生成 API",
  "version": "1.0.0"
}
```

## 常见问题排查

### 问题 1：仍然出现 ModuleNotFoundError

**原因**：镜像没有使用修改后的 Dockerfile

**解决**：
```bash
# 强制重新构建
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### 问题 2：容器启动失败

**排查步骤**：
```bash
# 查看完整日志
docker-compose logs --tail=100

# 进入容器内部检查
docker-compose exec tnho-video-api /bin/bash

# 在容器内检查 PYTHONPATH
echo $PYTHONPATH

# 在容器内检查文件结构
ls -la /app/src/
ls -la /app/src/storage/
```

### 问题 3：健康检查一直失败

**检查服务是否真正启动**：
```bash
# 查看容器内部进程
docker-compose exec tnho-video-api ps aux

# 直接在容器内测试 Python 导入
docker-compose exec tnho-video-api python -c "from storage.memory.memory_saver import get_memory_saver; print('OK')"
```

### 问题 4：导入仍然失败

**手动测试导入**：
```bash
# 进入容器
docker-compose exec tnho-video-api /bin/bash

# 测试 sys.path
python -c "import sys; print('\n'.join(sys.path))"

# 测试导入
python -c "from storage.memory.memory_saver import get_memory_saver; print('导入成功')"
```

如果导入成功，说明环境配置正确。如果失败，检查：
1. `/app/src/` 目录是否存在
2. `/app/src/storage/memory/memory_saver.py` 文件是否存在
3. PYTHONPATH 环境变量是否正确

## 成功部署后的验证

### 验证 API 功能

1. **健康检查**：
```bash
curl http://localhost:8000/health
```

2. **测试视频生成接口**（需要 API Key 配置）：
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

3. **查看实时日志**：
```bash
docker-compose logs -f
```

## 维护命令

```bash
# 查看所有容器状态
docker-compose ps

# 查看服务日志
docker-compose logs -f tnho-video-api

# 重启服务
docker-compose restart

# 停止服务
docker-compose down

# 完全清理（包括网络）
docker-compose down -v

# 更新代码后重新部署
git pull
docker-compose build
docker-compose up -d
```

## 文件变更总结

本次修复涉及的文件：

1. **src/api/app.py**
   - 将 sys.path.insert() 移到所有导入语句之前
   - 确保在导入 agents.agent 之前正确设置 Python 路径

2. **src/agents/agent.py**
   - 使用 `from storage.memory.memory_saver import get_memory_saver`（不带 src. 前缀）

3. **Dockerfile**
   - 包含 `PYTHONPATH=/app:/app/src` 环境变量配置

这些修改确保了容器内的 Python 环境能够正确找到所有模块。
