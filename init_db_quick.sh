#!/bin/bash
# 快速数据库初始化脚本
# 在阿里云服务器上运行此脚本

cd /root/PAUL

# 激活虚拟环境
source venv/bin/activate

# 运行数据库初始化
python -c "
import os
import sys
from sqlalchemy import create_engine, text

# 从环境变量读取数据库配置
database_url = os.getenv('PGDATABASE_URL')
if not database_url:
    print('❌ 错误: 未找到 PGDATABASE_URL 环境变量')
    sys.exit(1)

print(f'数据库URL: {database_url[:50]}...')

try:
    engine = create_engine(database_url)
    
    # 创建表的 SQL
    create_table_sql = '''
    CREATE TABLE IF NOT EXISTS video_generation_tasks (
        id SERIAL PRIMARY KEY,
        task_id VARCHAR(64) UNIQUE NOT NULL,
        session_id VARCHAR(64),
        product_name VARCHAR(255) NOT NULL,
        theme VARCHAR(50) NOT NULL,
        duration INTEGER NOT NULL,
        type VARCHAR(20) NOT NULL,
        status VARCHAR(30) NOT NULL DEFAULT \"pending\",
        progress INTEGER NOT NULL DEFAULT 0,
        current_step VARCHAR(255),
        total_parts INTEGER NOT NULL DEFAULT 1,
        completed_parts INTEGER NOT NULL DEFAULT 0,
        video_urls JSON,
        merged_video_url TEXT,
        script_content TEXT,
        error_message TEXT,
        created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE,
        completed_at TIMESTAMP WITH TIME ZONE
    );

    CREATE INDEX IF NOT EXISTS idx_video_tasks_task_id ON video_generation_tasks(task_id);
    CREATE INDEX IF NOT EXISTS idx_video_tasks_session_id ON video_generation_tasks(session_id);
    CREATE INDEX IF NOT EXISTS idx_video_tasks_status ON video_generation_tasks(status);
    CREATE INDEX IF NOT EXISTS idx_video_tasks_created_at ON video_generation_tasks(created_at DESC);
    '''
    
    with engine.connect() as conn:
        conn.execute(text(create_table_sql))
        conn.commit()
        
        # 验证表是否存在
        result = conn.execute(text('''
            SELECT EXISTS (
                SELECT 1 FROM information_schema.tables 
                WHERE table_name = \"video_generation_tasks\"
            );
        '''))
        exists = result.scalar()
        
        if exists:
            print('✅ 表 video_generation_tasks 创建成功')
            
            # 查询表结构
            result = conn.execute(text('''
                SELECT column_name, data_type 
                FROM information_schema.columns 
                WHERE table_name = \"video_generation_tasks\" 
                ORDER BY ordinal_position;
            '''))
            print('\\n📋 表结构:')
            for row in result:
                print(f\"  - {row[0]}: {row[1]}\")
        else:
            print('❌ 表 video_generation_tasks 不存在')
            
except Exception as e:
    print(f'❌ 数据库初始化失败: {e}')
    import traceback
    traceback.print_exc()
    sys.exit(1)
"

echo ""
echo "=========================================="
echo "数据库初始化完成"
echo "=========================================="
