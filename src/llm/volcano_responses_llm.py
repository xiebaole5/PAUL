"""
火山方舟 Responses 接口自定义 LLM
支持 doubao-seed-1-8-251228 等新模型
"""
from typing import Any, Dict, List, Optional, Sequence, TypeVar, Union
from langchain_core.language_models.chat_models import BaseChatModel
from langchain_core.messages import BaseMessage, HumanMessage, SystemMessage, AIMessage, ChatMessage
from langchain_core.outputs import ChatGeneration, ChatResult
from langchain_core.callbacks.manager import CallbackManagerForLLMRun
from pydantic import Field, SecretStr
import requests
import os
import json

# 定义输出类型
OutputType = ChatResult


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
        api_key_str = self.api_key

        headers = {
            "Authorization": f"Bearer {api_key_str}",
            "Content-Type": "application/json"
        }

        # 转换消息格式
        input_data = self._convert_messages_to_input(messages)

        request = {
            "model": self.model,
            "input": input_data
        }

        # 添加可选参数（注意：responses 接口可能不支持 max_tokens）
        if self.temperature is not None:
            request["temperature"] = self.temperature
        # max_tokens 可能不支持，暂时注释掉
        # if self.max_tokens is not None:
        #     request["max_tokens"] = self.max_tokens

        try:
            # 打印请求内容用于调试
            if os.getenv('DEBUG_LLM'):
                print(f"Request URL: {self.base_url}/responses")
                print(f"Request: {json.dumps(request, indent=2, ensure_ascii=False)}")

            response = requests.post(
                f"{self.base_url}/responses",
                json=request,
                headers=headers,
                timeout=self.timeout
            )

            if os.getenv('DEBUG_LLM'):
                print(f"Response status: {response.status_code}")
                print(f"Response text: {response.text[:500]}")

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


from typing import Callable


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
