#!/data/data/com.termux/files/usr/bin/bash
# ============================================
# BAL 快速内网穿透 (无需配置文件)
# ============================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

show_menu() {
    clear
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}     BAL 快速内网穿透${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo "1) Cloudflared - 穿透前端 (localhost:3000)"
    echo "2) Cloudflared - 穿透 RPC (localhost:8545)"
    echo "3) Cloudflared - 穿透前端+RPC (临时URL)"
    echo "4) Cpolar - 穿透前端 (需先设置 token)"
    echo "5) 停止所有隧道"
    echo "6) 查看运行状态"
    echo "7) 安装/更新工具"
    echo "0) 退出"
    echo ""
    echo -e "${YELLOW}提示: 按 Ctrl+C 停止当前隧道${NC}"
    echo ""
}

run_frontend() {
    echo -e "${BLUE}[*] 启动前端穿透...${NC}"
    echo -e "${YELLOW}访问地址将在下方显示 (类似 https://xxx.trycloudflare.com)${NC}"
    cloudflared tunnel --url http://localhost:3000
}

run_rpc() {
    echo -e "${BLUE}[*] 启动 RPC 穿透...${NC}"
    echo -e "${YELLOW}注意: 公开 RPC 有安全风险，建议添加认证${NC}"
    cloudflared tunnel --url http://localhost:8545
}

run_both() {
    echo -e "${BLUE}[*] 启动前端 + RPC 穿透...${NC}"
    echo -e "${YELLOW}此模式使用随机临时 URL${NC}"

    # 前端
    cloudflared tunnel --url http://localhost:3000 &
    FRONT_PID=$!

    # RPC
    cloudflared tunnel --url http://localhost:8545 &
    RPC_PID=$!

    echo "[+] 前端 PID: $FRONT_PID"
    echo "[+] RPC PID: $RPC_PID"
    echo "[*] 按 Enter 停止所有隧道..."
    read
    kill $FRONT_PID $RPC_PID 2>/dev/null
}

run_cpolar() {
    if ! command -v cpolar &> /dev/null; then
        echo -e "${RED}[!] cpolar 未安装${NC}"
        return
    fi

    read -p "输入 cpolar authtoken: " TOKEN
    if [ -n "$TOKEN" ]; then
        cpolar authtoken "$TOKEN"
    fi

    read -p "输入子域名 (默认 bal): " SUB
    SUB=${SUB:-bal}

    cpolar http 3000 --subdomain="$SUB"
}

stop_all() {
    echo -e "${YELLOW}[*] 停止所有隧道进程...${NC}"
    pkill -f cloudflared 2>/dev/null || true
    pkill -f cpolar 2>/dev/null || true
    echo -e "${GREEN}[+] 已停止${NC}"
    sleep 1
}

show_status() {
    echo -e "${BLUE}[*] 运行中的隧道:${NC}"
    ps aux | grep -E "cloudflared|cpolar" | grep -v grep || echo "无"
    echo ""
    echo -e "${BLUE}[*] 本地服务状态:${NC}"
    curl -s http://localhost:3000 -o /dev/null -w "前端 (3000): %{http_code}\n" 2>/dev/null || echo "前端 (3000): 未运行"
    curl -s http://localhost:8545 -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' -o /dev/null -w "RPC (8545): %{http_code}\n" 2>/dev/null || echo "RPC (8545): 未运行"
}

install_tools() {
    echo -e "${YELLOW}[*] 安装/更新工具...${NC}"
    pkg update -y
    pkg install -y wget curl unzip

    # cloudflared
    cd ~
    wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64
    chmod +x cloudflared-linux-arm64
    mv cloudflared-linux-arm64 $PREFIX/bin/cloudflared

    # cpolar
    rm -f $PREFIX/bin/cpolar 2>/dev/null
    wget -q "https://www.cpolar.com/static/downloads/cpolar-stable-linux-arm64.zip" -O cpolar.zip 2>/dev/null
    if [ -f cpolar.zip ]; then
        unzip -o cpolar.zip
        chmod +x cpolar
        mv cpolar $PREFIX/bin/
        rm -f cpolar.zip
    fi

    echo -e "${GREEN}[+] 完成${NC}"
}

# 主循环
while true; do
    show_menu
    read -p "选择操作 [0-7]: " CHOICE

    case $CHOICE in
        1) run_frontend ;;
        2) run_rpc ;;
        3) run_both ;;
        4) run_cpolar ;;
        5) stop_all ;;
        6) show_status; read -p "按 Enter 继续..." ;;
        7) install_tools ;;
        0) echo "[*] 退出"; exit 0 ;;
        *) echo -e "${RED}[!] 无效选择${NC}"; sleep 1 ;;
    esac
done
