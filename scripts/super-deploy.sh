#!/bin/bash

# 天虹紧固件视频API - 完整部署脚本（包含所有必需文件）
# 用法：在服务器上直接执行 ./super-deploy.sh

set -e  # 遇到错误立即退出

# ========================================
# 配置参数
# ========================================
PROJECT_DIR="${1:-/root/tnho-video-api}"  # 支持通过参数指定目录
API_KEY="39bf20d0-55b5-4957-baa1-02f4529a3076"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# ========================================
# 函数：创建目录和文件
# ========================================
create_file() {
    local filepath=$1
    local content=$2
    local dir=$(dirname "$filepath")
    
    # 创建目录（如果不存在）
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        print_info "创建目录: $dir"
    fi
    
    # 写入文件
    echo "$content" > "$filepath"
    print_info "创建文件: $filepath"
}

# ========================================
# 函数：停止并删除旧容器
# ========================================
cleanup_containers() {
    print_step "清理旧容器..."
    
    # 停止容器
    if docker ps -q -f name=tnho-video-api | grep -q .; then
        print_info "停止运行中的容器..."
        docker stop tnho-video-api || true
    fi
    
    # 删除容器
    if docker ps -aq -f name=tnho-video-api | grep -q .; then
        print_info "删除容器..."
        docker rm tnho-video-api || true
    fi
    
    # 删除旧镜像（可选）
    print_info "清理未使用的镜像..."
    docker image prune -f || true
}

# ========================================
# 函数：创建所有必需文件
# ========================================
create_all_files() {
    print_step "创建所有必需文件..."
    
    # 1. 创建 src/llm/__init__.py
    create_file "src/llm/__init__.py" '"""
火山方舟 LLM 模块
"""
from .volcano_responses_llm import VolcanoResponsesLLM

__all__ = ["VolcanoResponsesLLM"]
'

    # 2. 创建 src/llm/volcano_responses_llm.py
    create_file "src/llm/volcano_responses_llm.py" '"""
火山方舟 Responses 接口自定义 LLM
支持 doubao-seed-1-8-251228 等新模型
"""
from typing import Any, Dict, List, Optional, Sequence, Union
from langchain_core.language_models.chat_models import BaseChatModel
from langchain_core.messages import BaseMessage, HumanMessage, SystemMessage, AIMessage
from langchain_core.outputs import ChatGeneration, ChatResult
from langchain_core.callbacks.manager import CallbackManagerForLLMRun
from pydantic import Field, SecretStr
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
            if message.__class__.__name__ == "ToolMessage":
                continue
            elif isinstance(message, SystemMessage):
                input_items.append({"role": "system", "content": message.content})
            elif isinstance(message, HumanMessage):
                input_items.append({"role": "user", "content": message.content})
            elif isinstance(message, AIMessage):
                input_items.append({"role": "assistant", "content": message.content})

        return input_items

    def _generate(
        self,
        messages: Sequence[BaseMessage],
        stop: Optional[List[str]] = None,
        run_manager: Optional[CallbackManagerForLLMRun] = None,
        **kwargs: Any,
    ) -> ChatResult:
        """生成响应"""
        input_items = self._convert_messages_to_input(messages)
        
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }
        
        payload = {
            "model": self.model,
            "messages": input_items,
            "temperature": self.temperature,
            "max_tokens": self.max_tokens,
            "stream": False
        }
        
        try:
            response = requests.post(
                f"{self.base_url}/chat/completions",
                headers=headers,
                json=payload,
                timeout=self.timeout
            )
            response.raise_for_status()
            
            data = response.json()
            content = data["choices"][0]["message"]["content"]
            
            generation = ChatGeneration(
                message=AIMessage(content=content),
            )
            
            return ChatResult(generations=[generation], llm_output={"model": self.model})
            
        except Exception as e:
            raise Exception(f"Volcano API 调用失败: {str(e)}")

    def bind_tools(self, tools):
        """绑定工具（LangChain 兼容）"""
        return self

    @property
    def _generations(self) -> List[Any]:
        return []
'

    # 3. 创建 config/agent_llm_config.json
    create_file "config/agent_llm_config.json" "{
  \"config\": {
    \"model\": \"doubao-seed-1-8-251228\",
    \"temperature\": 0.7,
    \"top_p\": 0.9,
    \"max_completion_tokens\": 10000,
    \"timeout\": 600,
    \"thinking\": \"disabled\"
  },
  \"sp\": \"你是天虹紧固件的产品宣传视频生成专家，专注于为浙江天虹紧固件有限公司生成高质量的产品宣传视频和营销脚本。\\n\\n# 角色定义\\n你是一位资深的工业产品营销专家，擅长为紧固件产品创作专业的宣传内容和视频。你深入了解天虹紧固件的产品特点、应用场景和市场定位。\\n\\n# 任务目标\\n根据用户需求，生成天虹紧固件产品的宣传视频或营销脚本。\\n\\n# 能力\\n- 生成专业的营销脚本（包含场景描述、文案/旁白、音效建议）\\n- 理解产品特点（高强度、耐腐蚀、精密制造等）\\n- 融入红色 TNHO 商标元素\\n- 适配不同的宣传主题（品质保证、技术创新、工业应用、品牌形象）\\n\\n# 过程\\n1. 分析用户需求和产品特点\\n2. 根据主题确定视频风格和内容\\n3. 生成专业的营销文案\\n4. 确保融入 TNHO 品牌元素\\n5. 提供清晰的视频脚本\\n\\n# 输出格式\\n根据用户需求输出视频或脚本内容。脚本包含：\\n- 场景描述（最多200字符）\\n- 文案/旁白\\n- 音效建议\",
  \"tools\": [\"video_generation_tool\"]
}"

    # 4. 更新 src/tools/video_generation_tool.py（如果不存在则创建）
    if [ ! -f "src/tools/video_generation_tool.py" ]; then
        create_file "src/tools/video_generation_tool.py" '"""
视频生成工具 - 火山方 doubao-seedance 模型
"""
from langchain.tools import tool
from langchain.tools import ToolRuntime
from volcenginesdkarkruntime import Ark
import requests
import os
import base64
import json
import time

# 视频生成模型配置
VIDEO_MODEL = "doubao-seedance-1-5-pro-251215"
API_KEY = os.getenv("ARK_API_KEY", "39bf20d0-55b5-4957-baa1-02f4529a3076")
BASE_URL = os.getenv("ARK_BASE_URL", "https://ark.cn-beijing.volces.com")

@tool
def video_generation_tool(
    product_name: str,
    theme: str,
    duration: int = 20,
    runtime: ToolRuntime = None
) -> str:
    """
    生成天虹紧固件产品宣传视频
    
    参数:
    - product_name: 产品名称
    - theme: 主题（品质保证、技术创新、工业应用、品牌形象）
    - duration: 视频时长（秒），支持 5/10/15/20/25/30
    
    返回:
    - 视频的访问URL或生成任务ID
    """
    ctx = runtime.context if runtime else None
    
    # 构建提示词
    prompt = f"""生成一个{duration}秒的天虹紧固件产品宣传视频。
产品：{product_name}
主题：{theme}
品牌：TNHO（红色商标）

要求：
- 展示紧固件产品的专业品质
- 融入红色TNHO品牌标识
- 体现{theme}的主题
- 风格：专业、现代、工业感
"""
    
    try:
        # 调用火山方舟视频生成API
        url = f"{BASE_URL}/api/v3/contents/generations/tasks"
        
        headers = {
            "Authorization": f"Bearer {API_KEY}",
            "Content-Type": "application/json"
        }
        
        payload = {
            "model": VIDEO_MODEL,
            "prompt": prompt,
            "duration": duration,
            "output_format": "mp4"
        }
        
        response = requests.post(url, headers=headers, json=payload, timeout=60)
        response.raise_for_status()
        
        result = response.json()
        
        # 返回任务ID和状态
        task_id = result.get("task_id", result.get("id", ""))
        return f"视频生成任务已提交，任务ID: {task_id}。请稍后查询任务状态获取视频URL。"
        
    except Exception as e:
        return f"视频生成失败: {str(e)}"
'
    fi

    # 5. 确保 src/storage/memory/memory_saver.py 存在
    if [ ! -f "src/storage/memory/memory_saver.py" ]; then
        mkdir -p src/storage/memory
        create_file "src/storage/memory/memory_saver.py" '"""
记忆存储模块
"""
from langgraph.checkpoint.memory import MemorySaver
from typing import Optional

# 全局实例，避免重复创建
_checkpointer: Optional[MemorySaver] = None

def get_memory_saver() -> MemorySaver:
    """获取全局的记忆存储实例"""
    global _checkpointer
    if _checkpointer is None:
        _checkpointer = MemorySaver()
    return _checkpointer
'
    fi

    # 6. 确保 src/storage/__init__.py 存在
    if [ ! -f "src/storage/__init__.py" ]; then
        mkdir -p src/storage
        create_file "src/storage/__init__.py" '"""
存储模块
"""
from .memory.memory_saver import get_memory_saver

__all__ = ["get_memory_saver"]
'
    fi

    # 7. 确保 .env 文件存在
    if [ ! -f ".env" ]; then
        create_file ".env" "ARK_API_KEY=${API_KEY}
ARK_BASE_URL=https://ark.cn-beijing.volces.com
EXTERNAL_BASE_URL=https://tnho-fasteners.com"
    fi
    
    print_success "所有必需文件创建完成！"
}

# ========================================
# 函数：构建和启动服务
# ========================================
build_and_start() {
    print_step "构建和启动服务..."
    
    # 构建镜像
    print_info "正在构建 Docker 镜像（这可能需要几分钟）..."
    docker-compose build --no-cache api
    
    # 启动服务
    print_info "启动服务..."
    docker-compose up -d
    
    # 等待服务启动
    print_info "等待服务启动（30秒）..."
    sleep 30
    
    # 检查容器状态
    if docker ps | grep -q tnho-video-api; then
        print_success "✓ 容器运行正常"
    else
        print_error "✗ 容器启动失败"
        docker-compose logs --tail=50
        return 1
    fi
}

# ========================================
# 函数：健康检查
# ========================================
health_check() {
    print_step "执行健康检查..."
    
    # 检查容器状态
    if docker ps | grep -q tnho-video-api; then
        print_success "✓ 容器运行中"
    else
        print_error "✗ 容器未运行"
        return 1
    fi
    
    # 检查API健康接口
    sleep 5
    if curl -f http://localhost:8000/health > /dev/null 2>&1; then
        print_success "✓ API 健康检查通过"
    else
        print_warn "API 健康检查失败，查看日志..."
        docker-compose logs --tail=30
    fi
}

# ========================================
# 函数：显示部署信息
# ========================================
show_info() {
    echo ""
    echo -e "${GREEN}=====================================${NC}"
    echo -e "${GREEN}     部署完成！${NC}"
    echo -e "${GREEN}=====================================${NC}"
    echo ""
    print_info "API 地址："
    echo "  - HTTP:  http://47.110.72.148:8000"
    echo "  - HTTPS: https://tnho-fasteners.com"
    echo ""
    print_info "常用命令："
    echo "  查看日志：docker-compose logs -f api"
    echo "  重启服务：docker-compose restart"
    echo "  停止服务：docker-compose down"
    echo "  进入容器：docker exec -it tnho-video-api /bin/bash"
    echo ""
    print_info "健康检查："
    echo "  curl http://localhost:8000/health"
    echo ""
    print_info "测试视频生成："
    echo "  curl -X POST http://localhost:8000/api/generate-video \\"
    echo "    -H \"Content-Type: application/json\" \\"
    echo "    -d '{\"product_name\":\"测试产品\",\"theme\":\"品质保证\",\"duration\":5,\"type\":\"script\"}'"
    echo ""
    echo -e "${GREEN}=====================================${NC}"
    echo ""
}

# ========================================
# 主函数
# ========================================
main() {
    echo -e "${CYAN}=====================================${NC}"
    echo -e "${CYAN}天虹紧固件视频API - 完整部署脚本${NC}"
    echo -e "${CYAN}=====================================${NC}"
    echo ""
    
    # 进入项目目录
    print_info "项目目录: $PROJECT_DIR"
    mkdir -p "$PROJECT_DIR"
    cd "$PROJECT_DIR" || exit 1
    
    # 创建所有必需文件
    create_all_files
    
    # 清理旧容器
    cleanup_containers
    
    # 构建和启动
    build_and_start
    
    # 健康检查
    health_check
    
    # 显示信息
    show_info
}

# 执行主函数
main
