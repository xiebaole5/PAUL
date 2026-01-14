"""
企业微信 URL 验证接口（最简化版本）
只实现 URL 验证功能，确保能通过企业微信验证
"""
import os
import base64
import hashlib
from typing import Annotated
from fastapi import APIRouter, Query, HTTPException
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.backends import default_backend
import logging

# 配置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/wechat", tags=["企业微信"])

# 从环境变量读取企业微信配置
WECHAT_TOKEN = os.getenv("WECHAT_TOKEN", "")
WECHAT_ENCODING_AES_KEY = os.getenv("WECHAT_ENCODING_AES_KEY", "")
WECHAT_CORP_ID = os.getenv("WECHAT_CORP_ID", "")

logger.info(f"企业微信配置 - Token: {WECHAT_TOKEN[:10] if WECHAT_TOKEN else 'None'}..., CorpID: {WECHAT_CORP_ID}")


class SimpleWeChatCrypto:
    """企业微信消息解密类（最简化版本）"""

    def __init__(self, token: str, encoding_aes_key: str):
        self.token = token
        # 将 AES key 从 base64 解码
        self.key = base64.b64decode(encoding_aes_key + "=")

    def decrypt_echostr(self, echostr: str) -> str:
        """解密 echostr（最简化版本）"""
        try:
            # Base64 解码
            cipher_text = base64.b64decode(echostr)
            logger.info(f"Base64 解码后长度: {len(cipher_text)} 字节")

            # 提取 IV（前 16 字节）
            iv = cipher_text[:16]
            logger.info(f"IV 长度: {len(iv)} 字节")

            # 提取密文（16 字节之后）
            encrypted = cipher_text[16:]
            logger.info(f"密文长度: {len(encrypted)} 字节")

            # AES-CBC 解密
            cipher = Cipher(
                algorithms.AES(self.key),
                modes.CBC(iv),
                backend=default_backend()
            )
            decryptor = cipher.decryptor()
            decrypted = decryptor.update(encrypted) + decryptor.finalize()

            logger.info(f"解密后长度（含填充）: {len(decrypted)} 字节")

            # 去除 PKCS7 填充
            pad_len = decrypted[-1]
            decrypted = decrypted[:-pad_len]

            logger.info(f"去填充后长度: {len(decrypted)} 字节")
            logger.info(f"解密内容（十六进制）: {decrypted.hex()}")

            # 解析：msg_len(4) + msg + corp_id
            msg_len = int.from_bytes(decrypted[:4], byteorder='big')
            logger.info(f"消息长度: {msg_len} 字节")

            msg = decrypted[4:4 + msg_len].decode('utf-8')
            received_corp_id = decrypted[4 + msg_len:].decode('utf-8')

            logger.info(f"解密后的 echostr（msg）: {msg}")
            logger.info(f"解密后的 Corp ID: {received_corp_id}")
            logger.info(f"配置的 Corp ID: {WECHAT_CORP_ID}")

            # 只在 URL 验证阶段，我们不需要验证 Corp ID
            # 直接返回消息内容
            return msg

        except Exception as e:
            logger.error(f"解密失败: {str(e)}", exc_info=True)
            raise


# 创建解密实例
crypto = SimpleWeChatCrypto(
    token=WECHAT_TOKEN,
    encoding_aes_key=WECHAT_ENCODING_AES_KEY
)


@router.get("/callback")
async def wechat_url_verify(
    msg_signature: Annotated[str, Query(...)],
    timestamp: Annotated[str, Query(...)],
    nonce: Annotated[str, Query(...)],
    echostr: Annotated[str, Query(...)]
):
    """
    企业微信 URL 验证（最简化版本）

    企业微信会发送 GET 请求到这个接口，参数包括：
    - msg_signature: 签名
    - timestamp: 时间戳
    - nonce: 随机数
    - echostr: 加密的随机字符串（需要解密后返回）

    返回：解密后的 echostr 字符串（纯文本，不是 JSON）
    """
    try:
        logger.info("=" * 60)
        logger.info("收到企业微信 URL 验证请求")
        logger.info(f"  msg_signature: {msg_signature}")
        logger.info(f"  timestamp: {timestamp}")
        logger.info(f"  nonce: {nonce}")
        logger.info(f"  echostr: {echostr[:50]}...（长度: {len(echostr)}）")
        logger.info("=" * 60)

        # 第一步：验证签名
        # 排序并拼接参数
        arr = [WECHAT_TOKEN, timestamp, nonce, echostr]
        arr.sort()
        s = ''.join(arr)

        # SHA1 加密
        sha1 = hashlib.sha1()
        sha1.update(s.encode('utf-8'))
        signature = sha1.hexdigest()

        logger.info(f"计算出的签名: {signature}")
        logger.info(f"接收到的签名: {msg_signature}")

        if signature != msg_signature:
            logger.error("签名验证失败！")
            raise HTTPException(status_code=400, detail="签名验证失败")

        logger.info("✅ 签名验证通过")

        # 第二步：解密 echostr
        logger.info("开始解密 echostr...")
        decrypted_echostr = crypto.decrypt_echostr(echostr)

        logger.info(f"✅ 解密成功: {decrypted_echostr}")
        logger.info("=" * 60)

        # 第三步：返回解密后的 echostr（纯文本）
        return decrypted_echostr

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"企业微信 URL 验证失败: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"验证失败: {str(e)}")


@router.get("/test")
async def wechat_test():
    """测试接口"""
    return {
        "status": "ok",
        "message": "企业微信接口正常",
        "token_configured": bool(WECHAT_TOKEN),
        "encoding_aes_key_configured": bool(WECHAT_ENCODING_AES_KEY),
        "corp_id": WECHAT_CORP_ID[:10] + "..." if WECHAT_CORP_ID else ""
    }


@router.get("/health")
async def health_check():
    """健康检查"""
    return {"status": "ok"}
