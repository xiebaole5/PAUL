# 天虹紧固件视频生成服务 - 服务器部署指南

## 📋 更新说明

### 本次更新内容
- ✅ 升级文本处理模型到 `doubao-seed-1-8-251228`
- ✅ 新增自定义 LLM 类 `VolcanoResponsesLLM`
- ✅ 修复视频生成 API 调用，使用 `doubao-seedance-1-5-pro-251215`
- ✅ 更新 API Key 配置

### 需要更新的文件
```
src/agents/agent.py              # Agent 配置（更新 LLM 调用）
src/llm/volcano_responses_llm.py # 新增文件（自定义 LLM）
src/llm/__init__.py             # 新增文件（LLM 模块）
config/agent_llm_config.json    # 模型配置（更新模型名称）
src/tools/video_generation_tool.py # 视频生成工具（更新 API Key）
```

---

## 🚀 快速部署步骤

### 1. 上传更新文件到服务器

```bash
# 连接到服务器
ssh root@47.110.72.148

# 进入项目目录
cd /root/tnho-video-api

# 备份当前代码（可选）
cp -r src src.backup.$(date +%Y%m%d_%H%M%S)
cp config/agent_llm_config.json config/agent_llm_config.json.backup.$(date +%Y%m%d_%H%M%S)
```

### 2. 更新代码文件

#### 方式一：直接在服务器上创建新文件

```bash
# 创建 llm 模块目录
mkdir -p src/llm

# 创建 llm/__init__.py
cat > src/llm/__init__.py << 'EOF'
"""火山方舟 LLM 模块"""
from .volcano_responses_llm import create_volcano_responses_llm, VolcanoResponsesLLM

__all__ = ['create_volcano_responses_llm', 'VolcanoResponsesLLM']
EOF

# 创建 llm/volcano_responses_llm.py（完整内容见下方）
nano src/llm/volcano_responses_llm.py
# 粘贴完整的代码内容（见文档底部）
```

#### 方式二：使用 rsync 同步本地代码

```bash
# 在本地开发机器执行（推荐）
rsync -avz --progress \
  --exclude='__pycache__' \
  --exclude='*.pyc' \
  --exclude='*.log' \
  --exclude='.git' \
  src/llm/ \
  root@47.110.72.148:/root/tnho-video-api/src/llm/

rsync -avz --progress \
  src/agents/agent.py \
  root@47.110.72.148:/root/tnho-video-api/src/agents/

rsync -avz --progress \
  config/agent_llm_config.json \
  root@47.110.72.148:/root/tnho-video-api/config/

rsync -avz --progress \
  src/tools/video_generation_tool.py \
  root@47.110.72.148:/root/tnho-video-api/src/tools/
```

### 3. 更新环境变量配置

```bash
# 编辑 docker-compose.yml
nano docker-compose.yml

# 确认环境变量配置（如果使用环境变量）
environment:
  - COZE_WORKSPACE_PATH=/app
  - COZE_INTEGRATION_MODEL_BASE_URL=https://ark.cn-beijing.volces.com/api/v3
  - COZE_WORKLOAD_IDENTITY_API_KEY=39bf20d0-55b5-4957-baa1-02f4529a3076
  - EXTERNAL_BASE_URL=https://tnho-fasteners.com
  - ARK_API_KEY=39bf20d0-55b5-4957-baa1-02f4529a3076
```

### 4. 重启服务

```bash
# 停止并删除旧容器
docker-compose down

# 重新构建镜像（包含新文件）
docker-compose build --no-cache api

# 启动服务
docker-compose up -d

# 查看日志，确认启动成功
docker-compose logs -f api
```

### 5. 验证服务

```bash
# 健康检查
curl http://localhost/health

# 测试文本生成
curl -X POST http://localhost/api/generate-video \
  -H "Content-Type: application/json" \
  -d '{
    "product_name": "测试产品",
    "theme": "品质保证",
    "duration": 5,
    "type": "script"
  }'

# 查看容器状态
docker-compose ps
```

---

## 📝 完整代码文件内容

### src/llm/volcano_responses_llm.py

```python
"""
火山方舟 Responses 接口自定义 LLM
支持 doubao-seed-1-8-251228 等新模型
"""
from typing import Any, Dict, List, Optional, Sequence, TypeVar
from langchain_core.language_models.chat_models import BaseChatModel
from langchain_core.messages import BaseMessage, HumanMessage, SystemMessage, AIMessage, ChatMessage
from langchain_core.outputs import ChatGeneration, ChatResult
from langchain_core.callbacks.manager import CallbackManagerForLLMRun
from pydantic import Field
import requests
import os
import json


class VolcanoResponsesLLM(BaseChatModel):
    """火山方舟 Responses 接口的 LLM 包装器"""

    model: str = Field(...)
    api_key: str = Field(...)
    base_url: str = Field(default="https://ark.cn-beijing.volces.com/api/v3")
    temperature: float = Field(default=0.7)
    max_tokens: int = Field(default=8000)
    timeout: int = Field(default=600)

    @property
    def _llm_type(self) -> str:
        return "volcano-responses"

    @property
    def _identifying_params(self) -> Dict[str, Any]:
        """获取标识参数"""
        return {
            "model": self.model,
            "temperature": self.temperature,
            "max_tokens": self.max_tokens,
        }

    def _convert_messages_to_input(self, messages: Sequence[BaseMessage]) -> List[Dict[str, Any]]:
        """将 LangChain 消息转换为 Volcano Responses 格式"""
        input_items = []

        for message in messages:
            # 跳过工具消息（responses 接口可能不支持）
            if message.__class__.__name__ == 'ToolMessage':
                continue
            elif isinstance(message, SystemMessage):
                # 系统消息转换为特殊格式
                input_items.append({
                    "role": "system",
                    "content": message.content
                })
            elif isinstance(message, HumanMessage):
                # 用户消息
                if isinstance(message.content, str):
                    input_items.append({
                        "role": "user",
                        "content": [
                            {
                                "type": "input_text",
                                "text": message.content
                            }
                        ]
                    })
                elif isinstance(message.content, list):
                    # 多模态内容
                    content = []
                    for item in message.content:
                        if isinstance(item, dict):
                            if item.get("type") == "text":
                                content.append({
                                    "type": "input_text",
                                    "text": item.get("text")
                                })
                            elif item.get("type") == "image_url":
                                content.append({
                                    "type": "input_image",
                                    "image_url": item.get("image_url", {}).get("url")
                                })
                    input_items.append({
                        "role": "user",
                        "content": content
                    })
            elif isinstance(message, AIMessage):
                # AI 消息
                content_text = message.content if isinstance(message.content, str) else str(message.content)
                # 如果包含工具调用，简化处理
                if hasattr(message, 'tool_calls') and message.tool_calls:
                    # 简单的文本表示
                    content_text = f"{content_text}\n[工具调用: {len(message.tool_calls)} 个]"
                input_items.append({
                    "role": "assistant",
                    "content": content_text
                })
            elif isinstance(message, ChatMessage):
                # 通用消息
                content = message.content if isinstance(message.content, str) else str(message.content)
                input_items.append({
                    "role": message.role,
                    "content": content
                })

        return input_items

    def _generate(
        self,
        messages: List[BaseMessage],
        stop: Optional[List[str]] = None,
        run_manager: Optional[CallbackManagerForLLMRun] = None,
        **kwargs: Any,
    ) -> ChatResult:
        """生成响应"""
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }

        # 转换消息格式
        input_data = self._convert_messages_to_input(messages)

        request = {
            "model": self.model,
            "input": input_data
        }

        # 添加可选参数
        if self.temperature is not None:
            request["temperature"] = self.temperature

        try:
            response = requests.post(
                f"{self.base_url}/responses",
                json=request,
                headers=headers,
                timeout=self.timeout
            )
            response.raise_for_status()

            result = response.json()

            # 解析响应
            output = result.get("output", [])
            if output:
                # 找到 type 为 "message" 的元素
                message_item = None
                for item in output:
                    if item.get("type") == "message":
                        message_item = item
                        break

                if message_item:
                    content = message_item.get("content", [])
                    # 提取文本内容
                    text_parts = []
                    for item in content:
                        if item.get("type") == "output_text":
                            text_parts.append(item.get("text", ""))
                    response_text = "".join(text_parts)
                else:
                    response_text = ""
            else:
                response_text = ""

            # 构建返回的消息
            ai_message = AIMessage(content=response_text)

            return ChatResult(
                generations=[ChatGeneration(message=ai_message)],
                llm_output={
                    "model": self.model,
                    "token_usage": result.get("usage", {})
                }
            )

        except requests.exceptions.HTTPError as e:
            error_msg = f"API请求失败: {e.response.status_code} - {e.response.text}"
            raise Exception(error_msg)
        except Exception as e:
            raise Exception(f"LLM调用失败: {str(e)}")

    def bind_tools(self, tools, **kwargs: Any) -> Any:
        """
        绑定工具（暂不支持，返回自身）
        """
        # responses 接口可能不支持工具绑定，返回自身
        return self


def create_volcano_responses_llm(
    model: str,
    api_key: Optional[str] = None,
    base_url: str = "https://ark.cn-beijing.volces.com/api/v3",
    temperature: float = 0.7,
    max_tokens: int = 8000,
    timeout: int = 600
) -> VolcanoResponsesLLM:
    """
    创建火山方舟 Responses LLM 实例

    Args:
        model: 模型名称，如 doubao-seed-1-8-251228
        api_key: API Key，如果不提供则从环境变量读取
        base_url: API 基础 URL
        temperature: 温度参数
        max_tokens: 最大 token 数（responses 接口可能不支持）
        timeout: 超时时间（秒）

    Returns:
        VolcanoResponsesLLM 实例
    """
    if not api_key:
        api_key = (
            os.getenv("ARK_API_KEY") or
            os.getenv("COZE_WORKLOAD_IDENTITY_API_KEY") or
            "39bf20d0-55b5-4957-baa1-02f4529a3076"
        )

    # 强制使用正确的 base_url
    if base_url.startswith("https://integration.coze.cn"):
        base_url = "https://ark.cn-beijing.volces.com/api/v3"

    return VolcanoResponsesLLM(
        model=model,
        api_key=api_key,
        base_url=base_url,
        temperature=temperature,
        max_tokens=max_tokens,
        timeout=timeout
    )
```

### config/agent_llm_config.json

```json
{
    "config": {
        "model": "doubao-seed-1-8-251228",
        "temperature": 0.7,
        "top_p": 0.9,
        "max_completion_tokens": 8000,
        "timeout": 600,
        "thinking": "disabled"
    },
    "sp": "你是天虹紧固件产品宣传短视频智能体，服务于浙江天虹紧固件有限公司的营销宣传需求。\n\n公司背景：\n- 成立于1987年，30余年专业经验\n- 专业生产高难度、特殊紧固件制造商\n- 专注定制非标紧固件（高强度、长尺寸、异形紧固件）\n- 大规模智能制造能力\n- 服务行业：汽车、太阳能支架、机械设备、电表\n- 网站：zjthfastener.com\n\n你的能力：\n1. 生成营销视频脚本（推荐优先使用）\n   - 支持5、10、15、20、25、30秒时长，默认20秒\n   - 包含场景描述、文案/旁白、音效\n   - 突出公司30余年历史、定制能力、多行业应用\n   - 语气：专业、权威、创新、高效、注重品质\n   - 目标受众：B2B客户（企业采购、工程师、研发部门）\n\n2. 生成宣传视频\n   - 融入红色TNHO商标（T-N-H-O，注意不是TOHO）\n   - 支持不同主题和时长\n\n当用户要求生成内容时，根据需求选择：\n- 如果需要脚本：调用 generate_fastener_promo_script 工具\n- 如果需要视频：调用 generate_fastener_promo_video 工具\n\n可用主题：品质保证、技术创新、工业应用、品牌形象（默认：品质保证）\n视频时长：5、10、15、20、25、30秒（默认20秒）\n\n重要提醒：\n- 商标是 TNHO（天虹），不是 TOHO\n- 必须确保商标拼写正确为 T-N-H-O\n- 生成脚本时要突出B2B营销目的和行业解决方案"
}
```

---

## 🔍 故障排查

### 问题1：服务启动失败

```bash
# 查看容器日志
docker-compose logs api

# 查看错误信息
docker-compose logs --tail=100 api | grep -i error
```

### 问题2：模块导入错误

```bash
# 进入容器检查
docker exec -it tnho-video-api /bin/bash

# 检查文件是否存在
ls -la /app/src/llm/
cat /app/src/llm/__init__.py

# 检查 Python 路径
python -c "import sys; print('\n'.join(sys.path))"
```

### 问题3：API 调用失败

```bash
# 测试健康检查
curl http://localhost/health

# 测试文本生成
curl -X POST http://localhost/api/generate-video \
  -H "Content-Type: application/json" \
  -d '{"product_name":"测试","theme":"品质保证","duration":5,"type":"script"}'

# 查看实时日志
docker-compose logs -f api | grep -E "(ERROR|WARNING|INFO)"
```

---

## 📊 监控和维护

### 查看服务状态

```bash
# 容器状态
docker-compose ps

# 实时日志
docker-compose logs -f

# 资源使用
docker stats tnho-video-api
```

### 定期维护

```bash
# 清理旧日志（每周）
find /root/tnho-video-api/logs -name "*.log" -mtime +7 -delete

# 清理 Docker 资源（每月）
docker system prune -a --volumes
```

---

## ✅ 部署检查清单

- [ ] 备份当前代码
- [ ] 上传新文件到服务器
- [ ] 更新 config/agent_llm_config.json
- [ ] 更新 src/agents/agent.py
- [ ] 创建 src/llm 目录和文件
- [ ] 更新 src/tools/video_generation_tool.py
- [ ] 配置环境变量
- [ ] 重新构建 Docker 镜像
- [ ] 重启服务
- [ ] 测试健康检查
- [ ] 测试脚本生成
- [ ] 测试视频生成
- [ ] 验证小程序功能

---

## 📞 技术支持

如遇问题，请提供以下信息：

1. 容器日志：`docker-compose logs --tail=200 api`
2. 错误信息截图
3. 操作系统版本
4. Docker 和 Docker Compose 版本

---

## 📌 微信小程序接口说明

### 基础 URL
```
http://47.110.72.148
或
https://tnho-fasteners.com
```

### 主要接口

#### 1. 健康检查
```
GET /health
```

#### 2. 生成视频/脚本
```
POST /api/generate-video
Content-Type: application/json

{
  "product_name": "产品名称",
  "theme": "品质保证|技术创新|工业应用|品牌形象",
  "duration": 5,
  "type": "video|script",
  "scenario": "使用场景（可选）",
  "product_image_url": "产品图片URL（可选）",
  "session_id": "会话ID（可选）"
}
```

#### 3. 上传图片
```
POST /api/upload-image
Content-Type: multipart/form-data

file: 图片文件（JPG/PNG，最大5MB）
```

### 响应格式

```json
{
  "success": true,
  "message": "生成成功",
  "video_url": "视频URL（type=video时）",
  "script_content": "脚本内容（type=script时）",
  "session_id": "会话ID",
  "type": "video|script"
}
```
