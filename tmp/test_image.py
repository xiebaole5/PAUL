#!/usr/bin/env python3
"""生成测试图片"""
from PIL import Image
import io

# 创建一个简单的测试图片
img = Image.new('RGB', (100, 100), color='red')
img.save('/tmp/test.jpg', 'JPEG')
print("测试图片已生成: /tmp/test.jpg")
