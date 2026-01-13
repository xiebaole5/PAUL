# TNHO 视频生成服务 - 上传并部署脚本
# 在 Windows PowerShell 中执行

# 服务器配置
$serverHost = "47.110.72.148"
$serverUser = "root"
$remoteDir = "/root/tnho-video"
$localTarPath = "/tmp/tnho-complete-code.tar.gz"

# 检查本地文件是否存在
if (-not (Test-Path $localTarPath)) {
    Write-Host "错误: 未找到本地代码压缩包: $localTarPath" -ForegroundColor Red
    Write-Host "请先在 Linux 环境中执行: tar -czf /tmp/tnho-complete-code.tar.gz ." -ForegroundColor Yellow
    exit 1
}

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "TNHO 视频生成服务部署" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# 检查是否安装了 SCP 客户端
$scpPath = Get-Command scp -ErrorAction SilentlyContinue
if (-not $scpPath) {
    Write-Host "❌ 未找到 SCP 命令" -ForegroundColor Red
    Write-Host "请安装 OpenSSH 客户端:" -ForegroundColor Yellow
    Write-Host "  1. 打开 设置 -> 应用 -> 可选功能" -ForegroundColor Gray
    Write-Host "  2. 搜索 'OpenSSH 客户端' 并安装" -ForegroundColor Gray
    exit 1
}

# 上传文件
Write-Host "步骤 1: 上传代码压缩包到服务器..." -ForegroundColor Green
Write-Host "从: $localTarPath" -ForegroundColor Gray
Write-Host "到: $serverHost:$remoteDir/" -ForegroundColor Gray
Write-Host ""

scp $localTarPath "${serverUser}@${serverHost}:/tmp/tnho-complete-code.tar.gz"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ 上传失败" -ForegroundColor Red
    exit 1
}

Write-Host "✅ 上传成功" -ForegroundColor Green
Write-Host ""

# 在服务器上执行部署
Write-Host "步骤 2: 在服务器上执行部署..." -ForegroundColor Green
Write-Host ""

$deployCommands = @"
# 创建项目目录
mkdir -p /root/tnho-video
cd /root/tnho-video

# 停止现有容器
docker-compose down 2>/dev/null || true

# 备份现有代码
if [ -d "src" ]; then
    tar -czf backup-$(date +%Y%m%d-%H%M%S).tar.gz src/
fi

# 移动压缩包到项目目录
mv /tmp/tnho-complete-code.tar.gz .

# 创建目录结构
mkdir -p src/agents src/api src/llm src/storage/{database,memory,s3} src/utils/messages src/graphs config logs scripts

# 解压代码
tar -xzf tnho-complete-code.tar.gz

# 检查 .env 文件
if [ ! -f ".env" ]; then
    echo "创建 .env 文件..."
    cat > .env << 'ENVEOF'
ARK_API_KEY=39bf20d0-55b5-4957-baa1-02f4529a3076
ARK_BASE_URL=https://ark.cn-beijing.volces.com/api/v3
S3_ENDPOINT=https://tos-s3-cn-beijing.volces.com
S3_ACCESS_KEY_ID=your_access_key_id
S3_SECRET_ACCESS_KEY=your_secret_access_key
S3_BUCKET=tnho-videos
S3_REGION=cn-beijing
PGDATABASE_URL=postgresql://postgres:postgres123@db:5432/tnho_video
APP_HOST=0.0.0.0
APP_PORT=8000
LOG_LEVEL=info
ENVEOF
fi

# 修复文件权限
chmod +x scripts/*.sh

# 构建并启动容器
docker-compose down 2>/dev/null || true
docker-compose build
docker-compose up -d

# 等待服务启动
sleep 10

# 检查服务状态
docker-compose ps

# 测试健康检查
curl -f http://localhost:8000/health
"@

ssh "${serverUser}@${serverHost}" $deployCommands

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ 部署失败" -ForegroundColor Red
    Write-Host "请检查 SSH 连接和服务器配置" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "部署完成！" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "API 文档: http://tnho-fasteners.com/docs" -ForegroundColor White
Write-Host "健康检查: http://tnho-fasteners.com/health" -ForegroundColor White
Write-Host ""
Write-Host "常用命令:" -ForegroundColor Yellow
Write-Host "  SSH 登录: ssh root@$serverHost" -ForegroundColor Gray
Write-Host "  查看日志: docker-compose logs -f" -ForegroundColor Gray
Write-Host "  重启服务: docker-compose restart" -ForegroundColor Gray
Write-Host "  停止服务: docker-compose down" -ForegroundColor Gray
Write-Host ""
