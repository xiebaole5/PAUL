# 服务器 Mixed Content 错误修复 - 执行步骤

## 问题说明
服务器上的代码还是旧版本，需要先拉取最新代码才能使用新创建的脚本。

## 完整执行步骤

### 步骤 1：创建测试文件
```bash
# 创建测试文件
echo "Test content" > /tmp/test.txt

# 确认文件存在
ls -lh /tmp/test.txt
```

### 步骤 2：拉取最新代码
```bash
# 确保在正确的目录
cd /root/tnho-video

# 查看当前状态
git status

# 拉取最新代码
git pull origin main

# 确认新文件已下载
ls -lh scripts/restart-app.sh
```

### 步骤 3：重启应用（使用脚本）
```bash
# 确保在正确的目录
cd /root/tnho-video

# 执行重启脚本
bash scripts/restart-app.sh
```

**如果脚本执行成功，你会看到：**
```
========================================
小程序应用重启
========================================
ℹ 开始时间: 2026-01-14 ...

========================================
1. 拉取最新代码
========================================
✓ 代码拉取成功

========================================
2. 检查环境变量
========================================
✓ EXTERNAL_BASE_URL 配置正确

========================================
3. 停止旧进程
========================================
ℹ 停止旧进程 (PID: XXXX)
✓ 旧进程已停止

========================================
4. 启动新进程
========================================
ℹ 启动 Python 应用...
ℹ 虚拟环境已激活
✓ 应用启动成功 (PID: XXXX)

========================================
5. 测试应用
========================================
ℹ 测试健康检查接口...
✓ 健康检查通过

========================================
重启完成
========================================
ℹ 完成时间: 2026-01-14 ...

✓ 应用已成功重启

ℹ 查看日志：
  tail -f logs/app.log

ℹ 查看进程：
  ps aux | grep uvicorn

ℹ 测试 API：
  curl https://tnho-fasteners.com/api/health
```

### 步骤 4：验证修复
```bash
# 测试图片上传接口
curl -X POST https://tnho-fasteners.com/api/upload-image \
  -F "file=@/tmp/test.txt"
```

**预期结果：**
```json
{
  "success": true,
  "message": "图片上传成功",
  "image_url": "https://tnho-fasteners.com/assets/uploads/xxx.jpg",
  "filename": "xxx.jpg"
}
```

**重要**：确认 `image_url` 以 `https://tnho-fasteners.com` 开头，而不是 `http://47.110.72.148`

### 步骤 5：在小程序中测试

1. **打开微信开发者工具**
2. **清除缓存**：
   - 点击工具栏上的"清除缓存"
   - 选择"清除数据缓存"
3. **重新编译**：
   - 点击"编译"按钮
4. **测试图片上传**：
   - 点击"上传图片"按钮
   - 选择一张图片
   - 观察是否显示成功

## 手动重启方案（如果脚本不可用）

如果脚本执行失败，可以手动重启：

```bash
# 进入项目目录
cd /root/tnho-video

# 停止旧进程
ps aux | grep "[u]vicorn app:app" | awk '{print $2}' | xargs kill

# 等待 2 秒
sleep 2

# 激活虚拟环境
source venv/bin/activate

# 启动新进程（后台运行）
nohup uvicorn app:app --host 0.0.0.0 --port 8000 --workers 1 --log-level info >> logs/app.log 2>&1 &

# 检查进程是否启动成功
ps aux | grep uvicorn
```

## 验证服务状态

```bash
# 检查 Python 进程
ps aux | grep uvicorn

# 检查应用日志
tail -n 20 logs/app.log

# 测试健康检查接口
curl https://tnho-fasteners.com/api/health

# 测试图片上传接口
curl -X POST https://tnho-fasteners.com/api/upload-image \
  -F "file=@/tmp/test.txt"
```

## 常见问题

### Q1: git pull 失败
```bash
# 解决方法：先暂存本地修改
cd /root/tnho-video
git stash
git pull origin main
```

### Q2: 脚本执行失败
```bash
# 解决方法：使用手动重启方案
cd /root/tnho-video
ps aux | grep "[u]vicorn app:app" | awk '{print $2}' | xargs kill
sleep 2
source venv/bin/activate
nohup uvicorn app:app --host 0.0.0.0 --port 8000 --workers 1 --log-level info >> logs/app.log 2>&1 &
```

### Q3: 应用启动失败
```bash
# 查看错误日志
tail -n 50 logs/app.log

# 检查虚拟环境
source venv/bin/activate
python --version

# 重新安装依赖
pip install -r requirements.txt
```

### Q4: 图片 URL 还是使用 HTTP
```bash
# 检查环境变量
cat /root/tnho-video/.env | grep EXTERNAL_BASE_URL

# 应该输出：
# EXTERNAL_BASE_URL=https://tnho-fasteners.com

# 如果不对，编辑文件
nano /root/tnho-video/.env
# 添加或修改为：
# EXTERNAL_BASE_URL=https://tnho-fasteners.com

# 重启应用
bash /root/tnho-video/scripts/restart-app.sh
```

## 快速命令集合

```bash
# 完整的一键执行序列
cd /root/tnho-video && \
echo "Test content" > /tmp/test.txt && \
git pull origin main && \
bash scripts/restart-app.sh && \
curl -X POST https://tnho-fasteners.com/api/upload-image -F "file=@/tmp/test.txt"
```

---

**执行时间**：2026-01-14
**预计耗时**：2-3 分钟
**验证标志**：图片 URL 以 `https://tnho-fasteners.com` 开头
