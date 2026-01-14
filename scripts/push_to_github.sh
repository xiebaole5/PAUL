#!/bin/bash
# TNHO 视频生成项目 - Git 推送脚本
# 将代码推送到 GitHub 仓库

set -e

echo "=========================================="
echo "TNHO 视频生成项目 - Git 推送"
echo "=========================================="
echo ""

cd /workspace/projects

# 检查是否有未提交的更改
if [ -n "$(git status --porcelain)" ]; then
    echo "发现未提交的更改，正在提交..."
    git add .
    git commit -m "Complete TNHO video generation agent code"
fi

# 检查是否已配置远程仓库
if ! git remote get-url origin &>/dev/null; then
    echo "配置远程仓库..."
    git remote add origin https://github.com/xiebaole5/PAUL.git
fi

echo "准备推送到 GitHub: https://github.com/xiebaole5/PAUL.git"
echo ""

# 检查是否已认证
echo "检查 GitHub 认证..."
if git ls-remote git@github.com:xiebaole5/PAUL.git &>/dev/null; then
    echo "✅ SSH 认证已配置"
    git remote set-url origin git@github.com:xiebaole5/PAUL.git
    echo "使用 SSH 推送..."
    git push -u origin main
else
    echo "⚠️  未检测到 SSH 密钥认证"
    echo ""
    echo "请选择认证方式："
    echo "1. 使用 SSH 密钥（推荐）"
    echo "2. 使用 Personal Access Token (HTTPS)"
    echo ""
    read -p "请输入选择 (1/2): " choice

    case $choice in
        1)
            echo ""
            echo "=========================================="
            echo "SSH 密钥配置步骤："
            echo "=========================================="
            echo "1. 生成 SSH 密钥（在您的 Windows 本地执行）："
            echo "   ssh-keygen -t ed25519 -C 'your_email@example.com'"
            echo ""
            echo "2. 查看公钥内容："
            echo "   cat ~/.ssh/id_ed25519.pub"
            echo ""
            echo "3. 将公钥添加到 GitHub："
            echo "   - 访问 https://github.com/settings/keys"
            echo "   - 点击 'New SSH key'"
            echo "   - 粘贴公钥内容"
            echo ""
            echo "4. 配置完成后，执行："
            echo "   git remote set-url origin git@github.com:xiebaole5/PAUL.git"
            echo "   git push -u origin main"
            echo ""
            exit 0
            ;;
        2)
            echo ""
            echo "使用 Personal Access Token 推送..."
            echo ""
            echo "=========================================="
            echo "Personal Access Token 获取步骤："
            echo "=========================================="
            echo "1. 访问 https://github.com/settings/tokens"
            echo "2. 点击 'Generate new token' -> 'Generate new token (classic)'"
            echo "3. 勾选 'repo' 权限"
            echo "4. 点击 'Generate token' 并复制 token"
            echo ""
            echo "注意：Token 只显示一次，请妥善保存"
            echo ""

            read -sp "请输入 GitHub Token: " token
            echo ""
            echo ""

            # 使用 token 推送
            echo "正在推送..."
            git remote set-url origin https://${token}@github.com/xiebaole5/PAUL.git
            git push -u origin main

            # 恢复正常 URL
            git remote set-url origin https://github.com/xiebaole5/PAUL.git

            echo ""
            echo "✅ 推送成功！"
            echo ""
            echo "仓库地址: https://github.com/xiebaole5/PAUL"
            ;;
        *)
            echo "无效选择"
            exit 1
            ;;
    esac
fi

echo ""
echo "=========================================="
echo "推送完成！"
echo "=========================================="
echo "仓库地址: https://github.com/xiebaole5/PAUL"
echo ""
echo "下一步：在服务器上克隆代码"
echo "  ssh root@47.110.72.148"
echo "  git clone git@github.com:xiebaole5/PAUL.git tnho-video"
echo ""
