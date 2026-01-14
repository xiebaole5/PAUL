-- 天虹紧固件视频生成服务 - 数据库初始化脚本
-- 用途：创建数据库表结构和索引

-- 创建 video_generation_tasks 表
CREATE TABLE IF NOT EXISTS video_generation_tasks (
    id SERIAL PRIMARY KEY,
    task_id VARCHAR(255) UNIQUE NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    progress INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    error_message TEXT,
    script_content TEXT,
    video_url VARCHAR(1024),
    video_duration INTEGER,
    generation_type VARCHAR(50),
    theme VARCHAR(100),
    duration INTEGER,
    user_description TEXT,
    image_url VARCHAR(1024),
    scene_description TEXT
);

-- 创建索引以提升查询性能
CREATE INDEX IF NOT EXISTS idx_video_tasks_task_id ON video_generation_tasks(task_id);
CREATE INDEX IF NOT EXISTS idx_video_tasks_status ON video_generation_tasks(status);
CREATE INDEX IF NOT EXISTS idx_video_tasks_created_at ON video_generation_tasks(created_at DESC);

-- 添加注释
COMMENT ON TABLE video_generation_tasks IS '视频生成任务表';
COMMENT ON COLUMN video_generation_tasks.task_id IS '任务唯一标识（UUID）';
COMMENT ON COLUMN video_generation_tasks.status IS '任务状态：pending/processing/generating/merging/uploading/completed/failed';
COMMENT ON COLUMN video_generation_tasks.progress IS '任务进度（0-100）';
COMMENT ON COLUMN video_generation_tasks.generation_type IS '生成类型：video/script/image';
COMMENT ON COLUMN video_generation_tasks.theme IS '视频主题：quality_assurance/tech_innovation/industrial_application/brand_image';
COMMENT ON COLUMN video_generation_tasks.duration IS '视频时长（秒）';
COMMENT ON COLUMN video_generation_tasks.image_url IS '用户上传的图片URL（图生视频）';
COMMENT ON COLUMN video_generation_tasks.scene_description IS '用户描述的使用场景';

-- 创建更新触发器（自动更新 updated_at 字段）
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_video_tasks_updated_at ON video_generation_tasks;
CREATE TRIGGER update_video_tasks_updated_at
BEFORE UPDATE ON video_generation_tasks
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- 完成
SELECT 'Database initialized successfully!' AS message;
