"""
数据库初始化模块
创建数据库表结构
"""
from sqlalchemy import text
from storage.database.db import get_engine

def init_db():
    """
    初始化数据库表
    
    创建 video_generation_tasks 表（如果不存在）
    """
    engine = get_engine()
    
    # 创建表的 SQL
    create_table_sql = """
    CREATE TABLE IF NOT EXISTS video_generation_tasks (
        id SERIAL PRIMARY KEY,
        task_id VARCHAR(64) UNIQUE NOT NULL,
        session_id VARCHAR(64),
        product_name VARCHAR(255) NOT NULL,
        theme VARCHAR(50) NOT NULL,
        duration INTEGER NOT NULL,
        type VARCHAR(20) NOT NULL,
        status VARCHAR(30) NOT NULL DEFAULT 'pending',
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
    """
    
    try:
        with engine.connect() as conn:
            # 执行建表 SQL
            conn.execute(text(create_table_sql))
            conn.commit()
            print("✅ 数据库表创建成功")
            
            # 验证表是否存在
            result = conn.execute(text("""
                SELECT EXISTS (
                    SELECT 1 FROM information_schema.tables 
                    WHERE table_name = 'video_generation_tasks'
                );
            """))
            exists = result.scalar()
            
            if exists:
                print("✅ 表 video_generation_tasks 存在")
            else:
                print("❌ 表 video_generation_tasks 不存在")
                
    except Exception as e:
        print(f"❌ 数据库初始化失败: {e}")
        raise


if __name__ == "__main__":
    init_db()
