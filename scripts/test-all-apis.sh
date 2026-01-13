#!/bin/bash

# 小程序功能测试脚本
# 用于快速验证所有 API 接口是否正常工作

set -e

API_BASE_URL="https://tnho-fasteners.com"
COLOR_GREEN='\033[0;32m'
COLOR_RED='\033[0;31m'
COLOR_YELLOW='\033[1;33m'
COLOR_BLUE='\033[0;34m'
COLOR_RESET='\033[0m'

# 打印带颜色的消息
print_success() {
    echo -e "${COLOR_GREEN}✓ $1${COLOR_RESET}"
}

print_error() {
    echo -e "${COLOR_RED}✗ $1${COLOR_RESET}"
}

print_info() {
    echo -e "${COLOR_BLUE}ℹ $1${COLOR_RESET}"
}

print_warning() {
    echo -e "${COLOR_YELLOW}⚠ $1${COLOR_RESET}"
}

print_header() {
    echo ""
    echo -e "${COLOR_BLUE}========================================${COLOR_RESET}"
    echo -e "${COLOR_BLUE}$1${COLOR_RESET}"
    echo -e "${COLOR_BLUE}========================================${COLOR_RESET}"
}

# 测试函数
test_api() {
    local name="$1"
    local url="$2"
    local method="$3"
    local data="$4"
    local expected_code="${5:-200}"

    print_info "测试: $name"
    echo "   URL: $url"
    echo "   Method: $method"

    if [ -n "$data" ]; then
        response=$(curl -s -w "\n%{http_code}" -X "$method" "$url" \
            -H "Content-Type: application/json" \
            -d "$data" 2>&1)
    else
        response=$(curl -s -w "\n%{http_code}" -X "$method" "$url" 2>&1)
    fi

    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')

    echo "   HTTP Code: $http_code"

    if [ "$http_code" == "$expected_code" ]; then
        print_success "$name - 通过"
        echo "   响应: $body" | head -c 200
        return 0
    else
        print_error "$name - 失败 (期望: $expected_code, 实际: $http_code)"
        echo "   响应: $body"
        return 1
    fi
}

# 创建测试文件
create_test_file() {
    cat > /tmp/test_upload.txt << 'EOF'
This is a test file for image upload.
EOF
}

# 清理函数
cleanup() {
    rm -f /tmp/test_upload.txt
    print_info "清理临时文件"
}

trap cleanup EXIT

# ===== 开始测试 =====

print_header "小程序 API 接口测试"
print_info "测试时间: $(date '+%Y-%m-%d %H:%M:%S')"
print_info "API 地址: $API_BASE_URL"
echo ""

# 创建测试文件
create_test_file

# 统计变量
total_tests=0
passed_tests=0
failed_tests=0

# ===== 1. 基础连接测试 =====
print_header "1. 基础连接测试"

total_tests=$((total_tests + 1))
if curl -s -o /dev/null -w "%{http_code}" "$API_BASE_URL/" | grep -q "200\|301\|302"; then
    passed_tests=$((passed_tests + 1))
    print_success "服务器连接正常"
else
    failed_tests=$((failed_tests + 1))
    print_error "服务器连接失败"
fi

total_tests=$((total_tests + 1))
if curl -s -o /dev/null -w "%{http_code}" "$API_BASE_URL/api/health" | grep -q "200"; then
    passed_tests=$((passed_tests + 1))
    print_success "健康检查接口正常"
else
    failed_tests=$((failed_tests + 1))
    print_warning "健康检查接口不存在或失败"
fi

# ===== 2. 图片上传测试 =====
print_header "2. 图片上传测试"

total_tests=$((total_tests + 1))
print_info "测试: 图片上传接口"
upload_response=$(curl -s -w "\n%{http_code}" -X POST "$API_BASE_URL/api/upload-image" \
    -F "file=@/tmp/test_upload.txt" 2>&1)

upload_code=$(echo "$upload_response" | tail -n1)
upload_body=$(echo "$upload_response" | sed '$d')

echo "   HTTP Code: $upload_code"
echo "   响应: $upload_body" | head -c 200

if echo "$upload_code" | grep -q "200"; then
    passed_tests=$((passed_tests + 1))
    print_success "图片上传接口正常"

    # 提取图片 URL
    if echo "$upload_body" | grep -q '"url"'; then
        uploaded_url=$(echo "$upload_body" | grep -o '"url":"[^"]*"' | cut -d'"' -f4)
        print_info "上传的图片 URL: $uploaded_url"
    fi
else
    failed_tests=$((failed_tests + 1))
    print_error "图片上传接口失败"
fi

# ===== 3. 脚本生成测试 =====
print_header "3. 脚本生成测试"

total_tests=$((total_tests + 1))
if test_api "脚本生成接口" "$API_BASE_URL/api/generate-script" "POST" \
    '{"theme": "品质保证", "duration": 20}' "200"; then
    passed_tests=$((passed_tests + 1))
else
    failed_tests=$((failed_tests + 1))
fi

# ===== 4. 视频生成测试 =====
print_header "4. 视频生成测试"

total_tests=$((total_tests + 1))
video_response=$(curl -s -w "\n%{http_code}" -X POST "$API_BASE_URL/api/generate-video" \
    -H "Content-Type: application/json" \
    -d '{"theme": "品质保证", "duration": 20}' 2>&1)

video_code=$(echo "$video_response" | tail -n1)
video_body=$(echo "$video_response" | sed '$d')

echo "   HTTP Code: $video_code"
echo "   响应: $video_body" | head -c 200

if echo "$video_code" | grep -q "200"; then
    passed_tests=$((passed_tests + 1))
    print_success "视频生成接口正常"

    # 提取 task_id
    if echo "$video_body" | grep -q '"task_id"'; then
        task_id=$(echo "$video_body" | grep -o '"task_id":"[^"]*"' | cut -d'"' -f4)
        print_info "任务 ID: $task_id"

        # 测试进度查询
        total_tests=$((total_tests + 1))
        progress_response=$(curl -s "$API_BASE_URL/api/progress/$task_id" 2>&1)
        print_info "进度查询响应: $progress_response"
        passed_tests=$((passed_tests + 1))
        print_success "进度查询接口正常"
    fi
else
    failed_tests=$((failed_tests + 1))
    print_error "视频生成接口失败"
fi

# ===== 5. 服务器状态检查 =====
print_header "5. 服务器状态检查"

# 检查 Nginx
total_tests=$((total_tests + 1))
if sudo systemctl is-active --quiet nginx; then
    passed_tests=$((passed_tests + 1))
    print_success "Nginx 运行正常"
else
    failed_tests=$((failed_tests + 1))
    print_error "Nginx 未运行"
fi

# 检查 Python 应用
total_tests=$((total_tests + 1))
if ps aux | grep -q "[u]vicorn app:app"; then
    passed_tests=$((passed_tests + 1))
    print_success "Python 应用运行正常"
else
    failed_tests=$((failed_tests + 1))
    print_error "Python 应用未运行"
fi

# 检查 PostgreSQL
total_tests=$((total_tests + 1))
if docker ps | grep -q "tnho-postgres"; then
    passed_tests=$((passed_tests + 1))
    print_success "PostgreSQL 容器运行正常"
else
    failed_tests=$((failed_tests + 1))
    print_error "PostgreSQL 容器未运行"
fi

# 检查 SSL 证书
total_tests=$((total_tests + 1))
if sudo certbot certificates 2>&1 | grep -q "VALID: True"; then
    passed_tests=$((passed_tests + 1))
    print_success "SSL 证书有效"
else
    failed_tests=$((failed_tests + 1))
    print_error "SSL 证书无效或即将过期"
fi

# ===== 测试结果汇总 =====
print_header "测试结果汇总"
echo "总测试数: $total_tests"
echo -e "${COLOR_GREEN}通过: $passed_tests${COLOR_RESET}"
echo -e "${COLOR_RED}失败: $failed_tests${COLOR_RESET}"

if [ $failed_tests -eq 0 ]; then
    echo ""
    print_success "所有测试通过！小程序可以正常使用。"
    exit 0
else
    echo ""
    print_warning "有 $failed_tests 个测试失败，请检查相关接口和配置。"
    echo ""
    print_info "查看详细日志："
    echo "  tail -f /root/tnho-video/logs/app.log"
    echo ""
    print_info "查看 Nginx 日志："
    echo "  tail -f /var/log/nginx/error.log"
    exit 1
fi
