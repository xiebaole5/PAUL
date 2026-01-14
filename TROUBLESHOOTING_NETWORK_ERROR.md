# 真机调试网络请求错误排查指南

## 🚨 错误信息

```
Error: 上传失败：网络请求错误 undefined [2.01.2510260][win32-x64]
```

## 🔍 问题原因分析

这个错误通常是由于以下原因之一：

1. **域名配置未生效**（最常见）
2. **uploadFile 合法域名未配置**
3. **HTTPS 证书问题**
4. **服务器未运行或响应异常**
5. **Cloudflare CDN 缓存问题**
6. **防火墙或网络策略问题**

## ✅ 排查步骤（按顺序执行）

### 步骤 1：检查域名配置是否生效

**操作**：
1. 登录微信公众平台：https://mp.weixin.qq.com/
2. 进入 **开发** → **开发管理** → **开发设置**
3. 检查 **uploadFile 合法域名** 是否包含 `https://tnho-fasteners.com`
4. 检查配置时间（刚配置需要 5-10 分钟生效）

**如果配置时间少于 10 分钟**：
- ⏳ 等待 10 分钟后重试

---

### 步骤 2：在服务器上验证服务状态

在服务器上执行以下命令：

```bash
# 1. 检查服务状态
systemctl status tnho-api

# 2. 检查服务日志（实时）
journalctl -u tnho-api -f
```

**预期输出**：
```
● tnho-api.service - 天虹紧固件视频生成 API 服务
   Loaded: loaded (/etc/systemd/system/tnho-api.service; enabled; preset: enabled)
   Active: active (running) since ...
```

**如果服务未运行**：
```bash
# 启动服务
systemctl start tnho-api
```

---

### 步骤 3：测试 HTTPS 证书和 API 接口

在服务器上执行以下命令：

```bash
# 1. 测试 HTTPS 证书
curl -I https://tnho-fasteners.com

# 2. 测试健康检查接口
curl https://tnho-fasteners.com/health

# 3. 测试图片上传接口
echo "test" > /tmp/test_upload.txt
curl -X POST https://tnho-fasteners.com/api/upload-image \
  -F "file=@/tmp/test_upload.txt" \
  -v
```

**预期输出**：
```json
{
  "url": "https://tnho-video.oss-cn-hangzhou.aliyuncs.com/...",
  "message": "图片上传成功"
}
```

**如果测试失败**：
- 检查 HTTPS 证书配置
- 检查 Nginx 配置：`sudo nginx -t`
- 重启 Nginx：`sudo systemctl reload nginx`

---

### 步骤 4：检查 Cloudflare CDN 配置

**如果使用了 Cloudflare**：

1. 登录 Cloudflare Dashboard
2. 检查 DNS 设置：
   - 确保 `tnho-fasteners.com` 的记录是 **橙色云朵**（代理开启）
   - 或者 **灰色云朵**（仅 DNS，绕过 CDN）

3. 检查 SSL/TLS 设置：
   - 设置为 **Full** 模式
   - 不是 Flexible 模式

4. 清除 Cloudflare 缓存：
   - 进入 **Caching** → **Configuration**
   - 点击 **Purge Everything**

**建议**：暂时关闭 Cloudflare 代理（改为灰色云朵），直接测试

---

### 步骤 5：检查防火墙设置

在服务器上执行：

```bash
# 检查防火墙规则
sudo iptables -L -n | grep 443

# 如果没有规则，添加规则
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT

# 保存规则
sudo service iptables save
```

---

### 步骤 6：检查 Nginx 配置

在服务器上执行：

```bash
# 1. 测试 Nginx 配置
sudo nginx -t

# 2. 查看 Nginx 错误日志
sudo tail -50 /var/log/nginx/error.log

# 3. 查看访问日志
sudo tail -50 /var/log/nginx/access.log

# 4. 重启 Nginx
sudo systemctl reload nginx
```

---

### 步骤 7：在小程序开发者工具中测试

#### 方式 1：使用真机调试（不校验域名）

1. 打开微信开发者工具
2. 点击右上角 **详情** 按钮
3. 进入 **本地设置** 标签
4. 勾选 **不校验合法域名、web-view（业务域名）、TLS 版本以及 HTTPS 证书**
5. 重新编译并测试

⚠️ **注意**：此设置仅用于开发调试，正式发布前必须取消勾选并配置正确的域名。

#### 方式 2：使用模拟器测试

1. 先在模拟器中测试
2. 查看控制台 Network 标签
3. 检查网络请求是否成功

---

## 🔧 解决方案

### 方案 1：等待域名配置生效（最常见）

如果域名配置时间少于 10 分钟：

1. ⏳ 等待 10 分钟
2. 清除小程序缓存
3. 重新测试

---

### 方案 2：临时关闭域名校验（开发调试）

1. 打开微信开发者工具
2. 点击 **详情** → **本地设置**
3. 勾选 **不校验合法域名、web-view（业务域名）、TLS 版本以及 HTTPS 证书**
4. 重新编译并测试

---

### 方案 3：临时关闭 Cloudflare 代理

1. 登录 Cloudflare Dashboard
2. 找到 `tnho-fasteners.com` 的 DNS 记录
3. 将橙色云朵改为灰色云朵（DNS only）
4. 等待 DNS 传播（约 1-2 分钟）
5. 重新测试

---

### 方案 4：检查小程序代码配置

在小程序的 `app.js` 中检查 API 地址配置：

```javascript
// 确保 apiUrl 配置正确
const apiUrl = 'https://tnho-fasteners.com';

// 确保 pages/index/index.js 中使用正确
wx.uploadFile({
  url: `${apiUrl}/api/upload-image`,
  // ...
});
```

---

### 方案 5：重启服务

在服务器上执行：

```bash
# 1. 重启 API 服务
systemctl restart tnho-api

# 2. 重启 Nginx
systemctl reload nginx

# 3. 等待几秒
sleep 5

# 4. 检查服务状态
systemctl status tnho-api
systemctl status nginx

# 5. 测试接口
curl https://tnho-fasteners.com/health
```

---

## 📊 问题诊断流程图

```
网络请求错误
    ↓
域名配置未生效？
    ↓ 是
等待 10 分钟 → 重新测试
    ↓ 否
服务是否运行？
    ↓ 否
启动服务 → systemctl start tnho-api
    ↓ 是
HTTPS 证书是否有效？
    ↓ 否
检查证书配置 → sudo certbot renew
    ↓ 是
Cloudflare 代理是否开启？
    ↓ 是
暂时关闭代理 → 重新测试
    ↓ 否
使用不校验域名模式测试
    ↓
是否成功？
    ↓ 是
问题解决 → 恢复配置
    ↓ 否
查看详细日志 → 联系技术支持
```

---

## 📝 诊断信息收集

如果问题仍未解决，请收集以下信息：

### 服务器端

```bash
# 1. 服务状态
systemctl status tnho-api > /tmp/service_status.txt

# 2. 服务日志
journalctl -u tnho-api -n 100 > /tmp/service_logs.txt

# 3. Nginx 日志
sudo tail -50 /var/log/nginx/error.log > /tmp/nginx_error.txt
sudo tail -50 /var/log/nginx/access.log > /tmp/nginx_access.txt

# 4. HTTPS 证书信息
echo | openssl s_client -connect tnho-fasteners.com:443 -servername tnho-fasteners.com 2>/dev/null | openssl x509 -noout -dates > /tmp/cert_info.txt

# 5. 网络测试
curl -v https://tnho-fasteners.com/health > /tmp/api_test.txt 2>&1
```

### 小程序端

1. 微信开发者工具的 **Console** 标签错误信息
2. 微信开发者工具的 **Network** 标签请求详情
3. 错误提示截图
4. 真机调试的设备信息（手机型号、微信版本）

---

## 🚀 预防措施

### 1. 定期检查服务状态

```bash
# 添加监控脚本
cat > /root/monitor_service.sh << 'EOF'
#!/bin/bash
if ! systemctl is-active --quiet tnho-api; then
    echo "服务未运行，正在启动..."
    systemctl start tnho-api
fi
EOF

chmod +x /root/monitor_service.sh

# 添加到 crontab（每 5 分钟检查一次）
(crontab -l 2>/dev/null; echo "*/5 * * * * /root/monitor_service.sh") | crontab -
```

### 2. 配置域名提醒

- 记录域名配置时间
- 配置后等待 10 分钟再测试
- 保存配置截图

### 3. 定期检查证书

```bash
# 检查证书有效期
echo | openssl s_client -connect tnho-fasteners.com:443 -servername tnho-fasteners.com 2>/dev/null | openssl x509 -noout -dates
```

---

## 📞 快速联系方式

如果问题仍未解决，请提供：

1. **服务器日志**：
   ```bash
   journalctl -u tnho-api -n 100 > logs.txt
   ```

2. **小程序错误信息**：
   - 控制台截图
   - Network 请求详情

3. **测试结果**：
   - 模拟器是否正常
   - 真机调试是否失败
   - 域名配置时间

---

**创建时间**：2026-01-14
**最后更新**：2026-01-14
