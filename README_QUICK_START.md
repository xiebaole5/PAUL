# 天虹视频生成服务 - 快速启动指南

## 快速修复和部署

### 一键修复（推荐）

```bash
# 1. 添加执行权限
chmod +x *.sh

# 2. 运行快速修复
bash quick_fix.sh
```

如果快速修复无效，运行完整重新部署：

```bash
bash fix_and_redeploy.sh
```

### 验证服务状态

```bash
# 检查容器状态
docker-compose ps

# 运行功能测试
bash test_service.sh
```

### 访问服务

- **API 文档**: http://47.110.72.148/docs
- **健康检查**: http://47.110.72.148/health

## 常用脚本说明

| 脚本 | 说明 | 使用场景 |
|------|------|----------|
| `quick_fix.sh` | 快速修复脚本 | 服务异常但镜像已构建完成 |
| `fix_and_redeploy.sh` | 完整修复和重新部署 | 首次部署或代码有较大改动 |
| `debug_container.sh` | 容器诊断脚本 | 排查服务启动问题 |
| `test_service.sh` | 功能测试脚本 | 验证服务是否正常工作 |

## 故障排查

### 问题：容器一直重启

```bash
# 查看日志
docker-compose logs -f tnho-video-api

# 运行诊断
bash debug_container.sh
```

### 问题：健康检查失败

```bash
# 检查容器状态
docker-compose ps

# 重启容器
docker-compose restart tnho-video-api

# 等待 10 秒后重试
sleep 10
curl http://localhost:8000/health
```

### 问题：API 文档无法访问

检查 Nginx 配置和端口映射：

```bash
# 检查 Nginx 日志
docker-compose logs -f tnho-nginx

# 检查端口占用
netstat -tlnp | grep :80
netstat -tlnp | grep :8000
```

## 环境配置

确保 `.env` 文件存在并包含以下配置：

```bash
# 火山方舟 API 配置
ARK_API_KEY=e1533511-efae-4131-aea9-b573a1be4ecf
ARK_BASE_URL=https://ark.cn-beijing.volces.com/api/v3

# 外部访问地址
EXTERNAL_BASE_URL=http://47.110.72.148
```

## API 快速测试

### 1. 生成视频脚本

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

### 2. 生成宣传视频

```bash
curl -X POST http://localhost:8000/api/generate-video \
  -H "Content-Type: application/json" \
  -d '{
    "product_name": "不锈钢螺丝",
    "theme": "技术创新",
    "duration": 20,
    "type": "video",
    "scenario": "用于汽车制造中的高强度连接场景"
  }'
```

### 3. 上传产品图片

```bash
curl -X POST http://localhost:8000/api/upload-image \
  -F "file=@your_product_image.jpg"
```

## 技术支持

遇到问题请查看：
- 详细故障排查文档：`FIX_DEPLOYMENT_GUIDE.md`
- 容器诊断：`bash debug_container.sh`
- 完整日志：`docker-compose logs --tail=100 tnho-video-api`
