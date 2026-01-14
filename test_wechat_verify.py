"""
极简版企业微信URL验证
只有核心逻辑，不超过30行代码
"""
import os
import hashlib
from fastapi import FastAPI, Query, Response
from dotenv import load_dotenv

load_dotenv()

app = FastAPI()
TOKEN = os.getenv("WECHAT_TOKEN", "")

@app.get("/callback")
def verify(signature: str, timestamp: str, nonce: str, echostr: str):
    # 1. 拼接参数（token + timestamp + nonce）
    arr = sorted([TOKEN, timestamp, nonce])
    s = ''.join(arr)

    # 2. 计算SHA1签名
    sha1 = hashlib.sha1(s.encode('utf-8')).hexdigest()

    # 3. 验证并返回
    if sha1 == signature:
        print(f"✅ 验证成功: echostr={echostr}")
        return Response(content=echostr, media_type="text/plain")
    else:
        print(f"❌ 验证失败")
        print(f"  期望: {sha1}")
        print(f"  收到: {signature}")
        return Response(content="failed", status_code=400)

if __name__ == "__main__":
    import uvicorn
    print("🚀 启动极简版企业微信验证服务...")
    print(f"🔑 Token: {TOKEN}")
    uvicorn.run(app, host="0.0.0.0", port=8080)
