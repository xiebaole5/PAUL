# Nginx SSL配置指南

## 证书已成功申请 ✅

Let's Encrypt证书已成功申请：
- **证书文件**：`/etc/letsencrypt/live/tnho-fasteners.com/fullchain.pem`
- **私钥文件**：`/etc/letsencrypt/live/tnho-fasteners.com/privkey.pem`
- **有效期**：2026-04-13（约1年3个月）
- **自动续期**：已设置

## 步骤1：安装Nginx

```bash
# 安装Nginx
sudo apt update
sudo apt install nginx -y

# 检查Nginx是否安装成功
nginx -v
```

## 步骤2：创建Nginx配置文件

```bash
# 创建站点配置文件
sudo nano /etc/nginx/sites-available/tnho-fasteners.com
```

复制以下内容到配置文件：

```nginx
# HTTP重定向到HTTPS
server {
    listen 80;
    server_name tnho-fasteners.com;

    # Let's Encrypt验证使用的路径
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    # 其他请求重定向到HTTPS
    location / {
        return 301 https://$server_name$request_uri;
    }
}

# HTTPS虚拟主机
server {
    listen 443 ssl http2;
    server_name tnho-fasteners.com;

    # SSL证书配置
    ssl_certificate /etc/letsencrypt/live/tnho-fasteners.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/tnho-fasteners.com/privkey.pem;

    # SSL协议和加密套件
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384';
    ssl_prefer_server_ciphers on;

    # SSL会话缓存
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # HSTS (可选，增强安全性)
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # 日志配置
    access_log /var/log/nginx/tnho-fasteners-access.log;
    error_log /var/log/nginx/tnho-fasteners-error.log;

    # 客户端最大上传大小
    client_max_body_size 10M;

    # API代理
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # 超时设置
        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;

        # WebSocket支持（如果需要）
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    # 静态文件服务
    location /assets/ {
        alias /app/assets/;
        expires 7d;
        add_header Cache-Control "public, immutable";
    }
}
```

## 步骤3：启用站点配置

```bash
# 创建符号链接
sudo ln -s /etc/nginx/sites-available/tnho-fasteners.com /etc/nginx/sites-enabled/

# 删除默认配置（可选）
sudo rm /etc/nginx/sites-enabled/default

# 测试Nginx配置
sudo nginx -t

# 如果显示 "syntax is ok" 和 "test is successful"，继续下一步
```

## 步骤4：创建certbot目录（用于证书验证和续期）

```bash
# 创建目录
sudo mkdir -p /var/www/certbot

# 设置权限
sudo chown -R www-data:www-data /var/www/certbot
```

## 步骤5：重启Nginx

```bash
# 重启Nginx
sudo systemctl restart nginx

# 设置Nginx开机自启
sudo systemctl enable nginx

# 检查Nginx状态
sudo systemctl status nginx
```

## 步骤6：配置防火墙（如果启用）

```bash
# 如果使用UFW防火墙
sudo ufw allow 'Nginx Full'
sudo ufw status

# 如果使用iptables
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
sudo service iptables save
```

## 步骤7：测试HTTPS访问

```bash
# 测试HTTP（应该重定向到HTTPS）
curl -I http://tnho-fasteners.com

# 测试HTTPS
curl -I https://tnho-fasteners.com

# 测试API
curl https://tnho-fasteners.com/health

# 应该返回：{"status":"ok"}
```

## 步骤8：更新小程序API地址

编辑 `miniprogram/app.js`：

```javascript
globalData: {
  // 生产环境（正式上线）：
  apiUrl: 'https://tnho-fasteners.com',
}
```

## 步骤9：配置Cloudflare SSL/TLS

1. 登录Cloudflare控制台：https://dash.cloudflare.com/
2. 选择域名 `tnho-fasteners.com`
3. 进入 **SSL/TLS** 设置
4. 将模式设置为 **Full**（不是Flexible）
5. 确保边缘证书已启用
6. 检查DNS记录是否正确（A记录指向服务器IP）

## 步骤10：配置小程序后台服务器域名

1. 登录小程序后台：https://mp.weixin.qq.com/
2. 进入 **开发 > 开发管理 > 服务器域名**
3. 添加以下域名：
   - **request合法域名**：`https://tnho-fasteners.com`
   - **uploadFile合法域名**：`https://tnho-fasteners.com`
   - **downloadFile合法域名**：`https://tnho-fasteners.com`
4. 保存并等待审核（通常1-2小时）

## 证书自动续期

Certbot已经设置了自动续期任务，可以通过以下命令查看：

```bash
# 查看续期任务
sudo systemctl status certbot.timer

# 手动测试续期
sudo certbot renew --dry-run
```

## 验证配置

完成上述配置后，访问以下URL验证：

- https://tnho-fasteners.com/health - 应该返回 `{"status":"ok"}`
- https://tnho-fasteners.com/ - 应该显示API文档或健康信息

## 常见问题

### 1. Nginx启动失败

```bash
# 查看错误日志
sudo tail -f /var/log/nginx/error.log

# 检查配置
sudo nginx -t
```

### 2. HTTPS访问失败

```bash
# 检查证书是否存在
sudo ls -la /etc/letsencrypt/live/tnho-fasteners.com/

# 检查Nginx配置中的证书路径是否正确
sudo grep ssl_certificate /etc/nginx/sites-available/tnho-fasteners.com
```

### 3. 端口被占用

```bash
# 检查80和443端口
sudo netstat -tlnp | grep -E ":80|:443"
```

## 一键配置脚本

如果需要快速配置，可以使用以下脚本：

```bash
#!/bin/bash
# nginx-ssl-setup.sh

# 安装Nginx
sudo apt update
sudo apt install nginx -y

# 创建站点配置
sudo tee /etc/nginx/sites-available/tnho-fasteners.com > /dev/null << 'EOF'
server {
    listen 80;
    server_name tnho-fasteners.com;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://$server_name$request_uri;
    }
}

server {
    listen 443 ssl http2;
    server_name tnho-fasteners.com;

    ssl_certificate /etc/letsencrypt/live/tnho-fasteners.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/tnho-fasteners.com/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;

    access_log /var/log/nginx/tnho-fasteners-access.log;
    error_log /var/log/nginx/tnho-fasteners-error.log;

    client_max_body_size 10M;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
    }

    location /assets/ {
        alias /app/assets/;
        expires 7d;
        add_header Cache-Control "public, immutable";
    }
}
EOF

# 创建certbot目录
sudo mkdir -p /var/www/certbot
sudo chown -R www-data:www-data /var/www/certbot

# 启用站点
sudo ln -s /etc/nginx/sites-available/tnho-fasteners.com /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# 测试配置
sudo nginx -t

# 重启Nginx
sudo systemctl restart nginx
sudo systemctl enable nginx

echo "✅ Nginx配置完成！"
echo "🌐 HTTPS访问：https://tnho-fasteners.com"
echo "🔍 健康检查：https://tnho-fasteners.com/health"
```

保存为 `nginx-ssl-setup.sh`，然后执行：

```bash
chmod +x nginx-ssl-setup.sh
./nginx-ssl-setup.sh
```

---

**配置完成后，记得更新小程序API地址并配置Cloudflare！**
