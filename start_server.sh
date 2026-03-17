#!/bin/bash
# Linux 后台启动 Streamlit 服务器脚本
# 使用方式: ./start_server.sh [port]
# 默认端口: 8501

set -e

# 获取端口参数，默认为 8501
PORT=${1:-8501}

echo "========================================"
echo "启动 RAG Streamlit 服务器"
echo "端口: $PORT"
echo "========================================"
echo ""

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 检查 Python3.11 是否安装
if ! command -v python3.11 &> /dev/null; then
    echo "错误: 未找到 Python3.11，请先安装 Python3.11"
    exit 1
fi

# 检查 streamlit 是否安装
if ! python3.11 -c "import streamlit" 2>/dev/null; then
    echo "错误: 未找到 streamlit，请先安装: pip install streamlit"
    exit 1
fi

# 创建日志目录
mkdir -p .log

# 设置日志文件路径（带时间戳）
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOGFILE=".log/streamlit_${TIMESTAMP}.log"
PIDFILE=".log/streamlit.pid"

# 检查是否已有进程在运行
if [ -f "$PIDFILE" ]; then
    OLD_PID=$(cat "$PIDFILE")
    if ps -p "$OLD_PID" > /dev/null 2>&1; then
        echo "警告: 检测到已有 Streamlit 进程在运行 (PID: $OLD_PID)"
        echo "请先使用 ./stop_server.sh 停止现有服务，或手动终止进程"
        exit 1
    else
        # PID 文件存在但进程不存在，删除旧的 PID 文件
        rm -f "$PIDFILE"
    fi
fi

# 后台启动 Streamlit，将输出重定向到日志文件
echo "正在启动服务器..."
echo "Streamlit 日志将保存到: $LOGFILE"
echo "工作目录: $SCRIPT_DIR"

# 使用 nohup 在后台运行，并将输出重定向到日志文件
nohup python3.11 -m streamlit run app_streamlit.py \
    --server.port "$PORT" \
    --server.headless true \
    > "$LOGFILE" 2>&1 &

# 获取进程 ID
STREAMLIT_PID=$!

# 保存 PID 到文件
echo "$STREAMLIT_PID" > "$PIDFILE"

# 等待一下确保服务启动
sleep 3

# 检查进程是否还在运行
if ps -p "$STREAMLIT_PID" > /dev/null 2>&1; then
    echo ""
    echo "========================================"
    echo "服务器已启动！"
    echo "访问地址: http://localhost:$PORT"
    echo "进程 ID: $STREAMLIT_PID"
    echo "PID 文件: $PIDFILE"
    echo "日志文件: $LOGFILE"
    echo ""
    echo "服务器在后台运行"
    echo "要停止服务器，请使用: ./stop_server.sh"
    echo "或查看日志: tail -f $LOGFILE"
    echo "========================================"
    echo ""
else
    echo "错误: 服务器启动失败，请查看日志文件: $LOGFILE"
    rm -f "$PIDFILE"
    exit 1
fi
