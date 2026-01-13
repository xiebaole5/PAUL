# TNHO 视频生成服务 - 应用入口
# 从 src/api 导入 FastAPI 应用
import os
import sys

# 添加 src 目录到 Python 路径
current_dir = os.path.dirname(os.path.abspath(__file__))
src_path = os.path.join(current_dir, "src")

if src_path not in sys.path:
    sys.path.insert(0, src_path)

# 导入 FastAPI 应用
from api.app import app

# 导出 app，便于 uvicorn 启动
__all__ = ["app"]

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app:app", host="0.0.0.0", port=8000, reload=False)
