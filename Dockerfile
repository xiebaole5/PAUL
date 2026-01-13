FROM python:3.10-slim

# 设置工作目录
WORKDIR /app

# 设置环境变量
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    COZE_WORKSPACE_PATH=/app \
    PYTHONPATH=/app:/app/src

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# 复制依赖文件
COPY requirements.txt .

# 安装 Python 依赖
RUN pip install --no-cache-dir -r requirements.txt

# 复制项目文件
COPY src/ /app/src/
COPY config/ /app/config/
COPY scripts/ /app/scripts/

# 创建必要的目录
RUN mkdir -p /app/assets/uploads \
    /app/logs

# 暴露端口
EXPOSE 8000

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# 从 /app/src 目录启动，确保模块导入路径正确
WORKDIR /app/src
CMD ["uvicorn", "api.app:app", "--host", "0.0.0.0", "--port", "8000"]
