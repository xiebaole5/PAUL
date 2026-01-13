# PowerShell 上传脚本 - 将最新 API 代码上传到服务器

# 配置
$SERVER = "root@47.110.72.148"
$LOCAL_PATH = "/workspace/projects"
$TEMP_FILE = "tnho-api-update.tar.gz"

Write-Host "======================================" -ForegroundColor Green
Write-Host "上传最新 API 代码到服务器" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host ""

# 1. 创建压缩包
Write-Host "步骤 1: 创建压缩包..." -ForegroundColor Yellow
$tarCmd = "tar -czf /tmp/$TEMP_FILE -C $LOCAL_PATH src/api/app.py src/agents/ src/tools/ src/storage/ config/"
Invoke-Expression $tarCmd

if (Test-Path "/tmp/$TEMP_FILE") {
    Write-Host "✅ 压缩包创建成功" -ForegroundColor Green
} else {
    Write-Host "❌ 压缩包创建失败" -ForegroundColor Red
    exit 1
}

# 2. 上传到服务器
Write-Host ""
Write-Host "步骤 2: 上传到服务器..." -ForegroundColor Yellow
$scpCmd = "scp /tmp/$TEMP_FILE ${SERVER}:/root/"
Invoke-Expression $scpCmd

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ 文件上传成功" -ForegroundColor Green
} else {
    Write-Host "❌ 文件上传失败" -ForegroundColor Red
    exit 1
}

# 3. 在服务器上解压并部署
Write-Host ""
Write-Host "步骤 3: 在服务器上部署..." -ForegroundColor Yellow
$sshDeployCmd = @"
cd /root/tnho-video-api

# 备份旧文件
cp app.py app.py.backup.old

# 解压新文件
tar -xzf /root/$TEMP_FILE -C /root/tnho-video-api --strip-components=1

# 复制新的 app.py
cp src/api/app.py app.py

# 检查路由数量
echo "新版本 API 路由数量:"
grep -c "@app\." app.py

# 重启容器
docker-compose down
docker-compose up -d

# 等待启动
sleep 10

# 检查 API 端点
echo "检查 API 端点:"
curl -s http://localhost:8000/openapi.json | grep -o '"/[^"]*"' | head -10

# 清理临时文件
rm -f /root/$TEMP_FILE
"@

ssh $SERVER $sshDeployCmd

Write-Host ""
Write-Host "======================================" -ForegroundColor Green
Write-Host "部署完成！" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host ""
Write-Host "现在可以测试 API：" -ForegroundColor Cyan
Write-Host "  curl http://tnho-fasteners.com/api/generate-video -X POST -H 'Content-Type: application/json' -d '{`"product_name`":`"高强度螺栓`",`"theme`":`"品质保证`",`"duration`":10,`"type`":`"video`"}'" -ForegroundColor White
