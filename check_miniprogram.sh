#!/bin/bash
# 微信小程序完整性检查脚本

echo "========================================="
echo "微信小程序完整性检查"
echo "========================================="
echo ""

MINIPROGRAM_DIR="/workspace/projects/miniprogram"

# 检查必要文件
echo "检查必要文件..."

files=(
    "app.js"
    "app.json"
    "app.wxss"
    "project.config.json"
    "sitemap.json"
)

missing_files=0

for file in "${files[@]}"; do
    if [ -f "$MINIPROGRAM_DIR/$file" ]; then
        echo "✅ $file"
    else
        echo "❌ $file 缺失"
        ((missing_files++))
    fi
done

echo ""
echo "检查页面文件..."

# 检查页面文件
if [ -d "$MINIPROGRAM_DIR/pages/index" ]; then
    echo "✅ pages/index/"
    index_files=("index.js" "index.json" "index.wxml" "index.wxss")
    for file in "${index_files[@]}"; do
        if [ -f "$MINIPROGRAM_DIR/pages/index/$file" ]; then
            echo "  ✅ $file"
        else
            echo "  ❌ $file 缺失"
            ((missing_files++))
        fi
    done
else
    echo "❌ pages/index/ 目录缺失"
    ((missing_files++))
fi

if [ -d "$MINIPROGRAM_DIR/pages/result" ]; then
    echo "✅ pages/result/"
    result_files=("result.js" "result.json" "result.wxml" "result.wxss")
    for file in "${result_files[@]}"; do
        if [ -f "$MINIPROGRAM_DIR/pages/result/$file" ]; then
            echo "  ✅ $file"
        else
            echo "  ❌ $file 缺失"
            ((missing_files++))
        fi
    done
else
    echo "❌ pages/result/ 目录缺失"
    ((missing_files++))
fi

echo ""
echo "检查配置..."

# 检查 AppID
if grep -q "wx464504ca7e01b3b1" "$MINIPROGRAM_DIR/project.config.json"; then
    echo "✅ AppID: wx464504ca7e01b3b1"
else
    echo "❌ AppID 未配置或错误"
    ((missing_files++))
fi

# 检查 API地址
if grep -q "https://tnho-fasteners.com" "$MINIPROGRAM_DIR/app.js"; then
    echo "✅ API地址: https://tnho-fasteners.com"
else
    echo "❌ API地址 未配置或错误"
    ((missing_files++))
fi

echo ""
echo "========================================="
echo "检查结果"
echo "========================================="

if [ $missing_files -eq 0 ]; then
    echo "✅ 所有检查通过！小程序文件完整"
    echo ""
    echo "导入步骤："
    echo "1. 打开微信开发者工具"
    echo "2. 点击 '+' 号或 '导入项目'"
    echo "3. 项目目录选择: $MINIPROGRAM_DIR"
    echo "4. AppID 填入: wx464504ca7e01b3b1"
    echo "5. 项目名称: 天虹紧固件"
    echo "6. 点击 '导入'"
    echo ""
    echo "导入后，请阅读 '导入微信开发者工具指南.md'"
    exit 0
else
    echo "❌ 发现 $missing_files 个问题"
    echo "请检查缺失的文件"
    exit 1
fi
