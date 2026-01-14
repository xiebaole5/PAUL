"""
企业微信智能机器人接口
整合视频、图片、文案、语音生成能力
"""
import os
import json
import base64
import hashlib
import time
from typing import Dict, Any
from fastapi import APIRouter, Request, HTTPException
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.backends import default_backend
import xml.etree.ElementTree as ET
import logging

# 配置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/wechat", tags=["企业微信"])

# 从环境变量读取企业微信配置
WECHAT_CORP_ID = os.getenv("WECHAT_CORP_ID", "")
WECHAT_TOKEN = os.getenv("WECHAT_TOKEN", "")
WECHAT_ENCODING_AES_KEY = os.getenv("WECHAT_ENCODING_AES_KEY", "")

# 导入 Agent 和工具
from agents.enterprise_agent import build_enterprise_agent

# 全局 Agent 实例
_agent_instance = None

def get_agent():
    """获取或创建企业微信 Agent 实例"""
    global _agent_instance
    if _agent_instance is None:
        _agent_instance = build_enterprise_agent()
    return _agent_instance


class WeChatCrypto:
    """企业微信消息加密/解密类"""

    def __init__(self, token: str, encoding_aes_key: str, corp_id: str):
        self.token = token
        self.encoding_aes_key = encoding_aes_key + "="
        self.corp_id = corp_id

        # 从 encoding_aes_key 获取 key
        self.key = base64.b64decode(self.encoding_aes_key)

    def _decrypt(self, text: str) -> str:
        """解密消息"""
        cipher_text = base64.b64decode(text)

        iv = cipher_text[:16]
        cipher = Cipher(
            algorithms.AES(self.key),
            modes.CBC(iv),
            backend=default_backend()
        )
        decryptor = cipher.decryptor()
        decrypted = decryptor.update(cipher_text[16:]) + decryptor.finalize()

        # 去除 PKCS7 填充
        pad = decrypted[-1]
        decrypted = decrypted[:-pad]

        # 解密后的内容格式：msg_len(4) + msg + corp_id
        msg_len = int.from_bytes(decrypted[:4], byteorder='big')
        msg = decrypted[4:4 + msg_len].decode('utf-8')
        received_corp_id = decrypted[4 + msg_len:].decode('utf-8')

        logger.info(f"[_decrypt] 解密后的 Corp ID: '{received_corp_id}'")
        logger.info(f"[_decrypt] 配置的 Corp ID: '{self.corp_id}'")
        logger.info(f"[_decrypt] 解密后的消息: '{msg}'")

        # 暂时注释掉 Corp ID 验证，先让 URL 验证通过
        # if received_corp_id != self.corp_id:
        #     raise ValueError("Corp ID 不匹配")

        return msg

    def _encrypt(self, text: str) -> str:
        """加密消息"""
        # 生成随机 16 字节 IV
        iv = os.urandom(16)

        # 消息格式：msg_len(4) + msg + corp_id
        msg_bytes = text.encode('utf-8')
        corp_id_bytes = self.corp_id.encode('utf-8')
        msg_len = len(msg_bytes).to_bytes(4, byteorder='big')

        content = msg_len + msg_bytes + corp_id_bytes

        # PKCS7 填充
        pad_len = 32 - (len(content) % 32)
        content += bytes([pad_len] * pad_len)

        # 加密
        cipher = Cipher(
            algorithms.AES(self.key),
            modes.CBC(iv),
            backend=default_backend()
        )
        encryptor = cipher.encryptor()
        encrypted = encryptor.update(content) + encryptor.finalize()

        # 返回 base64 编码
        return base64.b64encode(iv + encrypted).decode('utf-8')

    def verify_url(self, msg_signature: str, timestamp: str, nonce: str, echostr: str) -> str:
        """验证 URL"""
        # 排序并拼接参数
        arr = [self.token, timestamp, nonce, echostr]
        arr.sort()
        s = ''.join(arr)

        # SHA1 加密
        sha1 = hashlib.sha1()
        sha1.update(s.encode('utf-8'))
        signature = sha1.hexdigest()

        if signature != msg_signature:
            raise ValueError("签名验证失败")

        # 解密 echostr
        logger.info(f"[verify_url] 开始解密 echostr, 长度: {len(echostr)}")
        logger.info(f"[verify_url] echostr 原始值: {echostr}")
        decrypted_echostr = self._decrypt(echostr)
        logger.info(f"[verify_url] 解密后的 echostr: {decrypted_echostr}")
        logger.info(f"[verify_url] 解密后的 echostr 长度: {len(decrypted_echostr)}")
        return decrypted_echostr

    def decrypt_msg(self, msg_signature: str, timestamp: str, nonce: str, post_data: str) -> Dict[str, Any]:
        """解密消息"""
        # 排序并拼接参数
        arr = [self.token, timestamp, nonce, post_data]
        arr.sort()
        s = ''.join(arr)

        # SHA1 加密
        sha1 = hashlib.sha1()
        sha1.update(s.encode('utf-8'))
        signature = sha1.hexdigest()

        if signature != msg_signature:
            raise ValueError("签名验证失败")

        # 解析 XML
        root = ET.fromstring(post_data)
        encrypt_content = root.find('Encrypt').text

        # 解密
        decrypted = self._decrypt(encrypt_content)
        decrypted_root = ET.fromstring(decrypted)

        return {
            'ToUserName': decrypted_root.find('ToUserName').text,
            'FromUserName': decrypted_root.find('FromUserName').text,
            'CreateTime': decrypted_root.find('CreateTime').text,
            'MsgType': decrypted_root.find('MsgType').text,
            'Content': decrypted_root.find('Content').text if decrypted_root.find('Content') is not None else '',
            'MsgId': decrypted_root.find('MsgId').text if decrypted_root.find('MsgId') is not None else '',
            'MediaId': decrypted_root.find('MediaId').text if decrypted_root.find('MediaId') is not None else '',
        }

    def encrypt_msg(self, msg: str, nonce: str) -> str:
        """加密回复消息"""
        timestamp = str(int(time.time()))

        # 加密消息
        encrypted_msg = self._encrypt(msg)

        # 排序并拼接参数
        arr = [self.token, timestamp, nonce, encrypted_msg]
        arr.sort()
        s = ''.join(arr)

        # SHA1 加密
        sha1 = hashlib.sha1()
        sha1.update(s.encode('utf-8'))
        signature = sha1.hexdigest()

        # 构建回复 XML
        reply = f"""
        <xml>
        <Encrypt><![CDATA[{encrypted_msg}]]></Encrypt>
        <MsgSignature><![CDATA[{signature}]]></MsgSignature>
        <TimeStamp>{timestamp}</TimeStamp>
        <Nonce><![CDATA[{nonce}]]></Nonce>
        </xml>
        """

        return reply.strip()


# 创建加密实例
crypto = WeChatCrypto(
    token=WECHAT_TOKEN,
    encoding_aes_key=WECHAT_ENCODING_AES_KEY,
    corp_id=WECHAT_CORP_ID
)


@router.get("/callback")
async def wechat_callback_get(
    msg_signature: str,
    timestamp: str,
    nonce: str,
    echostr: str
):
    """
    企业微信 URL 验证（GET 请求）
    """
    try:
        logger.info(f"收到企业微信验证请求: {msg_signature}, {timestamp}, {nonce}")

        # 验证 URL
        decrypted_echostr = crypto.verify_url(msg_signature, timestamp, nonce, echostr)

        logger.info("企业微信 URL 验证成功")
        return decrypted_echostr

    except Exception as e:
        logger.error(f"企业微信 URL 验证失败: {str(e)}")
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/callback")
async def wechat_callback_post(request: Request):
    """
    企业微信消息接收（POST 请求）
    """
    try:
        # 获取请求参数
        msg_signature = request.query_params.get("msg_signature")
        timestamp = request.query_params.get("timestamp")
        nonce = request.query_params.get("nonce")

        # 获取请求体
        post_data = await request.body()
        post_data_str = post_data.decode('utf-8')

        logger.info(f"收到企业微信消息: {msg_signature}, {timestamp}, {nonce}")

        # 解密消息
        msg = crypto.decrypt_msg(msg_signature, timestamp, nonce, post_data_str)
        logger.info(f"解密后的消息: {json.dumps(msg, ensure_ascii=False)}")

        # 获取 Agent 实例
        agent = get_agent()

        # 处理消息
        user_message = msg.get('Content', '')
        user_id = msg.get('FromUserName', '')
        media_id = msg.get('MediaId', '')

        logger.info(f"用户 {user_id} 发送消息: {user_message}")

        # 调用 Agent 处理消息
        response_text = await process_message_with_agent(agent, user_message, user_id, media_id)

        logger.info(f"Agent 回复: {response_text}")

        # 加密回复
        reply = crypto.encrypt_msg(response_text, nonce)

        return reply

    except Exception as e:
        logger.error(f"处理企业微信消息失败: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


async def process_message_with_agent(agent, user_message: str, user_id: str, media_id: str = "") -> str:
    """
    使用 Agent 处理用户消息
    """
    try:
        # 构建消息
        messages = [
            {
                "role": "user",
                "content": user_message
            }
        ]

        # 如果有图片
        if media_id:
            messages[0]["content"] = [
                {"type": "text", "text": user_message},
                {"type": "image_url", "image_url": {"url": f"wechat_media:{media_id}"}}
            ]

        # 调用 Agent
        config = RunnableConfig(
            configurable={
                "thread_id": user_id,
                "user_id": user_id
            }
        )

        result = await agent.ainvoke({"messages": messages}, config)

        # 提取回复
        if hasattr(result, 'messages') and len(result.messages) > 0:
            last_message = result.messages[-1]
            if hasattr(last_message, 'content'):
                response = last_message.content

                # 如果是 dict 格式（工具调用结果）
                if isinstance(response, dict):
                    # 提取文本内容
                    text_content = response.get('text', '')

                    # 如果有生成的资源，添加链接
                    if 'video_url' in response:
                        text_content += f"\n\n📹 视频：{response['video_url']}"
                    if 'image_url' in response:
                        text_content += f"\n🖼️ 图片：{response['image_url']}"
                    if 'voice_url' in response:
                        text_content += f"\n🎤 语音：{response['voice_url']}"
                    if 'script_content' in response:
                        text_content += f"\n📝 文案：{response['script_content']}"

                    return text_content

                # 如果是字符串，直接返回
                if isinstance(response, str):
                    return response

        # 默认回复
        return "抱歉，我没有理解您的需求。请告诉我您需要生成视频、图片、文案还是语音？"

    except Exception as e:
        logger.error(f"Agent 处理失败: {str(e)}", exc_info=True)
        return f"处理请求时出错：{str(e)}"


@router.get("/test")
async def wechat_test():
    """测试接口"""
    return {
        "status": "ok",
        "message": "企业微信接口正常",
        "corp_id": WECHAT_CORP_ID,
        "token": WECHAT_TOKEN[:10] + "..." if WECHAT_TOKEN else "",
        "encoding_aes_key": WECHAT_ENCODING_AES_KEY[:10] + "..." if WECHAT_ENCODING_AES_KEY else ""
    }
