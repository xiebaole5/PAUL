# PowerShell 上传完整代码到服务器

$SERVER = "root@47.110.72.148"
$LOCAL_PATH = "/workspace/projects"

Write-Host "======================================" -ForegroundColor Green
Write-Host "上传完整代码到服务器" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host ""

# 1. 创建压缩包（排除不必要的文件）
Write-Host "步骤 1: 创建压缩包..." -ForegroundColor Yellow

$tarCmd = "tar -czf /tmp/tnho-full-code.tar.gz " +
           "-C $LOCAL_PATH " +
           "--exclude='.git' " +
           "--exclude='__pycache__' " +
           "--exclude='*.pyc' " +
           "--exclude='logs/*' " +
           "--exclude='assets/uploads/*' " +
           "--exclude='node_modules' " +
           "--exclude='dist' " +
           "--exclude='.env.local' " +
           "--exclude='tnho-latest.tar.gz' " +
           "src/ config/ app.py requirements.txt docker-compose.yml Dockerfile .env.example"

Invoke-Expression $tarCmd

if (Test-Path "/tmp/tnho-full-code.tar.gz") {
    Write-Host "✅ 压缩包创建成功" -ForegroundColor Green
    $fileSize = (Get-Item "/tmp/tnho-full-code.tar.gz").Length / 1MB
    Write-Host "   文件大小: $([math]::Round($fileSize, 2)) MB" -ForegroundColor Cyan
} else {
    Write-Host "❌ 压缩包创建失败" -ForegroundColor Red
    exit 1
}

# 2. 上传到服务器
Write-Host ""
Write-Host "步骤 2: 上传到服务器 (可能需要几分钟)..." -ForegroundColor Yellow

$scpCmd = "scp /tmp/tnho-full-code.tar.gz ${SERVER}:/root/"
Invoke-Expression $scpCmd

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ 文件上传成功" -ForegroundColor Green
} else {
    Write-Host "❌ 文件上传失败" -ForegroundColor Red
    exit 1
}

# 3. 在服务器上部署
Write-Host ""
Write-Host "步骤 3: 在服务器上部署..." -ForegroundColor Yellow

$sshDeployCmd = @"
cd /root/tnho-video-api

# 备份当前目录
echo "备份当前目录..."
tar -czf /root/tnho-video-api.backup.`date +%Y%m%d_%H%M%S`.tar.gz .

# 解压新代码
echo "解压新代码..."
tar -xzf /root/tnho-full-code.tar.gz

# 检查目录结构
echo "检查目录结构..."
ls -la src/
ls -la src/agents/ 2>/dev/null || echo "  ⚠️  agents/ 目录不存在"

# 检查 app.py
echo ""
echo "检查 app.py..."
wc -l app.py
echo "路由数量:"
grep -c "@app\." app.py

# 重启容器
echo ""
echo "重启 Docker 容器..."
docker-compose down
docker-compose up -d --build

# 等待容器启动
echo "等待容器启动 (15秒)..."
sleep 15

# 检查容器状态
echo ""
echo "容器状态:"
docker ps | grep tnho

# 检查 API 端点
echo ""
echo "检查 API 端点:"
curl -s http://localhost:8000/openapi.json | python3 -c "import sys, json; data = json.load(sys.stdin); print('总路由数:', len(data.get('paths', {}))); [print('  ', k) for k in sorted(data.get('paths', {}).keys())]"

# 清理临时文件
rm -f /root/tnho-full-code.tar.gz

echo ""
echo "======================================"
echo "部署完成！"
echo "======================================"
"@

ssh $SERVER $sshDeployCmd

Write-Host ""
Write-Host "======================================" -ForegroundColor Green
Write-Host "部署完成！" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host ""
Write-Host "现在可以测试 API：" -ForegroundColor Cyan
Write-Host "  curl http://tnho-fasteners.com/api/generate-video -X POST -H 'Content-Type: application/json' -d '{`"product_name`":`"高强度螺栓`",`"theme`":`"品质保证`",`"duration`":10,`"type`":`"video`"}'" -ForegroundColor White
Write-Host ""
Write-Host "或者查看 API 文档：" -ForegroundColor Cyan
Write-Host "  http://tnho-fasteners.com/docs" -ForegroundColor White
