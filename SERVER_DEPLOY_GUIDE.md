# 天虹紧固件视频生成服务 - 服务器部署指南

## 当前状态
✅ 代码已完成开发
✅ 所有工具已实现
✅ Docker 配置就绪
✅ 域名已配置：tnho-fasteners.com
✅ 模型已更新：doubao-1.8（文本） + doubao-seedance-1-5-pro（视频）
✅ 需要在服务器上重启服务应用代码修改

---

## 📋 配置信息

### 基本信息
| 项目 | 值 |
|-----|---|
| 域名 | tnho-fasteners.com |
| 服务器 IP | 47.110.72.148 |
| 仓库目录 | /opt/tnho-video-generator |

### 模型配置
| 类型 | 模型名称 |
|-----|---------|
| 文本处理 | doubao-1.8 |
| 视频生成 | doubao-seedance-1-5-pro |

### 访问地址
| 服务 | URL |
|-----|-----|
| API 服务 | https://tnho-fasteners.com |
| API 文档 | https://tnho-fasteners.com/docs |
| 健康检查 | https://tnho-fasteners.com/health |

---

## 🚀 快速重启（3步完成）

### 方法 1：使用自动化脚本（推荐）

```bash
# 1. 将 restart_server.sh 上传到服务器 /opt/tnho-video-generator 目录
# 2. 添加执行权限并运行
cd /opt/tnho-video-generator
chmod +x restart_server.sh
./restart_server.sh
```

### 方法 2：手动执行命令

```bash
# 1. 切换到项目目录
cd /opt/tnho-video-generator

# 2. 停止并删除容器
docker stop tnho-video-api tnho-nginx
docker rm tnho-video-api tnho-nginx

# 3. 重新启动（不需要重新构建，因为只是修改了代码文件）
docker-compose up -d

# 4. 等待服务启动（15秒）
sleep 15

# 5. 查看服务状态
docker ps

# 6. 查看日志
docker logs tnho-video-api
```

---

## 🔍 验证服务是否正常

### 1. 健康检查
```bash
curl https://tnho-fasteners.com/health
```

预期返回：
```json
{"status":"ok"}
```

### 2. API 根路径
```bash
curl https://tnho-fasteners.com/
```

预期返回：
```json
{
  "status": "running",
  "service": "天虹紧固件视频生成 API",
  "version": "1.0.0"
}
```

### 3. 测试脚本生成（快速，约5秒）
```bash
curl -X POST https://tnho-fasteners.com/api/generate-video \
  -H "Content-Type: application/json" \
  -d '{
    "product_name": "高强度螺栓",
    "theme": "品质保证",
    "duration": 5,
    "type": "script"
  }'
```

### 4. 测试视频生成（需要1-2分钟，调用真实API）
```bash
curl -X POST https://tnho-fasteners.com/api/generate-video \
  -H "Content-Type: application/json" \
  -d '{
    "product_name": "不锈钢螺丝",
    "theme": "品质保证",
    "duration": 10,
    "type": "video"
  }'
```

### 5. 测试图片上传
```bash
curl -X POST https://tnho-fasteners.com/api/upload-image \
  -F "file=@/path/to/your/product-image.jpg"
```

---

## 🔧 常见问题排查

### 问题 1: 服务无法启动
```bash
# 查看详细日志
docker logs tnho-video-api --tail 100

# 检查容器状态
docker ps -a
```

**可能原因**：
- 端口被占用
- 环境变量配置错误
- 代码语法错误

### 问题 2: 视频生成失败
可能原因：
- API Key 无效
- 网络连接问题
- 模型服务不可用

排查步骤：
```bash
# 查看服务日志，寻找错误信息
docker logs -f tnho-video-api

# 检查环境变量
docker exec tnho-video-api env | grep ARK
```

### 问题 3: 图片上传返回 localhost URL
**解决方案**：
- 已修复！环境变量 `EXTERNAL_BASE_URL` 已更新为 `https://tnho-fasteners.com`
- 确保重启容器以应用新配置

### 问题 4: HTTPS 证书未配置
**解决方案**：
参考 `HTTPS_DEPLOY_GUIDE.md` 文档，申请并配置 SSL 证书。

---

## 📱 小程序配置

### 域名配置
1. 登录 [微信公众平台](https://mp.weixin.qq.com/)
2. 开发 -> 开发管理 -> 开发设置 -> 服务器域名
3. 添加 request 合法域名：
   - `https://tnho-fasteners.com`
4. 添加 uploadFile 合法域名：
   - `https://tnho-fasteners.com`

### 本地开发
1. 打开微信开发者工具
2. 导入 `miniprogram` 目录
3. 小程序配置已更新为使用 `https://tnho-fasteners.com`
4. 点击"编译"即可测试

**注意**：微信开发者工具中需要关闭「不校验合法域名」选项以测试正式环境。

---

## 🔗 完整文档

- **HTTPS 部署指南**：`HTTPS_DEPLOY_GUIDE.md` - 详细配置 SSL 证书
- **项目文档**：`PROJECT_README.md` - 项目整体介绍
- **小程序文档**：`MINIPROGRAM_README.md` - 小程序使用说明
- **部署指南（中文）**：`部署指南.md` - 完整部署流程

---

## 📊 API 接口文档

访问以下地址查看完整 API 文档：
```
https://tnho-fasteners.com/docs
```

---

## ✅ 待办事项

### 高优先级
- [x] 修复视频生成功能
- [x] 集成火山方舟视频生成模型
- [x] 实现脚本生成功能
- [x] 添加图片上传功能
- [x] 更新域名配置为 tnho-fasteners.com
- [x] 更新模型配置（doubao-1.8 + doubao-seedance-1-5-pro）
- [ ] 在服务器上重启服务（当前待办）
- [ ] 配置 HTTPS 证书
- [ ] 测试视频生成功能

### 中优先级
- [ ] 完成域名实名认证
- [ ] 完成 ICP 备案
- [ ] 配置微信小程序服务器域名
- [ ] 测试小程序完整功能

### 低优先级
- [ ] 提交小程序审核
- [ ] 性能优化
- [ ] 添加更多视频主题模板

---

## 📞 技术支持

如遇到问题，请提供以下信息：
1. 容器日志：`docker logs tnho-video-api`
2. 容器状态：`docker ps -a`
3. Nginx 日志：`docker logs tnho-nginx`
4. 具体错误信息或截图

---

**文档版本**: v2.1
**更新日期**: 2025-01-13
**域名**: tnho-fasteners.com
**模型配置**: doubao-1.8（文本） + doubao-seedance-1-5-pro（视频）
