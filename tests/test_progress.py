"""
测试视频生成进度功能
"""
import sys
sys.path.insert(0, '/workspace/projects/src')

from storage.database.db import get_session
from storage.database.video_task_manager import VideoTaskManager, VideoTaskCreate, VideoTaskUpdate

def test_task_manager():
    """测试任务管理器"""
    print("=== 测试视频任务管理器 ===")

    db = get_session()
    try:
        mgr = VideoTaskManager()

        # 测试创建任务
        print("\n1. 创建任务...")
        task_create = VideoTaskCreate(
            task_id="test-task-001",
            session_id="test-session",
            product_name="高强度螺栓",
            theme="品质保证",
            duration=20,
            type="video"
        )
        task = mgr.create_task(db, task_create, total_parts=2)
        print(f"任务创建成功: {task.task_id}, 状态: {task.status}, 总段数: {task.total_parts}")

        # 测试更新进度
        print("\n2. 更新进度...")
        updated_task = mgr.update_progress(db, "test-task-001", 30, "正在生成第1段视频...")
        print(f"进度更新成功: 进度={updated_task.progress}, 步骤={updated_task.current_step}")

        # 测试增加完成段数
        print("\n3. 增加完成段数...")
        updated_task = mgr.increment_completed_parts(db, "test-task-001")
        print(f"完成段数: {updated_task.completed_parts}, 进度: {updated_task.progress}")

        # 测试更新任务为完成
        print("\n4. 标记为完成...")
        result = {
            "video_urls": ["http://example.com/video1.mp4", "http://example.com/video2.mp4"],
            "merged_video_url": "http://example.com/merged.mp4"
        }
        completed_task = mgr.mark_as_completed(db, "test-task-001", result)
        print(f"任务完成: 状态={completed_task.status}, 进度={completed_task.progress}")
        print(f"视频URLs: {completed_task.video_urls}")
        print(f"拼接URL: {completed_task.merged_video_url}")

        # 测试查询任务
        print("\n5. 查询任务...")
        found_task = mgr.get_task_by_id(db, "test-task-001")
        print(f"查询成功: {found_task.task_id}, 状态={found_task.status}")

        # 测试转换为响应模型
        print("\n6. 转换为响应模型...")
        response = mgr.to_response(found_task)
        print(f"响应模型: {response.model_dump_json(indent=2)}")

        print("\n=== 测试通过 ===")
        return True

    except Exception as e:
        print(f"\n测试失败: {e}")
        import traceback
        traceback.print_exc()
        return False
    finally:
        db.close()

if __name__ == "__main__":
    success = test_task_manager()
    sys.exit(0 if success else 1)
