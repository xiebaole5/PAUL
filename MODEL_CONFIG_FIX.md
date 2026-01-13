# 模型配置修复总结

## 问题诊断

测试时出现错误：`code=190000006 message=not found model not found`

**根本原因**：配置文件中使用的模型名称无效

## 修复内容

### 1. 修复 LLM 模型配置（文本处理）

**文件**：`config/agent_llm_config.json`

**变更**：
```json
{
    "config": {
        "model": "doubao-seed-1-6-251015",  // 修复前：doubao-1.8 或 Doubao-seed-1.8-251228
        "temperature": 0.7,
        "top_p": 0.9,
        "max_completion_tokens": 8000,
        "timeout": 600,
        "thinking": "disabled"
    }
}
```

**说明**：使用集成文档中确认可用的模型 `doubao-seed-1-6-251015`

### 2. 修复视频生成模型配置

**文件**：`src/tools/video_generation_tool.py`

**变更**：
```python
# 修复前
MODEL_NAME = "doubao-seedance-1-5-pro"

# 修复后
MODEL_NAME = "Doubao-1.5-vision-pro-250328"
```

**说明**：使用您提供的视频生成模型名称

### 3. 优化 API Key 配置

**文件**：
- `src/agents/agent.py`
- `src/tools/video_generation_tool.py`

**变更**：
```python
# 修复前（强制要求环境变量）
api_key = os.getenv("COZE_WORKLOAD_IDENTITY_API_KEY")
if not api_key:
    raise ValueError("COZE_WORKLOAD_IDENTITY_API_KEY 环境变量未设置")

# 修复后（支持环境变量或使用默认值）
api_key = os.getenv("ARK_API_KEY") or os.getenv("COZE_WORKLOAD_IDENTITY_API_KEY") or "e1533511-efae-4131-aea9-b573a1be4ecf"
```

**说明**：提供默认 API Key 作为兜底，避免环境变量未配置时无法启动

### 4. 优化 Base URL 配置

**文件**：`src/agents/agent.py`

**变更**：
```python
# 修复前（强制要求环境变量）
base_url = os.getenv("COZE_INTEGRATION_MODEL_BASE_URL")
if not base_url:
    raise ValueError("COZE_INTEGRATION_MODEL_BASE_URL 环境变量未设置")

# 修复后（支持环境变量或使用默认值）
base_url = os.getenv("COZE_INTEGRATION_MODEL_BASE_URL") or os.getenv("ARK_BASE_URL") or "https://ark.cn-beijing.volces.com/api/v3"
```

## 测试结果

✅ **脚本生成功能测试通过**

测试输入：
```
请为"高强度螺栓"生成一个20秒的品质保证主题的宣传视频脚本
```

测试输出：成功生成详细的20秒视频脚本，包含分镜、文案、音效等完整内容

## 服务器部署步骤

### 方式一：快速重新部署

```bash
cd /root/tnho-video-generator

# 停止并删除旧容器
docker-compose down

# 重新构建镜像
docker-compose build --no-cache

# 启动服务
docker-compose up -d

# 查看日志
docker-compose logs -f api
```

### 方式二：使用修复脚本

如果您之前创建了 `fix_module_import.sh`，可以直接运行：

```bash
cd /root/tnho-video-generator
bash fix_module_import.sh
```

## 验证步骤

### 1. 检查容器状态
```bash
docker-compose ps
```
期望输出：
```
tnho-nginx       Up    0.0.0.0:80->80/tcp
tnho-video-api   Up    0.0.0.0:8000->8000/tcp
```

### 2. 测试健康检查
```bash
curl http://localhost:8000/health
```
期望输出：
```json
{"status":"ok"}
```

### 3. 测试脚本生成接口
```bash
curl -X POST http://localhost:8000/api/generate-video \
  -H "Content-Type: application/json" \
  -d '{
    "product_name": "高强度螺栓",
    "theme": "品质保证",
    "duration": 20,
    "type": "script"
  }'
```

### 4. 访问 API 文档
浏览器打开：http://47.110.72.148/docs

## 模型配置说明

### 文本处理模型（LLM）
- **模型名称**：`doubao-seed-1-6-251015`
- **用途**：处理文本内容、生成脚本、对话交互
- **配置位置**：`config/agent_llm_config.json`

### 视频生成模型
- **模型名称**：`Doubao-1.5-vision-pro-250328`
- **用途**：生成产品宣传视频
- **配置位置**：`src/tools/video_generation_tool.py`

### API 配置
- **Base URL**：`https://ark.cn-beijing.volces.com/api/v3`
- **API Key**：`e1533511-efae-4131-aea9-b573a1be4ecf`

## 注意事项

1. **视频生成功能**
   - 视频生成可能需要较长时间（几分钟到十几分钟）
   - 需要调用火山方舟视频生成 API
   - 建议先使用脚本生成功能进行测试

2. **环境变量优先级**
   - 优先使用环境变量配置
   - 如果环境变量未设置，使用硬编码的默认值
   - 生产环境建议使用环境变量管理敏感信息

3. **容器资源**
   - 视频生成可能消耗较多资源
   - 建议监控容器资源使用情况
   - 如需要可以调整容器资源限制

## 故障排查

### 问题 1：模型未找到错误

**症状**：`code=190000006 message=not found model not found`

**解决方案**：检查模型名称是否正确，使用集成文档中确认的模型名称

### 问题 2：API Key 无效

**症状**：`401 Unauthorized` 或 API 调用失败

**解决方案**：
- 检查 API Key 是否正确
- 确认 API Key 是否有效
- 检查火山方舟账户状态

### 问题 3：视频生成失败

**症状**：视频生成任务创建失败或超时

**排查步骤**：
```bash
# 查看容器日志
docker-compose logs api | grep "video"

# 检查网络连接
docker exec -it tnho-video-api ping ark.cn-beijing.volces.com

# 检查 API 可用性
curl -H "Authorization: Bearer e1533511-efae-4131-aea9-b573a1be4ecf" \
     https://ark.cn-beijing.volces.com/api/v3/contents/generations/tasks
```

## 后续优化建议

1. **性能优化**
   - 考虑添加任务队列处理视频生成请求
   - 实现异步任务查询机制
   - 添加任务状态缓存

2. **错误处理**
   - 添加更详细的错误信息返回
   - 实现重试机制
   - 添加超时控制

3. **监控告警**
   - 监控 API 调用成功率
   - 监控视频生成任务状态
   - 设置异常告警

---

**修复日期**：2025-01-XX
**测试状态**：脚本生成功能测试通过
**部署状态**：等待用户在服务器上重新部署
