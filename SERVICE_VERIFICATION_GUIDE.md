# 服务部署验证指南

## ✅ 当前状态

服务已成功启动！

**服务信息**：
- 状态：`active (running)`
- 地址：`http://0.0.0.0:8000`
- 进程ID：15435
- 内存占用：105.7M

## 📋 验证步骤

### 1. 运行自动化验证脚本

```bash
cd /root/PAUL
bash verify_service.sh
```

### 2. 手动验证接口

#### 健康检查
```bash
curl http://localhost:8000/health
```

**预期输出**：
```json
{"status":"ok"}
```

#### 图片上传测试
```bash
# 创建测试文件
echo "test" > /tmp/test_image.txt

# 上传测试
curl -X POST http://localhost:8000/api/upload-image \
  -F "file=@/tmp/test_image.txt"
```

**预期输出**：
```json
{
  "url": "https://tnho-video.oss-cn-hangzhou.aliyuncs.com/...",
  "message": "图片上传成功"
}
```

### 3. 配置服务开机自启

```bash
# 启用开机自启
systemctl enable tnho-api

# 验证已启用
systemctl is-enabled tnho-api
```

**预期输出**：
```
enabled
```

### 4. 测试公网访问

```bash
# 从本地或远程服务器测试
curl https://tnho-fasteners.com/health
```

**预期输出**：
```json
{"status":"ok"}
```

## 🔍 常用运维命令

### 服务管理
```bash
# 启动服务
systemctl start tnho-api

# 停止服务
systemctl stop tnho-api

# 重启服务
systemctl restart tnho-api

# 查看状态
systemctl status tnho-api

# 查看日志
journalctl -u tnho-api -f
```

### 日志查看
```bash
# 查看最近50行
journalctl -u tnho-api -n 50

# 查看实时日志
journalctl -u tnho-api -f

# 查看今天的日志
journalctl -u tnho-api --since today
```

### 端口和进程
```bash
# 查看端口占用
lsof -i:8000

# 查看进程
ps aux | grep python

# 查看资源使用
top -p $(pgrep -f "python.*app.py")
```

## 🚨 故障排查

### 问题1：服务无法启动

**解决方案**：
```bash
# 1. 查看详细日志
journalctl -u tnho-api -n 100

# 2. 检查端口占用
lsof -i:8000

# 3. 清除端口占用
kill -9 $(lsof -t -i:8000)

# 4. 重启服务
systemctl restart tnho-api
```

### 问题2：健康检查失败

**解决方案**：
```bash
# 1. 检查服务是否运行
systemctl status tnho-api

# 2. 手动运行查看错误
cd /root/PAUL
source venv/bin/activate
python app.py
```

### 问题3：图片上传失败

**可能原因**：
- 对象存储配置错误
- 网络连接问题
- 权限问题

**解决方案**：
```bash
# 1. 检查环境变量
cat /root/PAUL/.env | grep S3

# 2. 检查对象存储连接
python -c "
from coze_coding_dev_sdk.s3 import S3Client
import os
client = S3Client()
print('对象存储连接正常')
"

# 3. 查看详细日志
journalctl -u tnho-api -n 50 | grep -i error
```

## 📊 监控建议

### 1. 设置日志轮转
```bash
# 配置 systemd 日志轮转
sudo vi /etc/systemd/journald.conf

# 添加以下配置
SystemMaxUse=500M
SystemMaxFileSize=100M
```

### 2. 设置告警监控
建议配置以下监控指标：
- 服务运行状态
- 响应时间
- 错误率
- 内存使用率
- 磁盘空间

### 3. 定期检查
```bash
# 每天检查服务状态
systemctl status tnho-api

# 每周检查日志大小
journalctl --disk-usage

# 每月检查依赖更新
cd /root/PAUL
source venv/bin/activate
pip list --outdated
```

## 🎯 下一步

### 1. 配置小程序（如需要）
- 在微信公众平台配置服务器域名：`https://tnho-fasteners.com`
- 配置业务域名：`https://tnho-fasteners.com`
- 配置 uploadFile 合法域名：`https://tnho-fasteners.com`

### 2. 测试小程序功能
- 测试视频生成功能
- 测试图片上传功能
- 测试进度查询功能

### 3. 提交小程序审核（如需要）
- 确保所有功能正常
- 提交审核

### 4. 性能优化（可选）
- 根据实际使用情况调整配置
- 优化数据库连接池
- 添加缓存机制

## 📞 获取帮助

如果遇到问题，请收集以下信息：

```bash
# 服务状态
systemctl status tnho-api > /tmp/service_status.txt

# 服务日志
journalctl -u tnho-api -n 200 > /tmp/service_logs.txt

# 环境配置
cat /root/PAUL/.env > /tmp/env_config.txt

# 依赖列表
cd /root/PAUL && source venv/bin/activate && pip list > /tmp/pip_list.txt
```

然后将这些文件提供给技术支持人员。

## ✅ 验证清单

- [ ] 服务状态正常
- [ ] 健康检查通过
- [ ] 图片上传功能正常
- [ ] 服务开机自启已配置
- [ ] 公网访问正常
- [ ] 日志记录正常
- [ ] 资源使用正常

---

**创建时间**：2026-01-14
**最后更新**：2026-01-14
