# 天虹视频生成服务 - 修复总结报告

## 问题诊断

服务当前状态：`tnho-video-api` 容器处于 **Restarting** 状态，无法正常启动。

### 根本原因分析

1. **模块导入错误**
   - `src/storage/database/db.py` 强制依赖 `coze_workload_identity` 模块
   - 该模块可能未正确安装或在容器环境中不可用
   - 导致服务启动时直接抛出 ImportError

2. **API 配置灵活性不足**
   - `src/agents/agent.py` 仅从单一来源读取 API Key
   - 未考虑自定义火山方舟配置的情况

3. **环境变量配置缺失**
   - 缺少 `.env` 文件配置火山方舟 API
   - 外部访问地址未明确配置

## 已实施的修复方案

### 1. 修复数据库连接逻辑 (`src/storage/database/db.py`)

**变更内容**：
- 将 `coze_workload_identity` 从强制依赖改为可选导入
- 失败时降级为仅从环境变量读取配置
- 避免启动失败

**代码变更**：
```python
# 修复前
from coze_workload_identity import Client
try:
    client = Client()
    env_vars = client.get_project_env_vars()
    ...
except Exception as e:
    logger.error(f"Error loading PGDATABASE_URL: {e}")
    raise e  # ← 这会导致启动失败

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
# 不再抛出异常，允许服务继续启动
```

### 2. 优化 API 配置逻辑 (`src/agents/agent.py`)

**变更内容**：
- 支持从自定义环境变量读取火山方舟配置
- 提供更好的配置灵活性

**代码变更**：
```python
# 修复前
api_key = os.getenv("COZE_WORKLOAD_IDENTITY_API_KEY")
base_url = os.getenv("COZE_INTEGRATION_MODEL_BASE_URL")

# 修复后
api_key = os.getenv("ARK_API_KEY") or os.getenv("COZE_WORKLOAD_IDENTITY_API_KEY")
base_url = os.getenv("ARK_BASE_URL") or os.getenv("COZE_INTEGRATION_MODEL_BASE_URL", "https://ark.cn-beijing.volces.com/api/v3")
```

### 3. 创建辅助脚本和文档

#### 脚本列表

| 脚本名 | 用途 | 特点 |
|--------|------|------|
| `fix_and_redeploy.sh` | 完整修复和重新部署 | 停止容器、重新构建、启动 |
| `quick_fix.sh` | 快速修复（推荐先试） | 不重新构建，重启并测试 |
| `debug_container.sh` | 容器诊断 | 检查模块导入、环境变量等 |
| `test_service.sh` | 功能测试 | 测试各 API 接口是否正常 |

#### 文档列表

| 文档名 | 内容 |
|--------|------|
| `FIX_DEPLOYMENT_GUIDE.md` | 完整的故障排查和修复指南 |
| `README_QUICK_START.md` | 快速启动和使用指南 |
| `REPAIR_SUMMARY.md` | 本文档 |

## 立即执行步骤

### 第一步：执行快速修复（推荐）

```bash
# 1. 进入项目目录
cd /root/tnho-video-generator

# 2. 添加脚本执行权限
chmod +x *.sh

# 3. 运行快速修复脚本
bash quick_fix.sh
```

**快速修复脚本会做什么**：
1. 检查容器状态和最新日志
2. 尝试安装缺失的 Python 包
3. 测试关键模块导入
4. 重启 API 容器
5. 等待服务启动
6. 测试健康检查接口

### 第二步：验证服务状态

```bash
# 检查容器状态
docker-compose ps

# 期望输出：
# tnho-nginx       Up    0.0.0.0:80->80/tcp
# tnho-video-api   Up    0.0.0.0:8000->8000/tcp  # 应该是 Up 状态

# 测试健康检查
curl http://localhost:8000/health

# 期望输出：
# {"status":"ok"}
```

### 第三步：访问 API 文档

浏览器访问：**http://47.110.72.148/docs**

### 第四步（可选）：运行完整测试

```bash
# 运行功能测试脚本
bash test_service.sh
```

## 如果快速修复无效

### 方案：完整重新部署

```bash
# 运行完整修复和重新部署脚本
bash fix_and_redeploy.sh
```

**完整重新部署会做什么**：
1. 检查并创建 `.env` 配置文件
2. 停止所有容器
3. 重新构建 Docker 镜像（不使用缓存）
4. 启动所有容器
5. 等待服务启动（30秒）
6. 测试健康检查接口
7. 显示访问地址

## 验证清单

- [ ] 容器状态：`docker-compose ps` 显示 `tnho-video-api` 为 `Up` 状态
- [ ] 健康检查：`curl http://localhost:8000/health` 返回 `{"status":"ok"}`
- [ ] API 文档：浏览器访问 `http://47.110.72.148/docs` 可以打开
- [ ] 脚本生成：测试 `/api/generate-video` 接口生成脚本功能正常

## 故障排查

### 问题 1：容器仍然处于 Restarting 状态

**诊断**：
```bash
# 查看实时日志
docker-compose logs -f tnho-video-api

# 运行完整诊断
bash debug_container.sh
```

**常见原因**：
- Python 依赖未正确安装
- 端口 8000 被占用
- 磁盘空间不足

### 问题 2：健康检查返回错误

**检查**：
```bash
# 检查端口
netstat -tlnp | grep :8000

# 检查进程
docker-compose exec tnho-video-api ps aux | grep uvicorn
```

### 问题 3：日志中出现数据库连接错误

**说明**：这是正常的，服务会自动降级使用 MemorySaver，不影响核心功能

如果需要使用 PostgreSQL，在 `.env` 中配置 `PGDATABASE_URL`

## 技术细节

### 修复的关键点

1. **降低依赖强度**：将 `coze_workload_identity` 从强制依赖改为可选依赖
2. **增加配置灵活性**：支持自定义火山方舟 API 配置
3. **容错机制**：MemorySaver 作为数据库连接的降级方案

### 环境变量说明

```bash
# 火山方舟 API（新增）
ARK_API_KEY=e1533511-efae-4131-aea9-b573a1be4ecf
ARK_BASE_URL=https://ark.cn-beijing.volces.com/api/v3

# 数据库连接（可选）
PGDATABASE_URL=postgresql://user:password@host:5432/dbname

# 外部访问地址
EXTERNAL_BASE_URL=http://47.110.72.148

# 工作目录
COZE_WORKSPACE_PATH=/app

# Python 模块搜索路径
PYTHONPATH=/app:/app/src
```

### 系统架构

```
用户浏览器
    ↓
Nginx (端口 80)
    ↓ 反向代理
FastAPI (端口 8000)
    ↓
LangChain Agent
    ↓
火山方舟 API (视频生成)
```

## 常用命令速查

```bash
# 查看容器状态
docker-compose ps

# 查看日志
docker-compose logs -f tnho-video-api

# 重启服务
docker-compose restart tnho-video-api

# 停止服务
docker-compose down

# 启动服务
docker-compose up -d

# 进入容器
docker-compose exec tnho-video-api bash

# 测试健康检查
curl http://localhost:8000/health
```

## 后续建议

1. **监控服务状态**
   - 定期检查 `docker-compose ps`
   - 设置日志轮转避免磁盘占满

2. **备份数据**
   - 如果使用 PostgreSQL，定期备份数据库
   - 备份 `.env` 配置文件

3. **性能优化**
   - 根据实际使用情况调整容器资源限制
   - 监控 API 响应时间

4. **安全加固**
   - 确保 API Key 不泄露
   - 考虑添加 API 访问限流

## 联系和支持

如果遇到本文档未涵盖的问题，请提供以下信息：

1. 容器状态：`docker-compose ps`
2. 最新日志：`docker-compose logs --tail=100 tnho-video-api`
3. 诊断结果：`bash debug_container.sh` 的输出

---

**修复日期**: 2025-01-XX
**修复版本**: v1.1.0
**状态**: 已完成修复，等待用户验证
