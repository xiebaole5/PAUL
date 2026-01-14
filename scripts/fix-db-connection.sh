#!/bin/bash
# 数据库连接问题诊断和修复脚本
# 使用方法: bash scripts/fix-db-connection.sh

echo "=========================================="
echo "数据库连接问题 - 诊断和修复"
echo "=========================================="
echo ""

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. 检查数据库连接
echo "1. 测试数据库连接..."
python3 << 'EOF'
import os
import sys
from pathlib import Path

# 添加 src 到路径
current_dir = Path.cwd()
src_path = current_dir / "src"
if str(src_path) not in sys.path:
    sys.path.insert(0, str(src_path))

# 手动读取 .env 文件
env_file = current_dir / ".env"
if env_file.exists():
    with open(env_file) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                key, value = line.split('=', 1)
                os.environ[key] = value

try:
    from storage.database.db import get_session
    from sqlalchemy import text
    
    # 测试多个连接
    print("  测试1: 基本连接...")
    db1 = get_session()
    result1 = db1.execute(text("SELECT 1"))
    print(f"  ✓ 连接1成功: {result1.fetchone()}")
    
    print("  测试2: 并发连接...")
    import threading
    import time
    
    results = []
    errors = []
    
    def test_connection(i):
        try:
            db = get_session()
            result = db.execute(text(f"SELECT {i}"))
            results.append(result.fetchone()[0])
            db.close()
        except Exception as e:
            errors.append((i, str(e)))
    
    threads = []
    for i in range(10):
        t = threading.Thread(target=test_connection, args=(i,))
        threads.append(t)
        t.start()
    
    for t in threads:
        t.join()
    
    if len(results) == 10:
        print(f"  ✓ 10个并发连接全部成功")
    else:
        print(f"  ⚠ 部分连接失败: 成功 {len(results)}/10, 失败 {len(errors)}/10")
        for i, err in errors:
            print(f"    连接{i}失败: {err}")
    
    db1.close()
    sys.exit(0)
except Exception as e:
    print(f"✗ 数据库连接失败: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
EOF

if [ $? -ne 0 ]; then
    echo -e "${RED}数据库连接测试失败${NC}"
    echo ""
    echo "可能原因:"
    echo "1. 数据库服务不可用"
    echo "2. 数据库连接字符串错误"
    echo "3. 网络连接问题"
    echo "4. 数据库用户权限不足"
    echo ""
    echo "建议操作:"
    echo "1. 检查 .env 文件中的 PGDATABASE_URL"
    echo "2. 尝试重新连接数据库"
    exit 1
fi

# 2. 检查当前的连接池配置
echo ""
echo "2. 检查连接池配置..."
python3 << 'EOF'
import os
import sys
from pathlib import Path

current_dir = Path.cwd()
src_path = current_dir / "src"
if str(src_path) not in sys.path:
    sys.path.insert(0, str(src_path))

env_file = current_dir / ".env"
if env_file.exists():
    with open(env_file) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                key, value = line.split('=', 1)
                os.environ[key] = value

from storage.database.db import get_engine

engine = get_engine()
pool = engine.pool

print(f"  连接池类型: {type(pool).__name__}")
print(f"  连接池大小: {pool.size()}")
print(f"  已用连接: {pool.checkedout()}")
print(f"  空闲连接: {pool.checkedin()}")

# 检查连接池状态
from sqlalchemy import text
with engine.connect() as conn:
    result = conn.execute(text("SELECT version()"))
    version = result.fetchone()[0]
    print(f"  数据库版本: {version.split()[1]}")

EOF

# 3. 检查活跃的任务
echo ""
echo "3. 检查活跃的视频生成任务..."
python3 << 'EOF'
import os
import sys
from pathlib import Path

current_dir = Path.cwd()
src_path = current_dir / "src"
if str(src_path) not in sys.path:
    sys.path.insert(0, str(src_path))

env_file = current_dir / ".env"
if env_file.exists():
    with open(env_file) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                key, value = line.split('=', 1)
                os.environ[key] = value

from storage.database.db import get_session
from sqlalchemy import text

db = get_session()
try:
    result = db.execute(text("""
        SELECT
            status,
            COUNT(*) as count,
            MAX(created_at) as latest
        FROM video_generation_tasks
        WHERE created_at > NOW() - INTERVAL '1 hour'
        GROUP BY status
        ORDER BY status
    """))
    
    print("  最近1小时的任务统计:")
    for row in result:
        print(f"    - {row[0]}: {row[1]} (最新: {row[1]})")
    
    # 检查是否有卡住的任务
    result = db.execute(text("""
        SELECT COUNT(*)
        FROM video_generation_tasks
        WHERE status IN ('generating', 'merging', 'uploading')
        AND created_at < NOW() - INTERVAL '10 minutes'
    """))
    stuck_count = result.fetchone()[0]
    
    if stuck_count > 0:
        print(f"  ⚠ 发现 {stuck_count} 个可能卡住的任务（超过10分钟未更新）")
    
    db.close()
except Exception as e:
    print(f"  ✗ 查询失败: {e}")

EOF

# 4. 查看应用日志中的数据库错误
echo ""
echo "4. 查看最近的数据库错误日志..."
if [ -f "/root/tnho-video/logs/app.log" ]; then
    echo "  最近的数据库相关错误:"
    tail -200 /root/tnho-video/logs/app.log | grep -iE "psycopg2|database|sql|pool|connection" | tail -10
else
    echo "  ⚠ 日志文件不存在"
fi

# 5. 提供修复建议
echo ""
echo "=========================================="
echo "修复建议"
echo "=========================================="
echo ""
echo "方案1: 重启应用（清理连接池）"
echo "  cd /root/tnho-video"
echo "  pkill -f 'uvicorn app:app'"
echo "  sleep 2"
echo "  nohup uvicorn app:app --host 0.0.0.0 --port 8000 --workers 1 --log-level info >> logs/app.log 2>&1 &"
echo ""
echo "方案2: 优化连接池配置"
echo "  编辑 src/storage/database/db.py"
echo "  调整连接池参数:"
echo "    pool_size: 当前 20 -> 建议 10（减少并发）"
echo "    max_overflow: 当前 30 -> 建议 10"
echo "    pool_timeout: 当前 60 -> 建议 30"
echo "    statement_timeout: 当前 60 -> 建议 30"
echo ""
echo "方案3: 清理卡住的任务"
echo "  执行: bash /root/tnho-video/scripts/fix-tasks.sh"
echo ""

# 提供一键修复选项
echo "是否执行一键修复？（重启应用）"
read -p "输入 y 继续，其他键取消: " choice

if [ "$choice" = "y" ] || [ "$choice" = "Y" ]; then
    echo ""
    echo "正在重启应用..."
    pkill -f "uvicorn app:app"
    sleep 3
    
    # 检查是否还有进程
    if pgrep -f "uvicorn app:app" > /dev/null; then
        echo "  ⚠ 部分进程仍在运行，强制终止..."
        pkill -9 -f "uvicorn app:app"
        sleep 2
    fi
    
    nohup uvicorn app:app --host 0.0.0.0 --port 8000 --workers 1 --log-level info >> logs/app.log 2>&1 &
    
    sleep 3
    
    if pgrep -f "uvicorn app:app" > /dev/null; then
        echo -e "${GREEN}✓ 应用重启成功${NC}"
        ps aux | grep "uvicorn app:app" | grep -v grep | head -1
    else
        echo -e "${RED}✗ 应用重启失败${NC}"
    fi
else
    echo "已取消一键修复"
fi

echo ""
echo "=========================================="
echo "完成"
echo "=========================================="
