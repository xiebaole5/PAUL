# 快速修复指南 - 解决端口占用问题

## 当前状态

✅ 已完成：
- python-multipart 已安装
- coze-coding-dev-sdk 已安装

❌ 当前问题：
- 端口 8000 被占用
- 服务无法启动

## 快速修复（推荐）

在服务器上执行以下命令：

```bash
# 1. 拉取最新代码
cd /root/PAUL
git pull origin main

# 2. 运行修复脚本
bash fix_port_conflict.sh
```

## 手动修复（备用方案）

如果脚本执行失败，可以手动执行以下步骤：

```bash
# 1. 查找占用 8000 端口的进程
lsof -i:8000

# 2. 停止占用端口的进程（假设进程ID是 XXXX）
kill -9 <进程ID>

# 3. 或者一次性停止所有相关进程
pkill -f "python.*app.py"

# 4. 等待几秒
sleep 3

# 5. 验证端口是否释放
lsof -i:8000
# 如果没有输出，说明端口已释放

# 6. 重启服务
systemctl start tnho-api

# 7. 检查服务状态
systemctl status tnho-api

# 8. 查看日志
journalctl -u tnho-api -n 30 --no-pager
```

## 验证修复成功

### 1. 检查服务状态

```bash
systemctl status tnho-api
```

**预期输出**：
```
● tnho-api.service - 天虹紧固件视频生成 API 服务
   Loaded: loaded (/etc/systemd/system/tnho-api.service; enabled; preset: enabled)
   Active: active (running) since ...
```

### 2. 测试健康检查

```bash
curl http://localhost:8000/health
```

**预期输出**：
```json
{
  "status": "healthy",
  "message": "天虹紧固件视频生成 API 服务运行正常"
}
```

### 3. 测试图片上传

首先需要找一个实际的图片文件：

```bash
# 查看 assets 目录
ls -lh /root/PAUL/assets/

# 如果没有图片，可以创建一个测试图片（或使用系统自带的）
echo "test" > /tmp/test.txt
```

然后测试上传：

```bash
# 使用测试文件
curl -X POST http://localhost:8000/api/upload-image \
  -F "file=@/tmp/test.txt" \
  -v

# 或者使用真实的图片文件
curl -X POST http://localhost:8000/api/upload-image \
  -F "file=@/root/PAUL/assets/<图片文件名>" \
  -v
```

**预期输出**：
```json
{
  "url": "https://tnho-video.oss-cn-hangzhou.aliyuncs.com/...",
  "message": "图片上传成功"
}
```

## 常见问题

### Q1: 端口仍然被占用

**解决方案**：
```bash
# 查看所有相关进程
ps aux | grep python

# 强制停止所有 Python 进程（谨慎使用）
pkill -9 python

# 或者只停止特定进程
kill -9 $(lsof -t -i:8000)
```

### Q2: 服务启动后立即停止

**解决方案**：
```bash
# 查看详细日志
journalctl -u tnho-api -f

# 手动运行应用（查看实时错误）
cd /root/PAUL
source venv/bin/activate
python app.py
```

### Q3: 修复脚本执行失败

**解决方案**：
```bash
# 检查脚本是否存在
ls -lh /root/PAUL/fix_port_conflict.sh

# 检查脚本权限
chmod +x /root/PAUL/fix_port_conflict.sh

# 手动执行脚本中的命令
```

## 下一步

修复成功后：

1. ✅ 配置小程序服务器域名（如果需要）
2. ✅ 测试小程序功能
3. ✅ 提交小程序审核（如果需要）

## 获取帮助

如果遇到其他问题，请提供以下信息：

```bash
# 服务状态
systemctl status tnho-api

# 服务日志
journalctl -u tnho-api -n 100 --no-pager

# 端口占用情况
lsof -i:8000

# Python 进程
ps aux | grep python

# 已安装的依赖
pip list | grep -E "python-multipart|coze-coding-dev-sdk"
```
