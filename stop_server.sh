#!/bin/bash
# Linux 停止 Streamlit 服务器脚本

set -e

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

PIDFILE=".log/streamlit.pid"

echo "========================================"
echo "查找并停止 Streamlit 服务器进程"
echo "========================================"
echo ""

# 方法1: 从 PID 文件读取进程 ID
if [ -f "$PIDFILE" ]; then
    PID=$(cat "$PIDFILE")
    if ps -p "$PID" > /dev/null 2>&1; then
        echo "从 PID 文件找到进程，PID: $PID"
        kill "$PID" 2>/dev/null || true
        # 等待进程结束
        sleep 2
        # 如果还在运行，强制终止
        if ps -p "$PID" > /dev/null 2>&1; then
            echo "强制终止进程 $PID"
            kill -9 "$PID" 2>/dev/null || true
        fi
        echo "已停止进程 $PID"
        rm -f "$PIDFILE"
    else
        echo "PID 文件中的进程已不存在，清理 PID 文件"
        rm -f "$PIDFILE"
    fi
fi

# 方法2: 查找所有包含 streamlit 的 Python3.11 进程
PIDS=$(pgrep -f "python3.11.*streamlit run app_streamlit.py" 2>/dev/null || true)

if [ -z "$PIDS" ]; then
    echo "未找到运行中的 Streamlit 服务器进程"
else
    for PID in $PIDS; do
        echo "找到 Streamlit 进程，PID: $PID"
        kill "$PID" 2>/dev/null || true
        sleep 1
        # 如果还在运行，强制终止
        if ps -p "$PID" > /dev/null 2>&1; then
            echo "强制终止进程 $PID"
            kill -9 "$PID" 2>/dev/null || true
        fi
        echo "已停止进程 $PID"
    done
fi

echo ""
echo "========================================"
echo "操作完成"
echo "========================================"
