#!/bin/bash

# 天虹紧固件视频生成项目打包脚本

set -e

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 配置
PROJECT_NAME="tnho-video-generator"
OUTPUT_DIR="dist"
VERSION=$(date +%Y%m%d_%H%M%S)
ARCHIVE_NAME="${PROJECT_NAME}_v${VERSION}.tar.gz"

# 项目根目录
PROJECT_ROOT="/workspace/projects"
cd "$PROJECT_ROOT"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  项目打包工具${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

# 排除的文件和目录
EXCLUDE_LIST=(
    "__pycache__"
    "*.pyc"
    ".git"
    ".gitignore"
    ".DS_Store"
    "node_modules"
    ".pytest_cache"
    ".coverage"
    "htmlcov"
    "*.log"
    "dist"
    ".env.local"
    ".env.*.local"
)

# 构建排除参数
EXCLUDE_ARGS=()
for item in "${EXCLUDE_LIST[@]}"; do
    EXCLUDE_ARGS+=(--exclude="$item")
done

echo -e "${YELLOW}开始打包...${NC}"
echo "输出文件: $OUTPUT_DIR/$ARCHIVE_NAME"
echo ""

# 打包
tar -czf "$OUTPUT_DIR/$ARCHIVE_NAME" \
    "${EXCLUDE_ARGS[@]}" \
    .

# 计算文件大小
SIZE=$(du -h "$OUTPUT_DIR/$ARCHIVE_NAME" | cut -f1)

# 列出主要文件内容
echo -e "${GREEN}✓ 打包完成${NC}"
echo "文件大小: $SIZE"
echo ""
echo "压缩包主要内容："
echo "----------------------------------------"
tar -tzf "$OUTPUT_DIR/$ARCHIVE_NAME" | head -30
echo "----------------------------------------"
echo ""

# 生成文件清单
MANIFEST_FILE="$OUTPUT_DIR/manifest.txt"
echo "天虹紧固件视频生成项目清单" > "$MANIFEST_FILE"
echo "生成时间: $(date)" >> "$MANIFEST_FILE"
echo "版本: $VERSION" >> "$MANIFEST_FILE"
echo "文件大小: $SIZE" >> "$MANIFEST_FILE"
echo "" >> "$MANIFEST_FILE"
echo "包含文件:" >> "$MANIFEST_FILE"
tar -tzf "$OUTPUT_DIR/$ARCHIVE_NAME" | sort >> "$MANIFEST_FILE"

echo -e "${GREEN}✓ 清单已生成: $MANIFEST_FILE${NC}"
echo ""

# 创建快速开始指南
QUICKSTART_FILE="$OUTPUT_DIR/QUICKSTART.md"
cat > "$QUICKSTART_FILE" << 'EOF'
# 天虹紧固件视频生成项目 - 快速开始指南

## 🚀 快速部署

### 1. 解压项目

```bash
tar -xzf tnho-video-generator_v*.tar.gz
cd tnho-video-generator/
```

### 2. 安装依赖

```bash
pip install -r requirements.txt
```

### 3. 配置环境变量

创建 `.env` 文件：

```bash
ARK_API_KEY=your_api_key_here
```

### 4. 启动后端服务

```bash
# Linux/Mac
chmod +x scripts/start_backend.sh
./scripts/start_backend.sh

# Windows
scripts\start_backend.bat
```

### 5. 启动小程序

1. 打开微信开发者工具
2. 导入 `miniprogram` 目录
3. 配置后端地址：`http://localhost:8000`
4. 开始调试

详细文档请查看：
- `DEPLOYMENT_GUIDE.md` - 完整部署指南
- `MINIPROGRAM_README.md` - 小程序使用说明
- `PACKAGE_GUIDE.md` - 打包和下载指南

## 📋 项目结构

```
.
├── src/                 # 后端源代码
│   ├── agents/          # Agent 代码
│   ├── tools/           # 工具代码
│   ├── storage/         # 存储模块
│   └── api/             # API 服务
├── miniprogram/         # 微信小程序前端
├── config/              # 配置文件
├── scripts/             # 脚本工具
├── docs/                # 文档
├── requirements.txt     # Python 依赖
└── DEPLOYMENT_GUIDE.md  # 部署指南
```

## 📞 获取帮助

如遇到问题，请查看：
- 部署问题：`DEPLOYMENT_GUIDE.md`
- 小程序问题：`MINIPROGRAM_README.md`
- 打包问题：`PACKAGE_GUIDE.md`

---

**祝部署顺利！🎉**
EOF

echo -e "${GREEN}✓ 快速开始指南已生成: $QUICKSTART_FILE${NC}"
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}打包完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "📦 压缩包: $OUTPUT_DIR/$ARCHIVE_NAME"
echo "📄 清单文件: $MANIFEST_FILE"
echo "📖 快速开始: $QUICKSTART_FILE"
echo ""
