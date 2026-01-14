"""
数据库会话上下文管理器
确保数据库会话正确关闭，避免连接泄漏
"""
from contextlib import contextmanager
from typing import Generator

from storage.database.db import get_session


@contextmanager
def get_db_session() -> Generator:
    """
    数据库会话上下文管理器
    
    使用方式:
        with get_db_session() as db:
            db.execute("SELECT * FROM table")
        # 会话自动关闭
    """
    session = get_session()
    try:
        yield session
    finally:
        session.close()


__all__ = ["get_db_session"]
