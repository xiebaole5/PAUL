#!/bin/bash
# 数据库连接测试脚本

echo "测试数据库连接..."

python3 << 'EOF'
import sys
import os
from dotenv import load_dotenv

# 加载环境变量
load_dotenv()

# 获取数据库URL
db_url = os.getenv("PGDATABASE_URL")
print(f"数据库URL: {db_url[:50]}...")

# 测试连接
try:
    from sqlalchemy import create_engine, text
    engine = create_engine(db_url, pool_pre_ping=True)

    with engine.connect() as conn:
        result = conn.execute(text("SELECT version()"))
        version = result.fetchone()[0]
        print(f"✓ 数据库连接成功")
        print(f"  PostgreSQL版本: {version.split()[1]}")

        # 检查表是否存在
        result = conn.execute(text("""
            SELECT EXISTS (
                SELECT FROM information_schema.tables
                WHERE table_name = 'video_generation_tasks'
            )
        """))
        exists = result.fetchone()[0]
        print(f"  video_generation_tasks表: {'存在' if exists else '不存在'}")

        if exists:
            # 统计任务数量
            result = conn.execute(text("""
                SELECT
                    status,
                    COUNT(*) as count
                FROM video_generation_tasks
                GROUP BY status
            """))
            print(f"  任务统计:")
            for row in result:
                print(f"    - {row[0]}: {row[1]}")

except Exception as e:
    print(f"✗ 数据库连接失败: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)

EOF
