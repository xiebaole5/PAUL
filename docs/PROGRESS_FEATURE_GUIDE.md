# 视频生成进度功能部署说明

## 🎉 功能已成功实现

视频生成进度跟踪和实时提示功能已经完成并测试通过！

## 📋 当前状态

### ✅ 已完成
1. **数据库层**：任务进度表和管理器已创建并测试通过
2. **后端 API**：异步任务执行和进度查询接口已实现
3. **工具层**：视频生成、拼接、上传各阶段都支持进度回调
4. **小程序前端**：进度轮询和实时显示功能已实现
5. **测试验证**：所有功能测试通过

### 🚀 服务运行状态

```
服务名称：天虹紧固件视频生成 API
版本：1.1.0
端口：8000
状态：运行中
健康检查：✅ 正常
```

## 🌐 访问方式说明

### 问题分析

您尝试访问 `https://tnho-fasteners.com` 时遇到连接失败，原因是：

1. **HTTPS 未配置**：服务器只监听了 8000 端口（HTTP）
2. **没有反向代理**：域名请求没有被转发到 8000 端口
3. **防火墙限制**：云服务器可能未开放 8000 端口

### 解决方案

#### 方案1：本地测试（当前可用）✅

```bash
# 测试服务健康状态
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

# 获取任务ID后，查询进度
curl http://localhost:8000/api/progress/{task_id}
```

#### 方案2：配置 Nginx 反向代理（推荐用于生产环境）

1. **运行配置脚本**
   ```bash
   cd /workspace/projects
   bash scripts/setup_nginx.sh
   ```

2. **测试访问**
   ```bash
   # HTTP 访问
   curl http://tnho-fasteners.com/health
   curl http://47.110.72.148/health

   # 创建任务
   curl -X POST http://tnho-fasteners.com/api/generate-video \
     -H "Content-Type: application/json" \
     -d '{
       "product_name": "高强度螺栓",
       "theme": "品质保证",
       "duration": 20,
       "type": "video"
     }'
   ```

3. **配置 HTTPS（可选，推荐）**
   ```bash
   # 使用 Let's Encrypt 申请免费证书
   # 配置 Nginx 监听 443 端口
   ```

#### 方案3：直接使用公网IP + 端口（快速测试）

⚠️ 需要先在阿里云控制台开放 8000 端口

```bash
curl http://47.110.72.148:8000/health
```

## 📱 小程序配置

### 修改 API 地址

根据您的实际部署方式，修改小程序的 API 地址：

```javascript
// miniprogram/app.js
globalData: {
  // 方案1：使用域名（需要配置 Nginx 反向代理）
  apiUrl: 'http://tnho-fasteners.com'

  // 方案2：使用 IP + 端口（需要开放 8000 端口）
  // apiUrl: 'http://47.110.72.148:8000'

  // 方案3：开发测试（仅限同一局域网）
  // apiUrl: 'http://192.168.1.100:8000'
}
```

### 小程序使用流程

1. **用户填写信息**：产品名称、主题、时长、场景描述等
2. **点击"生成视频"**：提交请求到后端
3. **获取任务ID**：后端返回任务ID
4. **开始轮询进度**：每 2 秒查询一次进度
5. **显示实时进度**：
   ```
   生成中 0%
   生成中 35%
   生成中 70%
   正在拼接视频... 80%
   正在上传到对象存储... 95%
   任务已完成！ 100%
   ```
6. **跳转结果页**：显示生成的视频和分段信息

## 🔧 快速测试工具

提供了自动化测试脚本：

```bash
# 运行测试（自动测试多个访问地址）
bash /workspace/projects/scripts/test_api.sh
```

## 📊 进度功能说明

### 进度百分比计算

| 阶段 | 进度范围 | 说明 |
|------|----------|------|
| 任务创建 | 0% | 任务已创建，等待开始 |
| 视频生成 | 0-70% | 根据已完成段数比例计算 |
| 视频拼接 | 70-90% | 下载和拼接多段视频 |
| 上传到对象存储 | 90-100% | 上传最终视频 |
| 任务完成 | 100% | 全部完成 |

### 多段视频示例

以 20 秒视频为例（分为 2 段）：

```
0%  - 开始生成第1段视频...
35% - 第1段视频生成完成
35% - 开始生成第2段视频...
70% - 第2段视频生成完成
70% - 正在下载和拼接视频...
90% - 拼接完成，准备上传
95% - 正在上传到对象存储...
100% - 任务完成！
```

## 🛠️ 故障排查

### 问题1：服务无法访问

**症状**：`curl: (7) Failed to connect`

**解决方案**：
```bash
# 检查服务是否运行
ps aux | grep uvicorn

# 检查端口是否监听
netstat -tlnp | grep 8000

# 如果服务未运行，启动服务
cd /workspace/projects
PYTHONPATH=/workspace/projects/src nohup python -m uvicorn src.api.app:app \
  --host 0.0.0.0 --port 8000 > /tmp/api_server.log 2>&1 &
```

### 问题2：公网无法访问

**症状**：本地可访问，但公网 IP 无法访问

**解决方案**：
1. 检查阿里云安全组，确保开放 8000 端口
2. 配置 Nginx 反向代理（运行 `bash scripts/setup_nginx.sh`）
3. 检查防火墙规则

### 问题3：任务失败

**症状**：查询进度显示 `status: "failed"`

**解决方案**：
```bash
# 查看错误信息
curl http://localhost:8000/api/progress/{task_id}

# 查看后端日志
tail -f /tmp/api_server.log | grep -i error

# 常见错误：
# - API Key 配置错误
# - 数据库连接失败
# - 对象存储配置问题
```

## 📚 相关文档

- [部署指南](DEPLOYMENT_GUIDE.md) - 详细的部署和配置说明
- [API 文档](API.md) - API 接口详细说明
- [数据库模型](../src/storage/database/shared/model.py) - 数据库表结构

## ✅ 下一步行动

### 立即可用

1. **本地测试**：使用 `http://localhost:8000` 进行测试
2. **小程序开发**：使用局域网 IP 配置小程序进行开发测试

### 生产部署

1. **配置 Nginx**：运行 `bash scripts/setup_nginx.sh`
2. **开放端口**：在阿里云控制台开放 80/443 端口
3. **配置 HTTPS**（推荐）：使用 Let's Encrypt 证书
4. **修改小程序 API 地址**：改为 `http://tnho-fasteners.com`

### 优化建议

1. **添加 API 鉴权**：防止未授权访问
2. **限流保护**：防止恶意请求
3. **日志监控**：接入监控系统
4. **备份策略**：定期备份数据库

## 💡 提示

- **服务已在运行**：无需重新启动，可以直接使用
- **本地测试正常**：所有功能在本地测试通过
- **公网访问需要配置**：选择上述任一方案配置公网访问
- **小程序需要修改配置**：根据实际部署方式修改 API 地址

---

**如有任何问题，请查看日志文件或联系技术支持。**
