# 天虹紧固件视频生成服务 - 完整部署指南

## 概述

本指南提供天虹紧固件产品宣传短视频生成服务的完整部署步骤，包括：
- 火山方舟 API 配置
- 模块导入问题修复
- Docker 容器化部署
- 服务验证

## 前置条件

- 服务器：阿里云 ECS (47.110.72.148)
- Docker 和 Docker Compose 已安装
- 火山方舟 API Key: `e1533511-efae-4131-aea9-b573a1be4ecf`
- 推理接入点: `doubao-1.8`

## 已完成的修复

### 1. 模块导入问题

- ✅ **src/api/app.py**: 修复 sys.path 设置，同时添加 `/app` 和 `/app/src`
- ✅ **src/agents/agent.py**: 修正导入语句，使用 `from storage.memory.memory_saver import get_memory_saver`
- ✅ **Dockerfile**: 添加 `PYTHONPATH=/app:/app/src` 环境变量

### 2. API 配置

- ✅ **.env**: 配置火山方舟 API Key
- ✅ **requirements.txt**: 添加 `volcenginesdkarkruntime==1.0.6`
- ✅ **docker-compose.yml**: 环境变量映射正确配置

## 部署步骤

### 步骤 1: 准备文件

确保服务器上的以下文件与本地版本一致：

**方法 1: 使用 Git 同步**
```bash
cd /root/tnho-video-generator
git pull origin main
```

**方法 2: 手动上传文件**
需要上传/更新的文件：
- `src/api/app.py`
- `src/agents/agent.py`
- `Dockerfile`
- `requirements.txt`
- `config/agent_llm_config.json`
- `.env`

### 步骤 2: 配置环境变量

```bash
cd /root/tnho-video-generator

# 创建或更新 .env 文件
cat > .env << 'EOF'
ARK_API_KEY=e1533511-efae-4131-aea9-b573a1be4ecf
ARK_BASE_URL=https://ark.cn-beijing.volces.com/api/v3
EXTERNAL_BASE_URL=https://tnho-fasteners.com
EOF

# 验证配置
cat .env
```

### 步骤 3: 验证关键文件

```bash
# 检查 agent.py 导入语句（应该没有 src. 前缀）
grep "from.*memory_saver" src/agents/agent.py

# 预期输出：
# from storage.memory.memory_saver import get_memory_saver

# 检查 app.py sys.path 设置
grep -A 5 "添加项目根目录" src/api/app.py

# 预期输出包含：
# if workspace_path not in sys.path:
#     sys.path.insert(0, workspace_path)
# if src_path not in sys.path:
#     sys.path.insert(0, src_path)

# 检查 Dockerfile PYTHONPATH
grep "PYTHONPATH" Dockerfile

# 预期输出：
# PYTHONPATH=/app:/app/src
```

### 步骤 4: 停止现有服务

```bash
docker-compose down
```

### 步骤 5: 重新构建镜像

```bash
docker-compose build --no-cache
```

**注意**: `--no-cache` 确保使用最新的代码和依赖重新构建。

构建过程大约需要 2-5 分钟，包括：
- 安装系统依赖
- 安装 Python 依赖（包括火山方舟 SDK）
- 复制项目文件

### 步骤 6: 启动服务

```bash
docker-compose up -d
```

### 步骤 7: 等待服务启动

```bash
sleep 30
```

服务启动需要一些时间，因为需要：
- 初始化 FastAPI 应用
- 加载 LangChain 和 LangGraph
- 连接火山方舟 API

### 步骤 8: 检查容器状态

```bash
docker-compose ps
```

**预期输出**:
```
NAME              COMMAND                      STATE                    PORTS
tnho-nginx        /docker-entrypoint.sh ngin   Up                      0.0.0.0:80->80/tcp
tnho-video-api    uvicorn src.api.app:app...   Up (health: starting)   0.0.0.0:8000->8000/tcp
```

等待约 60 秒后，状态应变为 `Up (healthy)`。

### 步骤 9: 查看日志

```bash
# 查看最后 50 行日志
docker-compose logs --tail=50

# 实时跟踪日志
docker-compose logs -f
```

**成功标志**:
- ✅ 没有 `ModuleNotFoundError` 错误
- ✅ 显示 `INFO:     Started server process`
- ✅ 显示 `INFO:     Application startup complete`

**错误标志**:
- ❌ `ModuleNotFoundError: No module named 'storage.memory'`
- ❌ `ModuleNotFoundError: No module named 'src.storage.memory'`

### 步骤 10: 测试健康检查

```bash
curl http://localhost:8000/health
```

**预期输出**:
```json
{"status":"ok"}
```

### 步骤 11: 测试 API 根路径

```bash
curl http://localhost:8000/
```

**预期输出**:
```json
{
  "status": "running",
  "service": "天虹紧固件视频生成 API",
  "version": "1.0.0"
}
```

## 常见问题排查

### 问题 1: ModuleNotFoundError: No module named 'storage.memory'

**原因**: sys.path 设置不正确或 PYTHONPATH 环境变量缺失

**解决方案**:
```bash
# 检查 app.py 中的 sys.path 设置
grep -A 10 "添加项目根目录" src/api/app.py

# 确保同时添加了 /app 和 /app/src
# 重新构建
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### 问题 2: ModuleNotFoundError: No module named 'src.storage.memory'

**原因**: agent.py 中使用了错误的导入语句（带 src. 前缀）

**解决方案**:
```bash
# 修复导入语句
sed -i 's/from src\.storage\.memory\.memory_saver import/from storage.memory.memory_saver import/' src/agents/agent.py

# 验证
grep "from.*memory_saver" src/agents/agent.py

# 重新构建
docker-compose build --no-cache
docker-compose up -d
```

### 问题 3: 容器启动失败，日志中显示 ImportError

**原因**: 依赖包未正确安装

**解决方案**:
```bash
# 进入容器检查
docker-compose exec tnho-video-api /bin/bash

# 检查 Python 路径
echo $PYTHONPATH

# 检查文件结构
ls -la /app/src/storage/memory/

# 测试导入
python -c "from storage.memory.memory_saver import get_memory_saver; print('OK')"
```

### 问题 4: API 调用失败，连接超时

**原因**: API Key 配置错误或网络问题

**解决方案**:
```bash
# 检查环境变量
docker-compose exec tnho-video-api env | grep ARK

# 检查 .env 文件
cat .env

# 测试 API 连接
cd /root/tnho-video-generator
python test_ark_api.py
```

### 问题 5: 健康检查一直失败

**原因**: 服务未完全启动或健康检查配置错误

**解决方案**:
```bash
# 查看完整日志
docker-compose logs --tail=100 tnho-video-api

# 进入容器手动测试健康检查
docker-compose exec tnho-video-api curl http://localhost:8000/health

# 检查服务是否真正启动
docker-compose exec tnho-video-api ps aux | grep uvicorn
```

## 服务验证

### 1. 测试 Agent 响应

```bash
curl -X POST http://localhost:8000/agent/message \
  -H "Content-Type: application/json" \
  -d '{
    "message": "你好，请介绍一下天虹紧固件",
    "session_id": "test_001"
  }'
```

### 2. 测试脚本生成

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

### 3. 测试图片上传

```bash
curl -X POST http://localhost:8000/api/upload-image \
  -F "file=@/path/to/your/image.jpg"
```

## 服务管理

### 查看服务状态

```bash
docker-compose ps
```

### 查看日志

```bash
# 实时日志
docker-compose logs -f

# 特定服务日志
docker-compose logs -f tnho-video-api

# 最后 N 行日志
docker-compose logs --tail=100 tnho-video-api
```

### 重启服务

```bash
# 重启所有服务
docker-compose restart

# 重启特定服务
docker-compose restart tnho-video-api
```

### 停止服务

```bash
docker-compose down
```

### 更新代码后重新部署

```bash
# 1. 拉取最新代码
git pull origin main

# 2. 停止服务
docker-compose down

# 3. 重新构建
docker-compose build

# 4. 启动服务
docker-compose up -d

# 5. 查看日志
docker-compose logs -f
```

## 服务地址

部署成功后，可以通过以下地址访问：

- **API 服务**: http://47.110.72.148:8000
- **健康检查**: http://47.110.72.148:8000/health
- **Nginx 代理**: http://47.110.72.148

## API 文档

启动服务后，访问以下地址查看完整 API 文档：

- **Swagger UI**: http://47.110.72.148:8000/docs
- **ReDoc**: http://47.110.72.148:8000/redoc

## 火山方舟 API 配置说明

### 使用 langchain-openai（当前方案）

```python
from langchain_openai import ChatOpenAI

llm = ChatOpenAI(
    model="doubao-1.8",
    api_key=os.getenv("COZE_WORKLOAD_IDENTITY_API_KEY"),
    base_url=os.getenv("COZE_INTEGRATION_MODEL_BASE_URL"),
    temperature=0.7,
)
```

### 使用官方 SDK（备选方案）

```python
from volcenginesdkarkruntime import Ark

client = Ark(
    base_url=os.getenv("ARK_BASE_URL"),
    api_key=os.getenv("ARK_API_KEY"),
)

response = client.chat.completions.create(
    model="doubao-1.8",
    messages=[
        {"role": "user", "content": "你好"}
    ],
)
```

两种方式都已配置在 requirements.txt 中，可以切换使用。

## 下一步

服务成功部署后，还需要：

1. **配置 HTTPS**: 使用 Let's Encrypt 申请 SSL 证书
2. **ICP 备案**: 完成域名备案
3. **配置域名**: 将 tnho-fasteners.com 指向服务器 IP
4. **配置微信小程序**: 在微信小程序后台配置服务器域名
5. **测试完整流程**: 使用微信小程序测试视频生成功能

## 支持

如遇到问题，请提供以下信息：

1. 容器状态：`docker-compose ps`
2. 服务日志：`docker-compose logs --tail=100`
3. 错误信息：完整的错误堆栈
4. 环境变量：`docker-compose exec tnho-video-api env | grep ARK`

---

**文档版本**: v1.0
**最后更新**: 2025-01-12
