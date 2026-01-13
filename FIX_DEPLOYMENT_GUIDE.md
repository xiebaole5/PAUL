# 天虹视频生成服务 - 修复部署指南

## 问题描述

服务处于 `Restarting` 状态，无法正常启动。主要原因：
1. 模块导入错误（`storage.memory` 相关）
2. 数据库连接依赖问题
3. 火山方舟 API 配置问题

## 已实施的修复

### 1. 修复 `src/storage/database/db.py`
**问题**：强制依赖 `coze_workload_identity` 模块，该模块可能未安装或不可用

**修复**：将 `coze_workload_identity` 改为可选导入，失败时只从环境变量读取配置

```python
# 修复前
from coze_workload_identity import Client
try:
    client = Client()
    env_vars = client.get_project_env_vars()
    ...
except Exception as e:
    logger.error(f"Error loading PGDATABASE_URL: {e}")
    raise e

# 修复后
try:
    from coze_workload_identity import Client
    client = Client()
    env_vars = client.get_project_env_vars()
    ...
except ImportError:
    logger.debug("coze_workload_identity not available, using only environment variables")
except Exception as e:
    logger.warning(f"Error loading PGDATABASE_URL from coze_workload_identity: {e}")
```

### 2. 修复 `src/agents/agent.py`
**问题**：API Key 配置来源单一，未考虑自定义配置

**修复**：优先从自定义环境变量读取 API Key 和 Base URL，提供更大的灵活性

```python
# 修复前
api_key = os.getenv("COZE_WORKLOAD_IDENTITY_API_KEY")
base_url = os.getenv("COZE_INTEGRATION_MODEL_BASE_URL")

# 修复后
api_key = os.getenv("ARK_API_KEY") or os.getenv("COZE_WORKLOAD_IDENTITY_API_KEY")
base_url = os.getenv("ARK_BASE_URL") or os.getenv("COZE_INTEGRATION_MODEL_BASE_URL", "https://ark.cn-beijing.volces.com/api/v3")
```

### 3. 配置文件优化
**新增**：`.env` 文件配置火山方舟 API

```bash
# 火山方舟 API 配置
ARK_API_KEY=e1533511-efae-4131-aea9-b573a1be4ecf
ARK_BASE_URL=https://ark.cn-beijing.volces.com/api/v3

# 数据库配置（可选，不配置将使用内存存储）
# PGDATABASE_URL=postgresql://user:password@localhost:5432/dbname

# 外部访问地址
EXTERNAL_BASE_URL=http://47.110.72.148
```

### 4. 创建辅助脚本
- `fix_and_redeploy.sh`：完整修复和重新部署脚本
- `quick_fix.sh`：快速修复脚本（不重新构建镜像）
- `debug_container.sh`：容器诊断脚本

## 快速修复步骤

### 方案一：快速修复（推荐先尝试）

```bash
# 1. 给脚本添加执行权限
chmod +x quick_fix.sh fix_and_redeploy.sh debug_container.sh

# 2. 运行快速修复脚本
bash quick_fix.sh
```

### 方案二：完整重新部署（如果方案一失败）

```bash
# 1. 运行完整修复和重新部署脚本
bash fix_and_redeploy.sh
```

### 方案三：手动修复（需要更多操作）

```bash
# 1. 停止容器
docker-compose down

# 2. 重新构建镜像
docker-compose build --no-cache

# 3. 启动容器
docker-compose up -d

# 4. 查看日志
docker-compose logs -f tnho-video-api
```

## 验证服务是否正常

### 1. 检查容器状态
```bash
docker-compose ps
```
期望输出：
```
tnho-nginx       Up    0.0.0.0:80->80/tcp
tnho-video-api   Up    0.0.0.0:8000->8000/tcp  # 应该是 Up 状态
```

### 2. 检查健康状态
```bash
curl http://localhost:8000/health
```
期望输出：
```json
{"status":"ok"}
```

### 3. 访问 API 文档
浏览器访问：`http://47.110.72.148/docs`

## 故障排查

### 问题 1：容器仍然处于 Restarting 状态

**诊断**：
```bash
# 查看实时日志
docker-compose logs -f tnho-video-api

# 运行诊断脚本
bash debug_container.sh
```

**可能原因**：
- Python 依赖未正确安装
- 环境变量配置错误
- 端口冲突

**解决方案**：
```bash
# 进入容器检查
docker-compose exec tnho-video-api bash

# 检查 Python 环境
python --version
pip list | grep -E "(langchain|langgraph|coze)"

# 手动测试导入
python -c "from agents.agent import build_agent; print('OK')"
```

### 问题 2：健康检查失败

**诊断**：
```bash
# 检查服务是否真正启动
curl -v http://localhost:8000/health

# 查看容器内进程
docker-compose exec tnho-video-api ps aux
```

**解决方案**：
- 检查端口 8000 是否被占用
- 检查 uvicorn 进程是否正常运行

### 问题 3：数据库连接错误

**症状**：日志中出现 "Database connection failed"

**解决方案**：
由于已经修复了 db.py，服务会自动降级到使用 MemorySaver（内存存储），这不影响核心功能。

如果需要使用 PostgreSQL：
1. 确保 `.env` 中配置了 `PGDATABASE_URL`
2. 确保数据库服务可访问
3. 检查数据库用户权限

### 问题 4：火山方舟 API 调用失败

**症状**：视频生成失败，提示 API 错误

**检查**：
```bash
# 检查环境变量
docker-compose exec tnho-video-api env | grep ARK

# 测试 API 连接
docker-compose exec tnho-video-api python -c "
import os
from openai import OpenAI

client = OpenAI(
    api_key=os.getenv('ARK_API_KEY'),
    base_url=os.getenv('ARK_BASE_URL')
)
response = client.chat.completions.create(
    model='doubao-1.8',
    messages=[{'role': 'user', 'content': 'test'}],
    max_tokens=10
)
print('API 连接正常')
"
```

## 常用命令

```bash
# 查看容器状态
docker-compose ps

# 查看实时日志
docker-compose logs -f tnho-video-api

# 查看最近 N 行日志
docker-compose logs --tail=50 tnho-video-api

# 重启 API 容器
docker-compose restart tnho-video-api

# 停止所有服务
docker-compose down

# 启动所有服务
docker-compose up -d

# 进入容器
docker-compose exec tnho-video-api bash

# 重新构建并启动
docker-compose up -d --build

# 清理所有容器和镜像
docker-compose down -v --rmi all
```

## 技术架构

### 目录结构
```
/app/
├── src/
│   ├── agents/          # Agent 逻辑
│   ├── api/             # FastAPI 接口
│   ├── storage/         # 数据存储
│   └── tools/           # 工具定义
├── config/              # 配置文件
├── assets/              # 资源文件
└── logs/                # 日志文件
```

### 环境变量
- `COZE_WORKSPACE_PATH`：工作目录（默认：/app）
- `PYTHONPATH`：Python 模块搜索路径（/app:/app/src）
- `ARK_API_KEY`：火山方舟 API Key
- `ARK_BASE_URL`：火山方舟 Base URL
- `EXTERNAL_BASE_URL`：外部访问地址

### 核心依赖
- `langchain`：1.0.3
- `langgraph`：1.0.2
- `langchain-openai`：1.0.1
- `langgraph-checkpoint-postgres`：3.0.1
- `fastapi`：0.121.2
- `uvicorn`：0.38.0

## 联系支持

如果以上步骤都无法解决问题，请提供以下信息：
1. 容器状态：`docker-compose ps`
2. 完整日志：`docker-compose logs --tail=100 tnho-video-api`
3. 诊断结果：`bash debug_container.sh`

## 附录：API 接口说明

### 1. 健康检查
```
GET /health
```

### 2. 上传图片
```
POST /api/upload-image
Content-Type: multipart/form-data

参数：
- file: 图片文件（JPG/PNG，最大 5MB）
```

### 3. 生成视频
```
POST /api/generate-video
Content-Type: application/json

{
  "product_name": "高强度螺栓",
  "theme": "品质保证",
  "duration": 20,
  "type": "video",
  "scenario": "用于汽车制造",
  "product_image_url": "http://..."
}
```

### 4. 查询任务状态
```
GET /api/task-status/{task_id}
```
