# SSH 登录服务器指南

## 方法1：使用 SSH 命令（推荐）

### Windows 用户

#### 使用 CMD 或 PowerShell
```bash
ssh root@47.110.72.148
```

#### 使用 Git Bash（推荐）
```bash
ssh root@47.110.72.148
```

### macOS / Linux 用户
```bash
ssh root@47.110.72.148
```

### 输入密码
- 用户名：`root`
- 主机：`47.110.72.148`
- 密码：（输入服务器密码，输入时不会显示字符）

### 首次登录提示
如果是首次登录，会看到类似提示：
```
The authenticity of host '47.110.72.148 (47.110.72.148)' can't be established.
ED25519 key fingerprint is SHA256:xxx...
Are you sure you want to continue connecting (yes/no)?
```

输入 `yes` 并回车确认。

## 方法2：使用 SSH 密钥（更安全）

### 生成 SSH 密钥对
```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

按提示操作，可以一路回车使用默认设置。

### 复制公钥到服务器
```bash
ssh-copy-id root@47.110.72.148
```

或者手动复制：
```bash
# 查看公钥
cat ~/.ssh/id_ed25519.pub

# 复制公钥内容后，在服务器上执行：
echo "你的公钥内容" >> ~/.ssh/authorized_keys
```

### 使用密钥登录
```bash
ssh root@47.110.72.148
```

现在无需输入密码即可登录。

## 方法3：使用 SSH 配置文件（便捷）

### 创建配置文件
在 `~/.ssh/config` 中添加：

```text
Host tnho
    HostName 47.110.72.148
    User root
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

### 登录
```bash
ssh tnho
```

## 方法4：使用 PuTTY（Windows 图形界面）

### 下载 PuTTY
访问：https://www.putty.org/

### 配置 PuTTY
1. 打开 PuTTY
2. Host Name (or IP address): `47.110.72.148`
3. Port: `22`
4. Connection type: `SSH`
5. 点击 "Open"

### 输入用户名和密码
- `login as:` 输入 `root`
- `root@47.110.72.148's password:` 输入密码

## 登录后的操作

### 进入项目目录
```bash
cd /root/tnho-video
```

### 查看当前目录
```bash
pwd
# 输出: /root/tnho-video
```

### 拉取最新代码
```bash
git pull origin main
```

### 查看配置
```bash
grep -A 10 "pool_size=" src/storage/database/db.py
```

### 重启应用
```bash
source venv/bin/activate
pkill -f "uvicorn app:app"
sleep 2
nohup uvicorn app:app --host 0.0.0.0 --port 8000 --workers 1 --log-level info >> logs/app.log 2>&1 &
```

### 测试服务
```bash
curl -s https://tnho-fasteners.com/api/health
```

### 查看日志
```bash
tail -f logs/app.log
```

### 退出服务器
```bash
exit
# 或按 Ctrl+D
```

## 常见问题

### 问题1：Connection refused
**原因**：SSH 服务未运行或端口被防火墙阻止

**解决**：
1. 检查服务器SSH服务是否运行
2. 检查防火墙设置

### 问题2：Connection timed out
**原因**：网络连接问题

**解决**：
1. 检查网络连接
2. 尝试 ping 服务器：`ping 47.110.72.148`
3. 检查服务器是否在线

### 问题3：Permission denied (publickey)
**原因**：密钥配置错误

**解决**：
1. 检查 `~/.ssh/authorized_keys` 权限：`chmod 600 ~/.ssh/authorized_keys`
2. 检查密钥路径是否正确

### 问题4：密码输入错误
**原因**：密码错误或 Caps Lock 开启

**解决**：
1. 检查 Caps Lock 是否开启
2. 确认密码是否正确
3. 联系服务器管理员重置密码

## 一键登录脚本

### 创建快捷脚本

在 `~/.bashrc` 或 `~/.zshrc` 中添加：

```bash
alias tnho='ssh root@47.110.72.148'
```

### 重新加载配置
```bash
source ~/.bashrc
# 或
source ~/.zshrc
```

### 登录
```bash
tnho
```

## 安全建议

### 1. 使用 SSH 密钥而非密码
密码登录不够安全，建议使用 SSH 密钥。

### 2. 禁用密码登录
在服务器上编辑 `/etc/ssh/sshd_config`：
```bash
PasswordAuthentication no
```

### 3. 修改默认端口
在 `/etc/ssh/sshd_config` 中修改：
```bash
Port 2222
```

### 4. 限制登录用户
在 `/etc/ssh/sshd_config` 中添加：
```bash
AllowUsers root
```

### 5. 使用防火墙
```bash
# 只允许特定IP访问
ufw allow from your_ip_address to any port 22
```

## 服务器信息

- **IP 地址**: 47.110.72.148
- **用户名**: root
- **项目目录**: /root/tnho-video
- **API 地址**: https://tnho-fasteners.com

## 快速参考

```bash
# 登录
ssh root@47.110.72.148

# 进入项目目录
cd /root/tnho-video

# 拉取代码
git pull origin main

# 验证配置
grep -A 10 "pool_size=" src/storage/database/db.py

# 重启应用
source venv/bin/activate
pkill -f "uvicorn app:app"
sleep 2
nohup uvicorn app:app --host 0.0.0.0 --port 8000 --workers 1 --log-level info >> logs/app.log 2>&1 &

# 测试连接
python -c "from storage.database.db import get_session; db = get_session(); print('✓ 成功'); db.close()"

# 测试API
curl -s https://tnho-fasteners.com/api/health

# 查看日志
tail -f logs/app.log

# 退出
exit
```

---
**创建日期**: 2025-02-06
