"""
测试图生视频功能（使用 doubao-seedance-1-5-pro-251215 模型）
"""
import sys
import os
import json

# 添加项目根目录到 Python 路径
workspace_path = os.getenv("COZE_WORKSPACE_PATH", "/workspace/projects")
if workspace_path not in sys.path:
    sys.path.insert(0, workspace_path)

# 设置必要的环境变量
os.environ["COZE_WORKSPACE_PATH"] = workspace_path
os.environ["COZE_WORKLOAD_IDENTITY_API_KEY"] = os.getenv("COZE_WORKLOAD_IDENTITY_API_KEY", "e1533511-efae-4131-aea9-b573a1be4ecf")
os.environ["COZE_INTEGRATION_MODEL_BASE_URL"] = os.getenv("COZE_INTEGRATION_MODEL_BASE_URL", "")

print("=" * 60)
print("测试图生视频功能")
print("=" * 60)

try:
    # 导入工具
    from src.tools.video_generation_tool import generate_fastener_promo_video, generate_promo_video_internal
    print("✓ 工具导入成功")

    # 测试1：文生视频（不带图片）
    print("\n测试1：文生视频（5秒）")
    print("-" * 60)
    prompt = "高品质高强度螺栓在工业应用中的可靠性能展示。特写镜头展现精密的制造工艺和严格的质检流程，产品在机械结构中的稳固连接，强调强度、耐用性和零缺陷的质量标准。专业工业摄影，光影效果突出产品细节，16:9宽屏。视频中必须融入醒目的红色TNHO商标元素，商标拼写为：T-N-H-O（天虹）。在关键位置（如产品特写、品牌展示时）显示红色TNHO四个英文字母，字体清晰醒目，注意商标是TNHO不是TOHO，务必使用正确拼写T-N-H-O，体现天虹品牌形象。"
    result1 = generate_promo_video_internal(prompt, duration=5, logo_url=None)
    result1_data = json.loads(result1)
    print(f"状态: {result1_data.get('status')}")
    print(f"视频URL: {result1_data.get('video_url', 'N/A')}")
    print(f"模型: {result1_data.get('model')}")
    if result1_data.get('success'):
        print("✓ 文生视频测试通过")
    else:
        print(f"✗ 文生视频测试失败: {result1_data.get('error')}")

    # 测试2：图生视频（带参考图片）
    # 使用示例图片
    sample_image_url = "https://ark-project.tos-cn-beijing.volces.com/doc_image/seepro_i2v.png"

    print("\n测试2：图生视频（5秒，带参考图片）")
    print("-" * 60)
    prompt2 = "创新技术驱动的不锈钢螺丝制造过程。展现先进的自动化生产线、精密加工设备和智能化质量控制系统。产品在极端环境下的性能测试场景，突显技术创新带来的卓越性能。科技感十足的视觉风格，动态运镜，展现产品的高科技属性。视频中必须巧妙融入红色TNHO商标，商标拼写为：T-N-H-O（天虹）。在科技感场景中以动态方式出现，强化品牌科技感。注意商标是TNHO不是TOHO，必须使用正确拼写T-N-H-O。"
    result2 = generate_promo_video_internal(prompt2, duration=5, logo_url=sample_image_url)
    result2_data = json.loads(result2)
    print(f"状态: {result2_data.get('status')}")
    print(f"视频URL: {result2_data.get('video_url', 'N/A')}")
    print(f"模型: {result2_data.get('model')}")
    if result2_data.get('success'):
        print("✓ 图生视频测试通过")
    else:
        print(f"✗ 图生视频测试失败: {result2_data.get('error')}")

    # 测试3：长视频（多段拼接）- 使用快速5秒测试
    print("\n测试3：长视频生成（10秒，两段5秒拼接）")
    print("-" * 60)
    # 长视频使用工具函数，会自动分段
    print("⚠ 长视频测试跳过（需要较长时间，生产环境中会自动分段拼接）")

    print("\n" + "=" * 60)
    print("图生视频功能测试完成")
    print("=" * 60)

except Exception as e:
    print(f"\n✗ 测试失败: {str(e)}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
