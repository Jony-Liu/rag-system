#!/bin/bash
# 安装 systemd 服务脚本
# 使用方式: sudo ./install_service.sh [用户名] [工作目录] [端口]

set -e

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 获取参数
SERVICE_USER=${1:-$USER}
# 如果没有指定工作目录，使用脚本所在目录
if [ -z "$2" ]; then
    WORK_DIR="$SCRIPT_DIR"
else
    # 将工作目录转换为绝对路径
    WORK_DIR="$(cd "$2" && pwd)"
fi
PORT=${3:-8501}

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then 
    echo "错误: 请使用 sudo 运行此脚本"
    exit 1
fi

# 检查用户是否存在
if ! id "$SERVICE_USER" &>/dev/null; then
    echo "错误: 用户 $SERVICE_USER 不存在"
    exit 1
fi

# 检查工作目录是否存在
if [ ! -d "$WORK_DIR" ]; then
    echo "错误: 工作目录 $WORK_DIR 不存在"
    exit 1
fi

# 创建日志目录
mkdir -p "$WORK_DIR/.log"
chown "$SERVICE_USER:$SERVICE_USER" "$WORK_DIR/.log"

# 检测 Python3.11 路径
PYTHON_PATH=$(which python3.11)
if [ -z "$PYTHON_PATH" ]; then
    echo "错误: 未找到 python3.11，请确保已安装 Python3.11"
    exit 1
fi

# 复制服务文件到临时位置并替换变量
SERVICE_FILE="/tmp/rag-streamlit.service"
sed "s|%i|$SERVICE_USER|g; \
     s|/path/to/RAG-cy|$WORK_DIR|g; \
     s|--server.port 8501|--server.port $PORT|g; \
     s|/usr/bin/python3.11|$PYTHON_PATH|g" \
    "$SCRIPT_DIR/rag-streamlit.service" > "$SERVICE_FILE"

# 复制服务文件到 systemd 目录
cp "$SERVICE_FILE" /etc/systemd/system/rag-streamlit.service

# 重新加载 systemd
systemctl daemon-reload

echo "========================================"
echo "服务安装完成！"
echo "========================================"
echo "服务用户: $SERVICE_USER"
echo "工作目录: $WORK_DIR"
echo "端口: $PORT"
echo ""
echo "使用方法:"
echo "  启动服务: sudo systemctl start rag-streamlit"
echo "  停止服务: sudo systemctl stop rag-streamlit"
echo "  查看状态: sudo systemctl status rag-streamlit"
echo "  查看日志: sudo journalctl -u rag-streamlit -f"
echo "  开机自启: sudo systemctl enable rag-streamlit"
echo "  取消自启: sudo systemctl disable rag-streamlit"
echo "========================================"
