# 天虹紧固件视频生成服务 - 快速部署指南

## 一键部署（推荐）

在服务器上执行以下命令：

```bash
# 1. 克隆代码
cd /root
git clone https://github.com/xiebaole5/PAUL.git
cd PAUL

# 2. 执行部署脚本
chmod +x scripts/*.sh
bash scripts/deploy.sh
```

部署脚本会自动完成：
- ✅ 克隆代码
- ✅ 创建虚拟环境
- ✅ 安装依赖
- ✅ 启动 PostgreSQL 数据库
- ✅ 初始化数据库表
- ✅ 创建 systemd 服务

## 配置环境变量

部署完成后，**必须**配置环境变量：

```bash
vim /root/PAUL/.env
```

**重要配置项：**

```env
# 对象存储（必须填写正确的密钥）
S3_ACCESS_KEY_ID=your_access_key_here
S3_SECRET_ACCESS_KEY=your_secret_key_here
S3_BUCKET=your_bucket_name_here

# 其他配置可使用默认值
PGDATABASE_URL=postgresql://postgres:postgres123@localhost:5432/tnho_video
EXTERNAL_BASE_URL=https://tnho-fasteners.com
ARK_API_KEY=39bf20d0-55b5-4957-baa1-02f4529a3076
```

## 启动服务

```bash
bash /root/PAUL/scripts/start-service.sh
```

## 验证服务

```bash
# 查看服务状态
systemctl status tnho-api

# 查看 API 文档
# 浏览器访问：https://tnho-fasteners.com/docs

# 测试健康检查
curl https://tnho-fasteners.com/health
```

## 常用命令

```bash
# 启动服务
systemctl start tnho-api
bash /root/PAUL/scripts/start-service.sh

# 停止服务
systemctl stop tnho-api
bash /root/PAUL/scripts/stop-service.sh

# 重启服务
systemctl restart tnho-api
bash /root/PAUL/scripts/restart-service.sh

# 查看日志
journalctl -u tnho-api -f
```

## 小程序配置

1. 登录微信小程序后台
2. 配置服务器域名：
   - request: `https://tnho-fasteners.com`
   - uploadFile: `https://tnho-fasteners.com`
   - downloadFile: `https://tnho-fasteners.com`
3. 上传小程序代码并发布

## 完整文档

详细部署指南请参考：`docs/服务器部署指南.md`

故障排查：
- 数据库连接问题：`docs/数据库连接问题修复方案-最终版.md`
- 小程序视频生成问题：`docs/小程序视频生成失败排查指南.md`
- 小程序功能测试：`docs/小程序端功能测试指南.md`

## 获取帮助

如有问题，请查看日志：

```bash
# 查看服务日志
journalctl -u tnho-api -n 50

# 查看数据库日志
docker logs tnho-postgres

# 查看数据库连接
docker exec -it tnho-postgres psql -U postgres -d tnho_video -c "SELECT * FROM pg_stat_activity;"
```
