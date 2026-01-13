# 天虹紧固件 API 服务部署指南

## 服务运行状态

### 当前运行的服务
- **新API服务（带进度功能）**: 8000 端口
  - 进程: `python -m uvicorn src.api.app:app`
  - 健康检查: `http://localhost:8000/health`

- **旧API服务**: 9000 端口
  - 进程: `python -m uvicorn app.main:app`

## 访问方式

### 1. 本地测试（推荐用于调试）

```bash
# 测试健康状态
curl http://localhost:8000/health

# 创建视频生成任务
curl -X POST http://localhost:8000/api/generate-video \
  -H "Content-Type: application/json" \
  -d '{
    "product_name": "高强度螺栓",
    "theme": "品质保证",
    "duration": 20,
    "type": "video"
  }'

# 查询任务进度（替换 {task_id} 为实际的任务ID）
curl http://localhost:8000/api/progress/{task_id}
```

### 2. 公网访问（需要配置反向代理）

#### 方案A：使用 Nginx 反向代理

```bash
# 1. 运行配置脚本
cd /workspace/projects
bash scripts/setup_nginx.sh

# 2. 测试访问
curl http://47.110.72.148/health
curl http://tnho-fasteners.com/health

# 3. 创建任务
curl -X POST http://tnho-fasteners.com/api/generate-video \
  -H "Content-Type: application/json" \
  -d '{
    "product_name": "高强度螺栓",
    "theme": "品质保证",
    "duration": 20,
    "type": "video"
  }'
```

#### 方案B：直接使用公网IP + 端口

```bash
# 注意：需要确保云服务器安全组开放 8000 端口
curl http://47.110.72.148:8000/health
curl http://47.110.72.148:8000/api/health
```

## 快速测试脚本

```bash
# 运行自动化测试
bash /workspace/projects/scripts/test_api.sh
```

## API 接口说明

### 1. 健康检查
```
GET /health
```

响应：
```json
{
  "status": "ok"
}
```

### 2. 创建视频生成任务
```
POST /api/generate-video
Content-Type: application/json
```

请求体：
```json
{
  "product_name": "高强度螺栓",
  "theme": "品质保证",
  "duration": 20,
  "type": "video",
  "scenario": "用于汽车制造",
  "product_image_url": "http://example.com/image.jpg",
  "session_id": "session-123"
}
```

响应：
```json
{
  "success": true,
  "message": "视频生成任务已创建，任务ID: xxx",
  "task_id": "xxx",
  "type": "video"
}
```

### 3. 查询任务进度
```
GET /api/progress/{task_id}
```

响应：
```json
{
  "success": true,
  "task_id": "xxx",
  "status": "generating",
  "progress": 35,
  "current_step": "正在生成第1段视频...",
  "total_parts": 2,
  "completed_parts": 1,
  "video_urls": null,
  "merged_video_url": null,
  "message": "正在生成视频... (35%)"
}
```

状态说明：
- `pending`: 任务等待中
- `generating`: 正在生成视频
- `merging`: 正在拼接视频
- `uploading`: 正在上传到对象存储
- `completed`: 任务完成
- `failed`: 任务失败

## 环境变量配置

```bash
# API 访问地址
export EXTERNAL_BASE_URL="http://47.110.72.148"

# 或使用域名（需配置 DNS）
export EXTERNAL_BASE_URL="http://tnho-fasteners.com"
```

## 小程序配置

小程序需要修改 API 地址：

```javascript
// miniprogram/app.js
globalData: {
  // 使用 HTTP 或 HTTPS（取决于服务器配置）
  apiUrl: 'http://tnho-fasteners.com'
  // 或直接使用 IP
  // apiUrl: 'http://47.110.72.148'
}
```

## 进度功能说明

### 进度计算
- 视频生成阶段：0-70%（根据已完成段数比例）
- 视频拼接阶段：70-90%
- 上传阶段：90-100%

### 轮询建议
- 小程序端每 2 秒轮询一次
- 最多轮询 3 分钟（90次）
- 超时后提示用户稍后查看

## 故障排查

### 1. 服务无法启动
```bash
# 查看服务进程
ps aux | grep uvicorn

# 查看端口占用
netstat -tlnp | grep 8000

# 查看服务日志
tail -f /tmp/api_server.log
```

### 2. 无法通过公网访问
```bash
# 检查 Nginx 状态
service nginx status

# 测试 Nginx 配置
nginx -t

# 查看 Nginx 日志
tail -f /var/log/nginx/error.log

# 重载 Nginx
service nginx reload
```

### 3. 数据库连接失败
```bash
# 检查数据库配置
cat /workspace/projects/src/storage/database/db.py

# 测试数据库连接
PYTHONPATH=/workspace/projects/src python -c "from storage.database.db import get_session; print(get_session())"
```

### 4. 视频生成失败
```bash
# 查看完整错误信息
curl http://localhost:8000/api/progress/{task_id}

# 查看后端日志
tail -f /tmp/api_server.log | grep -i error
```

## 更新部署

```bash
# 1. 停止旧服务
pkill -f "uvicorn src.api.app:app"

# 2. 启动新服务
cd /workspace/projects
PYTHONPATH=/workspace/projects/src nohup python -m uvicorn src.api.app:app \
  --host 0.0.0.0 \
  --port 8000 \
  > /tmp/api_server.log 2>&1 &

# 3. 测试服务
sleep 3
curl http://localhost:8000/health

# 4. 重载 Nginx（如果配置了反向代理）
service nginx reload
```

## 安全建议

1. **启用 HTTPS**
   - 使用 Let's Encrypt 申请免费 SSL 证书
   - 配置 Nginx 监听 443 端口

2. **API 鉴权**
   - 添加 API Token 验证
   - 限制请求频率

3. **防火墙配置**
   - 仅开放必要的端口（80, 443, 22）
   - 使用安全组规则

## 联系支持

如有问题，请查看：
- 后端日志: `/tmp/api_server.log`
- Nginx 日志: `/var/log/nginx/error.log`
- 任务进度: 数据库表 `video_generation_tasks`
