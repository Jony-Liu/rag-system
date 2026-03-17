# 启动指南

## 方式一：Shell 脚本（简单快速）

### 首次使用
```bash
chmod +x start_server.sh stop_server.sh
```

### 启动服务
```bash
./start_server.sh          # 默认端口 8501
./start_server.sh 8502      # 指定端口
```

### 停止服务
```bash
./stop_server.sh
```

### 查看日志
```bash
tail -f .log/streamlit_*.log
```

---

## 方式二：systemd 服务（生产环境推荐）

### 安装服务
```bash
chmod +x install_service.sh
sudo ./install_service.sh [用户名] [工作目录] [端口]

# 示例：使用当前用户和当前目录
sudo ./install_service.sh $USER $(pwd) 8501
```

### 管理服务
```bash
# 启动
sudo systemctl start rag-streamlit

# 停止
sudo systemctl stop rag-streamlit

# 重启
sudo systemctl restart rag-streamlit

# 状态
sudo systemctl status rag-streamlit

# 日志
sudo journalctl -u rag-streamlit -f

# 开机自启
sudo systemctl enable rag-streamlit
```

---

## 检查服务状态

```bash
# 查看进程
ps aux | grep streamlit

# 查看端口
netstat -tlnp | grep 8501
# 或
lsof -i :8501
```

---

## 访问应用

启动成功后，在浏览器访问：
```
http://localhost:8501
```

或从其他机器访问（需要配置防火墙）：
```
http://服务器IP:8501
```
