import os
import time
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from sqlalchemy.exc import OperationalError
import logging
logger = logging.getLogger(__name__)

MAX_RETRY_TIME = 20  # 连接最大重试时间（秒）
# Load environment variables from .env if present
try:
    from dotenv import load_dotenv
    load_dotenv()
except Exception:
    pass

def get_db_url() -> str:
    """Build database URL from environment."""
    url = os.getenv("PGDATABASE_URL") or ""
    if url is not None and url != "":
        return url
    
    # 可选：尝试从 coze_workload_identity 获取（如果可用）
    try:
        from coze_workload_identity import Client
        client = Client()
        env_vars = client.get_project_env_vars()
        client.close()
        for env_var in env_vars:
            if env_var.key == "PGDATABASE_URL":
                url = env_var.value.replace("'", "'\\''")
                return url
    except ImportError:
        logger.debug("coze_workload_identity not available, using only environment variables")
    except Exception as e:
        logger.warning(f"Error loading PGDATABASE_URL from coze_workload_identity: {e}")
    
    if url is None or url == "":
        logger.warning("PGDATABASE_URL is not set")
    return url
_engine = None
_SessionLocal = None

def _create_engine_with_retry():
    url = get_db_url()
    if url is None or url == "":
        logger.error("PGDATABASE_URL is not set")
        raise ValueError("PGDATABASE_URL is not set")

    # 优化连接池配置，适配4GB内存服务器
    # 最大连接数 = pool_size + max_overflow = 20 + 30 = 50
    # 内存占用约 250MB（每个连接约5MB）
    size = 20           # 连接池大小
    overflow = 30      # 最大溢出连接数
    recycle = 3600     # 连接回收时间（1小时）
    timeout = 60       # 连接超时（60秒）

    engine = create_engine(
        url,
        pool_size=size,
        max_overflow=overflow,
        pool_pre_ping=True,
        pool_recycle=recycle,
        pool_timeout=timeout,
        connect_args={
            "connect_timeout": 10,  # 数据库连接超时（10秒）
            "options": "-c statement_timeout=60000"  # SQL执行超时（60秒）
        },
    )
    # 验证连接，带重试
    start_time = time.time()
    last_error = None
    while time.time() - start_time < MAX_RETRY_TIME:
        try:
            with engine.connect() as conn:
                conn.execute(text("SELECT 1"))
            return engine
        except OperationalError as e:
            last_error = e
            elapsed = time.time() - start_time
            logger.warning(f"Database connection failed, retrying... (elapsed: {elapsed:.1f}s)")
            time.sleep(min(1, MAX_RETRY_TIME - elapsed))
    logger.error(f"Database connection failed after {MAX_RETRY_TIME}s: {last_error}")
    raise last_error  # pyright: ignore [reportGeneralTypeIssues]

def get_engine():
    global _engine
    if _engine is None:
        _engine = _create_engine_with_retry()
    return _engine

def get_sessionmaker():
    global _SessionLocal
    if _SessionLocal is None:
        _SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=get_engine())
    return _SessionLocal

def get_session():
    return get_sessionmaker()()

__all__ = [
    "get_db_url",
    "get_engine",
    "get_sessionmaker",
    "get_session",
]
