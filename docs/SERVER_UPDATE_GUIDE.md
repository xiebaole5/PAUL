# 服务器更新指南

## 概述

本指南说明如何从 GitHub 拉取最新代码并在服务器上重启服务。

## 快速更新

在服务器上执行以下命令：

```bash
cd /workspace/projects
bash scripts/update_from_github.sh
```

## 脚本功能

`scripts/update_from_github.sh` 脚本会自动执行以下步骤：

1. 切换到项目目录 `/workspace/projects`
2. 检查当前 Git 状态
3. 从 GitHub 拉取最新代码（使用 `git reset --hard origin/main`）
4. 清理 Python 缓存
5. 停止所有旧的 Python 服务
6. 启动新的 FastAPI 服务
7. 验证服务状态（健康检查和企业微信接口测试）

## 手动更新步骤

如果需要手动更新，请按以下步骤操作：

### 1. 拉取最新代码

```bash
cd /workspace/projects
git fetch origin main
git reset --hard origin/main
```

### 2. 清理 Python 缓存

```bash
find src/ -name "*.pyc" -delete
find src/ -name "__pycache__" -type d -exec rm -rf {} +
```

### 3. 停止旧服务

```bash
pkill -9 -f "python3.*app"
pkill -9 -f "uvicorn"
pkill -9 -f "python.*app.main"
```

### 4. 启动新服务

```bash
cd /workspace/projects
nohup python3 app.py > /tmp/fastapi.log 2>&1 &
```

### 5. 验证服务状态

```bash
# 检查进程
ps aux | grep 'python3 app.py' | grep -v grep

# 健康检查
curl -s http://localhost:8080/health

# 测试企业微信接口
curl -s http://localhost:8080/api/wechat/test
```

## 服务管理

### 查看服务状态

```bash
bash scripts/manage_wechat_service.sh status
```

### 停止服务

```bash
bash scripts/manage_wechat_service.sh stop
```

### 启动服务

```bash
bash scripts/manage_wechat_service.sh start
```

### 重启服务

```bash
bash scripts/manage_wechat_service.sh restart
```

### 查看日志

```bash
tail -f /tmp/fastapi.log
```

## 测试企业微信 URL 验证

### 快速测试

```bash
bash scripts/quick_wechat_test.sh
```

### 手动测试

```bash
# 健康检查
curl -s http://localhost:8080/api/wechat/test

# URL 验证测试
curl -s "http://localhost:8080/api/wechat/callback?msg_signature={signature}&timestamp={timestamp}&nonce={nonce}&echostr={echostr}"
```

## 常见问题

### Q: 更新后服务无法启动？

**A:** 检查日志文件：
```bash
tail -100 /tmp/fastapi.log
```

常见原因：
- 代码语法错误
- 依赖包未安装
- 端口被占用

### Q: 端口被占用怎么办？

**A:** 查找占用端口的进程并停止：
```bash
# 查找占用 8080 端口的进程
lsof -i :8080
# 或
netstat -tulpn | grep 8080

# 停止该进程
kill -9 <PID>
```

### Q: 如何确认使用的是最新代码？

**A:** 检查以下内容：
1. Git 提交历史：`git log --oneline -5`
2. 文件修改时间：`ls -la src/api/wechat_callback_simple.py`
3. 服务启动时间：`ps aux | grep 'python3 app.py'`

### Q: 如何回滚到之前的版本？

**A:**
```bash
# 查看提交历史
git log --oneline

# 回滚到指定版本
git reset --hard <commit_hash>

# 重启服务
bash scripts/manage_wechat_service.sh restart
```

## 注意事项

1. **备份数据**：更新前建议备份重要数据（虽然此项目主要使用数据库，但也建议备份配置文件）
2. **测试环境**：建议先在测试环境验证，再在生产环境更新
3. **查看日志**：更新后务必查看日志，确保服务正常启动
4. **端口冲突**：如果使用其他端口，请修改 `app.py` 中的端口配置
5. **环境变量**：确保 `.env` 文件中的配置正确

## 更新日志

### 2025-01-15
- 修复企业微信 URL 验证接口，确认 echostr 为明文无需解密
- 移除所有 AES 解密逻辑
- 创建服务管理脚本
- 创建快速测试脚本
- 从 Git 历史中移除包含敏感信息的日志文件

## 相关文档

- `README.md` - 项目说明
- `DEPLOYMENT.md` - 部署指南
- `ENTERPRISE_WECHAT_CONFIG.md` - 企业微信配置指南
- `WECHAT_URL_VERIFY_SUCCESS.md` - URL 验证修复报告
