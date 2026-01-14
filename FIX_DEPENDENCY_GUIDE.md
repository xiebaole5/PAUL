# 服务依赖修复指南

## 问题诊断

服务启动失败，错误信息：
```
RuntimeError: Form data requires "python-multipart" to be installed.
```

**原因**: FastAPI 需要处理文件上传（`multipart/form-data`），但缺少 `python-multipart` 依赖。

## 修复方案

已在本地代码仓库中添加 `python-multipart` 依赖，并创建了修复脚本。

### 方案一：使用修复脚本（推荐）

在服务器上运行以下命令：

```bash
# 1. 进入项目目录
cd /root/PAUL

# 2. 拉取最新代码
git pull origin main

# 3. 运行修复脚本
bash fix_service_dependency.sh
```

### 方案二：手动修复

如果脚本执行失败，可以手动执行以下步骤：

```bash
# 1. 进入项目目录
cd /root/PAUL

# 2. 停止服务
systemctl stop tnho-api

# 3. 激活虚拟环境
source venv/bin/activate

# 4. 安装 python-multipart
pip install python-multipart --index-url https://mirrors.aliyun.com/pypi/simple/

# 5. 重启服务
systemctl start tnho-api

# 6. 检查服务状态
systemctl status tnho-api

# 7. 查看日志
journalctl -u tnho-api -n 50 --no-pager
```

## 验证修复

### 1. 检查服务状态

```bash
systemctl status tnho-api
```

**预期输出**:
```
● tnho-api.service - 天虹紧固件视频生成 API 服务
   Loaded: loaded (/etc/systemd/system/tnho-api.service; enabled; preset: enabled)
   Active: active (running) since ...
```

### 2. 测试健康检查接口

```bash
curl http://localhost:8000/health
```

**预期输出**:
```json
{
  "status": "healthy",
  "message": "天虹紧固件视频生成 API 服务运行正常"
}
```

### 3. 测试图片上传接口

```bash
curl -X POST http://localhost:8000/api/upload-image \
  -F "file=@/path/to/test/image.jpg"
```

**预期输出**:
```json
{
  "url": "https://tnho-video.oss-cn-hangzhou.aliyuncs.com/...",
  "message": "图片上传成功"
}
```

## 常见问题

### Q1: 安装 python-multipart 失败

**解决方案**:
```bash
# 尝试使用官方源
pip install python-multipart

# 或者升级 pip
pip install --upgrade pip
pip install python-multipart
```

### Q2: 服务启动后仍然报错

**解决方案**:
```bash
# 查看详细日志
journalctl -u tnho-api -f

# 检查虚拟环境
source venv/bin/activate
pip list | grep python-multipart
```

### Q3: coze_coding_dev_sdk 模块缺失

**解决方案**:
```bash
source venv/bin/activate
pip install coze-coding-dev-sdk --index-url https://mirrors.aliyun.com/pypi/simple/
```

## 更新说明

### requirements.txt 变更

**添加**:
- `python-multipart==0.0.20` - 支持 FastAPI 文件上传

**移除**:
- `dbus-python` - 导致安装失败
- `PyGObject` - 导致安装失败
- 其他不必要的依赖

### 新增文件

- `fix_service_dependency.sh` - 自动化修复脚本

## 后续步骤

1. ✅ 运行修复脚本
2. ✅ 验证服务启动成功
3. ✅ 测试 API 接口
4. ✅ 配置小程序服务器域名（如果需要）
5. ✅ 提交小程序审核（如果需要）

## 联系支持

如果遇到其他问题，请提供以下信息：
- 服务日志: `journalctl -u tnho-api -n 100 --no-pager`
- 依赖列表: `pip list`
- 错误信息截图
