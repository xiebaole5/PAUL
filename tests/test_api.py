"""
测试后端 API 服务
"""
import sys
import os

# 添加项目根目录到 Python 路径
workspace_path = os.getenv("COZE_WORKSPACE_PATH", "/workspace/projects")
if workspace_path not in sys.path:
    sys.path.insert(0, workspace_path)

# 设置必要的环境变量
os.environ["COZE_WORKSPACE_PATH"] = workspace_path
os.environ["COZE_WORKLOAD_IDENTITY_API_KEY"] = os.getenv("COZE_WORKLOAD_IDENTITY_API_KEY", "e1533511-efae-4131-aea9-b573a1be4ecf")
os.environ["COZE_INTEGRATION_MODEL_BASE_URL"] = os.getenv("COZE_INTEGRATION_MODEL_BASE_URL", "")

print("=" * 60)
print("测试 FastAPI 服务启动")
print("=" * 60)

try:
    # 导入 API 模块
    from src.api.app import app, get_agent
    print("✓ API 模块导入成功")

    # 初始化 Agent
    print("\n正在初始化 Agent...")
    agent = get_agent()
    print("✓ Agent 初始化成功")

    print("\n" + "=" * 60)
    print("API 服务测试通过")
    print("=" * 60)
    print("\n提示：可以使用以下命令启动服务：")
    print("  uvicorn src.api.app:app --host 0.0.0.0 --port 8000 --reload")
    print("\nAPI 文档地址：")
    print("  http://localhost:8000/docs")

except Exception as e:
    print(f"\n✗ 测试失败: {str(e)}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
