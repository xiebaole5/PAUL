# 模块导入错误修复报告

## 问题描述

服务容器 `tnho-video-api` 一直处于 `Restarting` 状态，无法正常启动。

**错误日志**：
```
ModuleNotFoundError: No module named 'storage.memory'
  File "/app/src/agents/agent.py", line 9, in <module>
    from storage.memory.memory_saver import get_memory_saver
```

## 根本原因

1. **模块导入路径问题**
   - 原启动命令：`uvicorn src.api.app:app --host 0.0.0.0 --port 8000`
   - 工作目录：`/app`
   - 导入语句：`from storage.memory.memory_saver import get_memory_saver`
   - 问题：Python 无法从 sys.path 找到 `storage` 模块（位于 `/app/src/storage/`）

2. **工作目录配置不当**
   - uvicorn 从 `/app` 启动，但 `storage` 模块在 `/app/src/storage/`
   - 虽然 PYTHONPATH 设置了 `/app:/app/src`，但实际运行时可能未生效

## 修复方案

### 1. 修改 Dockerfile 启动配置

**变更前**：
```dockerfile
CMD ["uvicorn", "src.api.app:app", "--host", "0.0.0.0", "--port", "8000"]
```

**变更后**：
```dockerfile
WORKDIR /app/src
CMD ["uvicorn", "api.app:app", "--host", "0.0.0.0", "--port", "8000"]
```

**说明**：
- 将工作目录切换到 `/app/src`
- uvicorn 启动命令从 `src.api.app:app` 改为 `api.app:app`
- 这样 Python 导入时就能直接找到 `storage` 模块

### 2. 修复 app.py 中的路径配置

**变更 1：静态文件路径**
```python
# 修复前
assets_path = Path("/workspace/projects/assets")

# 修复后
assets_path = Path("/app/assets")
```

**变更 2：上传目录路径**
```python
# 修复前
upload_dir = Path("/workspace/projects/assets/uploads")

# 修复后
upload_dir = Path("/app/assets/uploads")
```

### 3. 优化 agent.py 的导入

**变更**：
```python
# 添加 sys.path 设置确保万无一失
import sys
sys.path.insert(0, '/app/src')
from storage.memory.memory_saver import get_memory_saver
```

## 立即执行修复

### 方式一：运行修复脚本（推荐）

```bash
# 添加执行权限
chmod +x fix_module_import.sh

# 运行修复脚本
bash fix_module_import.sh
```

### 方式二：手动执行修复步骤

```bash
# 1. 停止所有容器
docker-compose down

# 2. 重新构建镜像
docker-compose build --no-cache

# 3. 启动容器
docker-compose up -d

# 4. 查看日志
docker-compose logs -f api
```

## 验证修复

### 1. 检查容器状态
```bash
docker-compose ps
```
期望输出：
```
tnho-nginx       Up    0.0.0.0:80->80/tcp
tnho-video-api   Up    0.0.0.0:8000->8000/tcp  # 应该是 Up 状态
```

### 2. 测试健康检查
```bash
curl http://localhost:8000/health
```
期望输出：
```json
{"status":"ok"}
```

### 3. 访问 API 文档
浏览器打开：http://47.110.72.148/docs

### 4. 测试脚本生成接口
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

## 技术细节

### 文件变更列表

| 文件 | 变更类型 | 说明 |
|------|----------|------|
| `Dockerfile` | 修改 | 添加 WORKDIR /app/src，修改启动命令 |
| `src/agents/agent.py` | 修改 | 添加 sys.path 设置 |
| `src/api/app.py` | 修改 | 修复 assets 路径配置 |
| `docker-compose.yml` | 修改 | 添加 config 目录挂载 |

### 目录结构

```
/app/
├── src/              # 源代码目录（新的 WORKDIR）
│   ├── agents/       # Agent 逻辑
│   ├── api/          # FastAPI 接口
│   ├── storage/      # 数据存储
│   └── tools/        # 工具定义
├── config/           # 配置文件（挂载到 /app/config）
├── assets/           # 资源文件（挂载到 /app/assets）
└── logs/             # 日志文件
```

### 环境变量

| 环境变量 | 值 | 说明 |
|----------|-----|------|
| COZE_WORKSPACE_PATH | /app | 工作目录 |
| PYTHONPATH | /app:/app/src | Python 模块搜索路径 |
| ARK_API_KEY | e1533511-efae-4131-aea9-b573a1be4ecf | 火山方舟 API Key |
| ARK_BASE_URL | https://ark.cn-beijing.volces.com/api/v3 | 火山方舟 Base URL |
| EXTERNAL_BASE_URL | https://tnho-fasteners.com | 外部访问地址 |

## 常见问题

### Q1: 修复后仍然无法启动

**检查步骤**：
```bash
# 查看最新日志
docker-compose logs --tail=100 api

# 查看实时日志
docker-compose logs -f api

# 进入容器检查
docker exec -it tnho-video-api bash

# 在容器内检查 Python 环境
python -c "import sys; print(sys.path)"
python -c "from storage.memory.memory_saver import get_memory_saver; print('OK')"
```

### Q2: 健康检查返回 500 错误

**可能原因**：
- 配置文件读取失败
- 火山方舟 API Key 配置错误
- 网络连接问题

**排查方法**：
```bash
# 检查配置文件是否存在
docker exec -it tnho-video-api ls -la /app/config/

# 检查环境变量
docker exec -it tnho-video-api env | grep ARK

# 查看完整错误日志
docker-compose logs api | grep -A 10 "error\|Error\|ERROR"
```

### Q3: 如何完全重置服务

```bash
# 停止并删除所有容器
docker-compose down

# 删除镜像
docker rmi tnho-video-generator_api:latest

# 重新构建和启动
docker-compose build --no-cache
docker-compose up -d
```

## 后续优化建议

1. **监控和告警**
   - 配置日志收集（如 ELK）
   - 设置健康检查失败的告警

2. **性能优化**
   - 根据实际负载调整容器资源限制
   - 考虑使用 Gunicorn 替代 Uvicorn（更高性能）

3. **安全加固**
   - 使用 HTTPS（SSL 证书）
   - 配置 API 访问限流
   - 定期更新依赖包

4. **备份策略**
   - 定期备份 assets 目录
   - 备份配置文件和 .env

## 联系支持

如果遇到本文档未涵盖的问题，请提供：
1. 容器状态：`docker-compose ps`
2. 最新日志：`docker-compose logs --tail=100 api`
3. 错误信息截图

---

**修复日期**: 2025-01-XX
**修复版本**: v1.2.0
**状态**: 已完成修复，等待验证
