# 项目打包和下载指南

## 📦 完整下载包创建

本指南教你如何创建一个完整的、可下载的项目压缩包。

---

## 方法一：直接压缩项目目录（推荐）

### 步骤

1. **进入项目根目录**

```bash
cd /workspace/projects
```

2. **创建压缩包**

```bash
# 创建 .tar.gz 压缩包（Linux/Mac 推荐）
tar -czf tnho-video-generator.tar.gz \
    --exclude='__pycache__' \
    --exclude='*.pyc' \
    --exclude='.git' \
    --exclude='.DS_Store' \
    --exclude='node_modules' \
    --exclude='.pytest_cache' \
    --exclude='.coverage' \
    --exclude='*.log' \
    .

# 或创建 .zip 压缩包（Windows 推荐）
zip -r tnho-video-generator.zip . -x \
    "*__pycache__*" \
    "*.pyc" \
    ".git/*" \
    ".DS_Store" \
    "node_modules/*" \
    ".pytest_cache/*" \
    ".coverage" \
    "*.log"
```

3. **验证压缩包**

```bash
# 查看压缩包内容
tar -tzf tnho-video-generator.tar.gz | head -20
```

---

## 方法二：使用脚本自动打包

### 创建打包脚本

创建 `scripts/package.sh`：

```bash
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

详细文档请查看 `DEPLOYMENT_GUIDE.md`
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
```

### 执行打包脚本

```bash
# 添加执行权限
chmod +x scripts/package.sh

# 执行打包
./scripts/package.sh
```

---

## 方法三：创建分发包（推荐给用户）

### 创建包含说明的分发包

创建 `scripts/create_distribution.sh`：

```bash
#!/bin/bash

# 创建分发包

PROJECT_ROOT="/workspace/projects"
VERSION=$(date +%Y%m%d)
DIST_DIR="tnho-video-generator-${VERSION}"

echo "创建分发包..."

# 创建临时目录
mkdir -p "$DIST_DIR"

# 复制必要文件
cp -r "$PROJECT_ROOT/src" "$DIST_DIR/"
cp -r "$PROJECT_ROOT/miniprogram" "$DIST_DIR/"
cp -r "$PROJECT_ROOT/config" "$DIST_DIR/"
cp -r "$PROJECT_ROOT/scripts" "$DIST_DIR/"
cp -r "$PROJECT_ROOT/docs" "$DIST_DIR/" 2>/dev/null || true

# 复制配置文件
cp "$PROJECT_ROOT/requirements.txt" "$DIST_DIR/"
cp "$PROJECT_ROOT/README.md" "$DIST_DIR/" 2>/dev/null || true
cp "$PROJECT_ROOT/DEPLOYMENT_GUIDE.md" "$DIST_DIR/" 2>/dev/null || true
cp "$PROJECT_ROOT/MINIPROGRAM_README.md" "$DIST_DIR/" 2>/dev/null || true

# 创建 README
cat > "$DIST_DIR/README.md" << 'EOF'
# 天虹紧固件视频生成系统

## 快速开始

1. 安装依赖：`pip install -r requirements.txt`
2. 配置 API Key：创建 `.env` 文件并设置 `ARK_API_KEY`
3. 启动后端：`./scripts/start_backend.sh`
4. 打开小程序：用微信开发者工具导入 `miniprogram` 目录

详细文档请查看：
- `DEPLOYMENT_GUIDE.md` - 完整部署指南
- `MINIPROGRAM_README.md` - 小程序使用说明
EOF

# 打包
tar -czf "${DIST_DIR}.tar.gz" "$DIST_DIR"

# 清理临时目录
rm -rf "$DIST_DIR"

echo "分发包创建完成: ${DIST_DIR}.tar.gz"
```

---

## 📋 下载包内容清单

### 完整包包含的文件

```
tnho-video-generator/
├── src/                           # 源代码
│   ├── agents/                    # Agent 代码
│   │   └── agent.py
│   ├── tools/                     # 工具代码
│   │   ├── video_generation_tool.py
│   │   └── video_script_generator.py
│   ├── storage/                   # 存储模块
│   ├── utils/                     # 工具函数
│   ├── api/                       # API 服务
│   │   └── app.py
│   └── main.py
├── miniprogram/                   # 微信小程序
│   ├── app.js
│   ├── app.json
│   ├── app.wxss
│   ├── project.config.json
│   ├── pages/
│   │   └── index/
│   │       ├── index.js
│   │       ├── index.json
│   │       ├── index.wxml
│   │       └── index.wxss
│   └── sitemap.json
├── config/                        # 配置文件
│   └── agent_llm_config.json
├── scripts/                       # 脚本
│   ├── start_backend.sh
│   ├── start_backend.bat
│   └── package.sh
├── docs/                          # 文档
├── tests/                         # 测试
├── requirements.txt               # Python 依赖
├── DEPLOYMENT_GUIDE.md            # 部署指南
├── MINIPROGRAM_README.md          # 小程序说明
├── README.md                      # 项目说明
└── QUICKSTART.md                  # 快速开始（打包时生成）
```

---

## 🌐 提供下载的方式

### 方式一：直接文件下载

如果项目部署在有文件服务器的环境中：

```bash
# 将压缩包移动到可下载目录
mv dist/tnho-video-generator_v*.tar.gz /path/to/download/directory/

# 或创建下载链接
ln -s dist/tnho-video-generator_v*.tar.gz /path/to/download/tnho-video-generator-latest.tar.gz
```

### 方式二：创建下载脚本

创建 `scripts/download.sh`：

```bash
#!/bin/bash

echo "下载天虹紧固件视频生成系统..."
echo ""

# 下载链接（替换为实际链接）
DOWNLOAD_URL="https://your-domain.com/tnho-video-generator-latest.tar.gz"

# 下载文件
curl -O "$DOWNLOAD_URL"

# 解压
tar -xzf tnho-video-generator-latest.tar.gz

echo "下载完成！"
echo "请阅读 README.md 开始部署"
```

### 方式三：GitHub Release（推荐用于开源）

如果项目托管在 GitHub：

1. 创建 Release：
   - 登录 GitHub
   - 进入项目页面
   - 点击「Releases」
   - 点击「Create a new release」

2. 上传压缩包：
   - 拖拽压缩包到附件区域
   - 填写 Release 说明

3. 提供下载链接：
   - `https://github.com/your-repo/releases/latest`
   - 或直接下载压缩包链接

---

## 📝 用户接收后的步骤

### 1. 下载和解压

```bash
# 下载
wget https://your-domain.com/tnho-video-generator.tar.gz

# 或使用 curl
curl -O https://your-domain.com/tnho-video-generator.tar.gz

# 解压
tar -xzf tnho-video-generator.tar.gz
cd tnho-video-generator/
```

### 2. 查看文档

```bash
# 快速开始
cat QUICKSTART.md

# 完整部署指南
cat DEPLOYMENT_GUIDE.md

# 小程序说明
cat MINIPROGRAM_README.md
```

### 3. 开始部署

按照 `DEPLOYMENT_GUIDE.md` 中的步骤进行部署。

---

## ✅ 打包检查清单

在发布下载包之前，确认：

- [ ] 所有必要的源代码文件都已包含
- [ ] 配置文件（config/）已包含
- [ ] 小程序代码（miniprogram/）已包含
- [ ] 文档文件完整
- [ ] requirements.txt 已包含
- [ ] 启动脚本（scripts/）已包含
- [ ] 敏感信息已从代码中移除（API Key、密码等）
- [ ] 压缩包可以正常解压
- [ ] 解压后项目可以正常运行
- [ ] 文档内容准确无误

---

## 🚀 快速打包命令

### 一键打包（推荐）

```bash
# 完整打包
./scripts/package.sh

# 或手动打包
tar -czf tnho-video-generator-$(date +%Y%m%d).tar.gz \
    --exclude='__pycache__' \
    --exclude='*.pyc' \
    --exclude='.git' \
    --exclude='node_modules' \
    --exclude='.pytest_cache' \
    --exclude='*.log' \
    .
```

---

## 📞 获取帮助

如果在打包过程中遇到问题：

1. 查看项目文档：`DEPLOYMENT_GUIDE.md`
2. 检查打包脚本：`scripts/package.sh`
3. 验证文件权限：`ls -la scripts/`

---

**打包完成！🎉**
