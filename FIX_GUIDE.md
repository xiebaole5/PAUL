# 天虹紧固件视频生成 Agent - 修复说明

## 问题分析

服务器部署时遇到以下错误：

```
ModuleNotFoundError: No module named 'storage.memory'
```

### 根本原因

1. **导入路径不匹配**：
   - 文件实际位置：`/app/src/storage/memory/memory_saver.py`
   - 导入语句：`from storage.memory.memory_saver import get_memory_saver`
   - Python 无法找到正确的模块路径

2. **PYTHONPATH 配置不完整**：
   - Dockerfile 中只设置了 `COZE_WORKSPACE_PATH=/app`
   - 缺少 `/app/src` 到 PYTHONPATH 的配置

## 修复方案

### 1. 修改 Dockerfile

在环境变量中添加 PYTHONPATH 配置：

```dockerfile
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    COZE_WORKSPACE_PATH=/app \
    PYTHONPATH=/app:/app/src
```

这样 Python 就能正确导入 `src/` 目录下的模块。

### 2. 自动修复脚本

创建了 `fix_agent_and_docker.sh` 脚本，自动执行以下操作：

1. 检查并修复 Dockerfile 中的 PYTHONPATH 配置
2. 停止现有容器
3. 重新构建 Docker 镜像
4. 启动服务
5. 等待服务启动并验证健康状态
6. 显示容器日志

### 3. 测试验证脚本

创建了 `test_agent_api.sh` 脚本，测试以下功能：

1. 健康检查 (`/health`)
2. Agent 初始化 (`/agent/message`)
3. 脚本生成工具
4. 视频生成接口

## 使用方法

### 在服务器上执行修复

```bash
# 1. 进入项目目录
cd /root/tnho-video-generator

# 2. 下载修复脚本（如果还没有）
# fix_agent_and_docker.sh 已经在项目中

# 3. 给脚本执行权限
chmod +x fix_agent_and_docker.sh

# 4. 执行修复脚本
./fix_agent_and_docker.sh
```

### 验证修复结果

```bash
# 1. 给测试脚本执行权限
chmod +x test_agent_api.sh

# 2. 执行测试脚本
./test_agent_api.sh
```

## 预期结果

修复成功后，服务应该：

1. 容器成功启动，没有 ModuleNotFoundError 错误
2. 健康检查返回 200 状态码
3. Agent 能够正常响应消息
4. 视频生成功能正常工作

## 常用命令

```bash
# 查看容器状态
docker compose ps

# 查看日志
docker compose logs -f

# 重启服务
docker compose restart

# 停止服务
docker compose down

# 查看特定服务日志
docker compose logs -f tnho-video-api
docker compose logs -f tnho-nginx
```

## 注意事项

1. 确保 Docker 和 Docker Compose 已正确安装
2. 确保环境变量配置正确（API Key、数据库连接等）
3. 如果修复失败，请查看完整日志：`docker compose logs --tail=100`
4. 修复过程中会重新构建镜像，需要一定时间（约 2-5 分钟）

## 相关文件

- `Dockerfile`: Docker 镜像构建配置
- `docker-compose.yml`: 服务编排配置
- `src/agents/agent.py`: Agent 主逻辑（已正确配置）
- `src/storage/memory/memory_saver.py`: 记忆管理模块
- `fix_agent_and_docker.sh`: 自动修复脚本
- `test_agent_api.sh`: API 测试脚本
