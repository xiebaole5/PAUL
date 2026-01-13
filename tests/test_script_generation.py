"""
测试视频脚本生成功能
"""
import sys
import os

# 添加项目根目录到 Python 路径
workspace_path = os.getenv("COZE_WORKSPACE_PATH", "/workspace/projects")
if workspace_path not in sys.path:
    sys.path.insert(0, workspace_path)

src_path = os.path.join(workspace_path, "src")
if src_path not in sys.path:
    sys.path.insert(0, src_path)

# 设置必要的环境变量
os.environ["COZE_WORKSPACE_PATH"] = workspace_path

print("=" * 60)
print("测试视频脚本生成功能")
print("=" * 60)

try:
    # 导入脚本生成工具
    from tools.video_script_generator import generate_fastener_promo_script
    print("✓ 脚本生成工具导入成功")

    # 测试不同时长的脚本生成
    durations = [5, 10, 15, 20, 25, 30]
    product_name = "高强度螺栓"
    theme = "品质保证"

    print("\n开始测试不同时长的脚本生成...")
    print("-" * 60)

    for duration in durations:
        print(f"\n测试时长：{duration}秒")
        print("-" * 40)

        # 调用脚本生成工具
        result = generate_fastener_promo_script.func(
            duration=duration,
            product_name=product_name,
            theme=theme
        )

        # 显示结果（截取前500字符）
        preview = result[:500] if len(result) > 500 else result
        print(f"脚本预览：\n{preview}...")

        # 验证关键元素
        required_elements = ["场景", "文案/旁白", "音效", "TNHO", "1987"]
        missing_elements = [elem for elem in required_elements if elem not in result]

        if missing_elements:
            print(f"✗ 缺少关键元素：{', '.join(missing_elements)}")
        else:
            print("✓ 包含所有关键元素")

        # 验证时长
        if f"视频时长：{duration}秒" in result:
            print(f"✓ 时长标记正确")
        else:
            print(f"✗ 缺少时长标记")

    print("\n" + "=" * 60)
    print("测试完成！")
    print("=" * 60)

except Exception as e:
    print(f"\n✗ 测试失败: {str(e)}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
