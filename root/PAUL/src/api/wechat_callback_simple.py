"""
企业微信 URL 验证接口（简化版）
严格按照企业微信官方文档实现
"""
import os
import hashlib
from typing import Annotated
from fastapi import APIRouter, Query, HTTPException
import logging

# 配置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/wechat", tags=["企业微信"])

# 从环境变量读取企业微信配置
WECHAT_TOKEN = os.getenv("WECHAT_TOKEN", "")
WECHAT_CORP_ID = os.getenv("WECHAT_CORP_ID", "")

logger.info(f"企业微信接口 - Token: {WECHAT_TOKEN[:10] if WECHAT_TOKEN else 'None'}...")


@router.get("/callback")
async def wechat_url_verify(
    msg_signature: Annotated[str, Query(...)],
    timestamp: Annotated[str, Query(...)],
    nonce: Annotated[str, Query(...)],
    echostr: Annotated[str, Query(...)]
):
    """
    企业微信 URL 验证（GET 请求）

    根据企业微信官方文档：
    1. 企业微信发送参数：msg_signature, timestamp, nonce, echostr
    2. echostr 是明文随机字符串，不需要解密
    3. 验证签名后直接返回 echostr 即可

    返回：echostr 字符串（纯文本）
    """
    try:
        logger.info("=" * 60)
        logger.info("收到企业微信 URL 验证请求")
        logger.info(f"  msg_signature: {msg_signature}")
        logger.info(f"  timestamp: {timestamp}")
        logger.info(f"  nonce: {nonce}")
        logger.info(f"  echostr: {echostr}")
        logger.info("=" * 60)

        # 验证签名
        # 1. 将 token, timestamp, nonce, echostr 按字典序排序
        arr = [WECHAT_TOKEN, timestamp, nonce, echostr]
        arr.sort()
        s = ''.join(arr)

        # 2. SHA1 加密
        sha1 = hashlib.sha1()
        sha1.update(s.encode('utf-8'))
        signature = sha1.hexdigest()

        logger.info(f"计算的签名: {signature}")
        logger.info(f"接收的签名: {msg_signature}")

        # 3. 比对签名
        if signature != msg_signature:
            logger.error("❌ 签名验证失败！")
            raise HTTPException(status_code=400, detail="签名验证失败")

        logger.info("✅ 签名验证通过")
        logger.info(f"✅ 直接返回 echostr: {echostr}")
        logger.info("=" * 60)

        # 4. 直接返回 echostr（明文，不需要解密）
        return echostr

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"企业微信 URL 验证失败: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"验证失败: {str(e)}")


@router.post("/callback")
async def wechat_callback_post(request):
    """
    企业微信消息推送（POST 请求）
    这里才需要解密消息
    """
    logger.info("收到企业微信消息推送（POST）")
    # TODO: 实现消息解密和处理逻辑
    return {"status": "ok"}


@router.get("/test")
async def test():
    """测试接口"""
    return {
        "status": "ok",
        "message": "企业微信接口正常",
        "token_configured": bool(WECHAT_TOKEN),
        "corp_id_configured": bool(WECHAT_CORP_ID)
    }
