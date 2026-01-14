"""
全局请求日志中间件
记录所有请求的详细信息
"""
import time
import logging
from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware

logger = logging.getLogger(__name__)

class RequestLoggingMiddleware(BaseHTTPMiddleware):
    """请求日志中间件"""

    async def dispatch(self, request: Request, call_next):
        # 记录请求开始
        start_time = time.time()

        # 记录请求信息
        client_host = request.client.host if request.client else "unknown"
        method = request.method
        url = str(request.url)
        user_agent = request.headers.get("user-agent", "unknown")

        # 打印所有请求
        logger.info("=" * 80)
        logger.info(f"收到请求")
        logger.info(f"  客户端 IP: {client_host}")
        logger.info(f"  方法: {method}")
        logger.info(f"  URL: {url}")
        logger.info(f"  User-Agent: {user_agent}")

        # 打印所有请求头（如果请求来自企业微信）
        if "wechat" in url.lower() or "qyapi" in user_agent.lower():
            logger.info(f"  可能是企业微信请求")
            logger.info(f"  所有请求头:")
            for name, value in request.headers.items():
                logger.info(f"    {name}: {value}")

            # 打印查询参数
            logger.info(f"  查询参数:")
            for key, value in request.query_params.items():
                logger.info(f"    {key}: {value}")

        # 调用下一个中间件或路由处理器
        try:
            response = await call_next(request)

            # 记录响应信息
            process_time = time.time() - start_time
            status_code = response.status_code

            logger.info(f"  响应状态码: {status_code}")
            logger.info(f"  处理时间: {process_time:.3f}秒")
            logger.info("=" * 80)

            return response
        except Exception as e:
            # 记录异常
            logger.error(f"  ❌ 处理请求时出错: {str(e)}")
            logger.error("=" * 80)
            raise
