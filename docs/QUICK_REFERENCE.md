# 快速参考 - 视频生成进度功能

## 🚀 快速开始

### 1️⃣ 本地测试（立即可用）

```bash
# 健康检查
curl http://localhost:8000/health

# 创建任务
curl -X POST http://localhost:8000/api/generate-video \
  -H "Content-Type: application/json" \
  -d '{
    "product_name": "高强度螺栓",
    "theme": "品质保证",
    "duration": 20,
    "type": "video"
  }'

# 查询进度（替换 {task_id}）
curl http://localhost:8000/api/progress/{task_id}
```

### 2️⃣ 公网部署（需要配置）

```bash
# 运行 Nginx 配置脚本
cd /workspace/projects
bash scripts/setup_nginx.sh

# 测试访问
curl http://47.110.72.148/health

# 使用域名（DNS 需已配置）
curl http://tnho-fasteners.com/health
```

### 3️⃣ 小程序配置

```javascript
// miniprogram/app.js
globalData: {
  // 根据实际部署方式选择
  apiUrl: 'http://tnho-fasteners.com'      // 使用 Nginx 反向代理
  // apiUrl: 'http://47.110.72.148:8000'   // 直接使用 IP + 端口
  // apiUrl: 'http://localhost:8000'       // 本地测试
}
```

## 📊 进度说明

| 进度 | 状态 | 说明 |
|------|------|------|
| 0-70% | generating | 正在生成视频（多段视频按比例计算） |
| 70-90% | merging | 正在拼接视频 |
| 90-100% | uploading | 正在上传到对象存储 |
| 100% | completed | 任务完成 |

## 🔧 常用命令

```bash
# 查看服务状态
ps aux | grep uvicorn

# 查看端口监听
netstat -tlnp | grep 8000

# 查看服务日志
tail -f /tmp/api_server.log

# 重启服务
pkill -f "uvicorn src.api.app:app" && \
cd /workspace/projects && \
PYTHONPATH=/workspace/projects/src nohup python -m uvicorn src.api.app:app \
  --host 0.0.0.0 --port 8000 > /tmp/api_server.log 2>&1 &

# 运行自动化测试
bash /workspace/projects/scripts/test_api.sh

# 重载 Nginx
service nginx reload

# 测试 Nginx 配置
nginx -t
```

## 🐛 故障排查

### 服务无法启动
```bash
# 检查 Python 环境
python --version

# 检查依赖安装
pip list | grep -E 'fastapi|uvicorn|langchain'

# 查看启动错误
cd /workspace/projects
PYTHONPATH=/workspace/projects/src python -m uvicorn src.api.app:app
```

### 无法访问公网
```bash
# 检查 Nginx 状态
service nginx status

# 检查防火墙
service iptables status

# 检查云服务器安全组（在阿里云控制台）
# 确保 80/443/8000 端口已开放
```

### 任务失败
```bash
# 查看任务详情
curl http://localhost:8000/api/progress/{task_id} | python -m json.tool

# 查看错误日志
tail -f /tmp/api_server.log | grep -i error

# 检查数据库连接
PYTHONPATH=/workspace/projects/src python -c \
  "from storage.database.db import get_session; print(get_session())"
```

## 📝 API 快速参考

### 创建任务
```
POST /api/generate-video
```

请求：
```json
{
  "product_name": "高强度螺栓",
  "theme": "品质保证",
  "duration": 20,
  "type": "video",
  "scenario": "用于汽车制造",
  "product_image_url": "http://example.com/image.jpg"
}
```

响应：
```json
{
  "success": true,
  "task_id": "xxx-xxx-xxx",
  "message": "视频生成任务已创建"
}
```

### 查询进度
```
GET /api/progress/{task_id}
```

响应：
```json
{
  "success": true,
  "status": "generating",
  "progress": 35,
  "current_step": "正在生成第1段视频...",
  "total_parts": 2,
  "completed_parts": 1
}
```

## 🎯 配置清单

- [x] 服务运行在 8000 端口
- [ ] Nginx 反向代理已配置（生产环境需要）
- [ ] HTTPS 证书已配置（推荐）
- [ ] 云服务器安全组已开放 80/443 端口
- [ ] 小程序 API 地址已修改
- [ ] 数据库连接正常
- [ ] 对象存储配置正确

## 📞 获取帮助

- **日志文件**: `/tmp/api_server.log`
- **Nginx 日志**: `/var/log/nginx/error.log`
- **部署指南**: `docs/DEPLOYMENT_GUIDE.md`
- **功能说明**: `docs/PROGRESS_FEATURE_GUIDE.md`

---

**提示**: 当前服务已在本地运行，可以立即开始测试！
