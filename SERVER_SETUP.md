# 服务器Git仓库设置指南

## 📋 问题诊断

服务器 `/workspace/projects` 目录不是Git仓库，导致无法同步代码。

## 🚀 解决方案

### 方案1：初始化Git仓库（推荐，保留现有代码）

```bash
# 进入项目目录
cd /workspace/projects

# 第一步：初始化Git仓库
git init

# 第二步：添加远程仓库
git remote add origin https://github.com/xiebaole5/PAUL.git

# 第三步：拉取最新代码
git fetch origin
git reset --hard origin/main
git clean -fd

# 第四步：查看更新
ls -la *.sh *.md

# 第五步：启动服务
bash start_service_v2.sh
```

### 方案2：克隆新仓库（全新开始）

```bash
# 第一步：备份现有目录（可选）
cd /workspace
mv projects projects_backup_$(date +%Y%m%d_%H%M%S)

# 第二步：克隆仓库
git clone https://github.com/xiebaole5/PAUL.git projects

# 第三步：进入项目目录
cd /workspace/projects

# 第四步：启动服务
bash start_service_v2.sh
```

### 方案3：使用初始化脚本（交互式）

```bash
# 下载并运行初始化脚本
cd /workspace/projects

# 复制下面的脚本内容到 setup_git_repo.sh
# 然后执行：
bash setup_git_repo.sh
```

## 🎯 一键执行命令（推荐）

```bash
# === 完整的一键初始化和部署 ===

cd /workspace/projects

# 停止旧服务
pkill -9 uvicorn 2>/dev/null || true
sleep 2

# 初始化Git仓库
git init
git remote add origin https://github.com/xiebaole5/PAUL.git

# 拉取最新代码
git fetch origin
git reset --hard origin/main
git clean -fd

# 查看文件
ls -la *.sh *.md

# 启动服务
export COZE_WORKSPACE_PATH=/workspace/projects
export PYTHONPATH=/workspace/projects/src:$PYTHONPATH
nohup python3 -m uvicorn src.main:app --host 0.0.0.0 --port 8080 --log-level info > /tmp/fastapi.log 2>&1 &

# 等待启动
sleep 5

# 验证服务
curl http://localhost:8080/health
```

## ✅ 验证步骤

执行完成后，运行以下命令验证：

```bash
# 1. 检查Git状态
git status
git log --oneline -3

# 2. 检查服务
ps aux | grep uvicorn | grep -v grep
curl http://localhost:8080/health

# 3. 测试API
curl -X POST http://localhost:8080/api/generate-script \
  -H "Content-Type: application/json" \
  -d '{"product_name":"螺母","product_image_url":"http://test.com/img.jpg","usage_scenario":"建筑","theme_direction":"高品质"}'
```

## 🔍 问题排查

### 如果 `git reset --hard origin/main` 失败

```bash
# 查看远程分支
git branch -r

# 手动指定分支
git fetch origin main
git reset --hard origin/main
```

### 如果端口被占用

```bash
# 查看占用端口的进程
netstat -tlnp | grep 8080

# 强制停止
pkill -9 -f "uvicorn.*8080"
```

### 如果仍然返回404

```bash
# 查看日志
tail -50 /tmp/fastapi.log

# 检查Python路径
python3 -c "import sys; print('\n'.join(sys.path))"

# 测试模块导入
cd /workspace/projects
export PYTHONPATH=/workspace/projects/src:$PYTHONPATH
python3 -c "from agents.miniprogram_video_agent import build_agent; print('✅ 模块正常')"
```

## 📦 预期文件结构

执行后，应该看到以下文件：

```
/workspace/projects/
├── src/
│   ├── main.py
│   ├── agents/
│   └── tools/
├── start_service.sh
├── start_service_v2.sh
├── diagnose.sh
├── restart_service.sh
├── quick_fix.sh
├── sync_and_deploy.sh
├── setup_git_repo.sh
├── DEPLOYMENT.md
├── SYNC_TO_SERVER.md
└── SERVER_SETUP.md
```

## 🎯 成功标志

执行成功后，应该看到：

```bash
✅ Git仓库已连接
✅ 代码已更新
✅ 服务已启动
{"status":"healthy"}
```

## 📞 下一步

1. 执行上述一键命令
2. 验证服务正常运行
3. 配置Nginx反向代理（参考 DEPLOYMENT.md）
4. 测试小程序功能

如果遇到问题，请提供以下信息：
- `git status` 的输出
- `tail -50 /tmp/fastapi.log` 的输出
- `curl http://localhost:8080/health` 的输出
