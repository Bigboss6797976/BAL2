#!/data/data/com.termux/files/usr/bin/bash
# ============================================
# BAL 项目 - Termux 内网穿透完整安装脚本
# 支持: cloudflared + cpolar (arm64)
# ============================================

set -e
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}[*] BAL Tunnel Installer${NC}"
echo "========================================"

# 检查 Termux 环境
if [ -z "$PREFIX" ]; then
    echo -e "${RED}[!] 请在 Termux 环境中运行${NC}"
    exit 1
fi

# 更新仓库
echo -e "${YELLOW}[1/6] 更新 Termux 仓库...${NC}"
pkg update -y

# 安装依赖
echo -e "${YELLOW}[2/6] 安装依赖...${NC}"
pkg install -y wget curl unzip nano nodejs-lts git python

# 安装 cloudflared
echo -e "${YELLOW}[3/6] 安装 cloudflared...${NC}"
if ! command -v cloudflared &> /dev/null; then
    cd ~
    wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64
    mv cloudflared-linux-arm64 cloudflared
    chmod +x cloudflared
    mv cloudflared $PREFIX/bin/
    echo -e "${GREEN}[+] cloudflared 安装完成${NC}"
else
    echo -e "${GREEN}[+] cloudflared 已存在${NC}"
fi

# 安装 cpolar arm64
echo -e "${YELLOW}[4/6] 安装 cpolar (arm64)...${NC}"
rm -f $PREFIX/bin/cpolar 2>/dev/null
cd ~
# 尝试下载 arm64 版本
wget -q "https://www.cpolar.com/static/downloads/cpolar-stable-linux-arm64.zip" -O cpolar-arm64.zip 2>/dev/null || true

if [ -f cpolar-arm64.zip ]; then
    unzip -o cpolar-arm64.zip >/dev/null 2>&1
    chmod +x cpolar
    mv cpolar $PREFIX/bin/
    rm -f cpolar-arm64.zip
    echo -e "${GREEN}[+] cpolar arm64 安装完成${NC}"
else
    echo -e "${YELLOW}[!] cpolar arm64 下载失败，将使用 cloudflared 作为主力${NC}"
fi

# 创建配置目录
echo -e "${YELLOW}[5/6] 创建配置...${NC}"
mkdir -p ~/.cloudflared

# 创建 cloudflared 配置模板
cat > ~/.cloudflared/config.yml.template << 'CONFIGEOF'
# Cloudflared 隧道配置 - BAL 项目
# 请替换 YOUR_TUNNEL_ID 为实际 ID

tunnel: YOUR_TUNNEL_ID
credentials-file: /data/data/com.termux/files/home/.cloudflared/YOUR_TUNNEL_ID.json

# 日志
logfile: /data/data/com.termux/files/home/.cloudflared/cloudflared.log
log-level: info
protocol: quic

# Ingress 规则
ingress:
  # BAL 前端
  - hostname: bal-YOURNAME.pages.dev
    service: http://localhost:3000
    originRequest:
      noTLSVerify: true

  # Hardhat RPC
  - hostname: rpc-bal-YOURNAME.pages.dev
    service: http://localhost:8545
    originRequest:
      noTLSVerify: true

  # 默认 404
  - service: http_status:404
CONFIGEOF

# 创建启动脚本
echo -e "${YELLOW}[6/6] 创建启动脚本...${NC}"

# 隧道管理脚本
cat > ~/start-tunnel.sh << 'TUNNELEOF'
#!/data/data/com.termux/files/usr/bin/bash
# BAL 隧道管理

MODE=${1:-all}
TUNNEL_NAME="bal2"

show_help() {
    echo "用法: start-tunnel.sh [命令]"
    echo ""
    echo "命令:"
    echo "  login      - 登录 Cloudflare"
    echo "  create     - 创建新隧道"
    echo "  run        - 运行隧道 (使用 config.yml)"
    echo "  frontend   - 快速穿透前端 (localhost:3000)"
    echo "  rpc        - 快速穿透 RPC (localhost:8545)"
    echo "  cpolar     - 使用 cpolar 穿透前端"
    echo "  status     - 查看状态"
    echo "  stop       - 停止所有隧道"
    echo "  logs       - 查看日志"
    echo ""
}

case $MODE in
    login)
        echo "[*] 登录 Cloudflare..."
        rm -f ~/.cloudflared/cert.pem 2>/dev/null
        cloudflared tunnel login
        ;;
    create)
        echo "[*] 创建隧道 bal2..."
        cloudflared tunnel create bal2
        echo "[*] 请复制上面的 Tunnel ID，然后编辑 ~/.cloudflared/config.yml"
        ;;
    run)
        echo "[*] 启动完整配置模式..."
        if [ ! -f ~/.cloudflared/config.yml ]; then
            echo "[!] 请先复制模板并编辑: cp ~/.cloudflared/config.yml.template ~/.cloudflared/config.yml"
            exit 1
        fi
        cloudflared tunnel --config ~/.cloudflared/config.yml run bal2
        ;;
    frontend)
        echo "[*] 快速穿透前端 localhost:3000..."
        cloudflared tunnel --url http://localhost:3000 run
        ;;
    rpc)
        echo "[*] 快速穿透 RPC localhost:8545..."
        cloudflared tunnel --url http://localhost:8545 run
        ;;
    cpolar)
        echo "[*] 使用 cpolar 穿透..."
        read -p "输入 authtoken: " TOKEN
        cpolar authtoken "$TOKEN"
        read -p "输入子域名前缀 (默认 bal): " SUB
        SUB=${SUB:-bal}
        cpolar http 3000 --subdomain="$SUB"
        ;;
    status)
        echo "[*] 隧道状态:"
        ps aux | grep -E "cloudflared|cpolar" | grep -v grep || echo "无运行中的隧道"
        ;;
    stop)
        echo "[*] 停止所有隧道..."
        pkill -f cloudflared 2>/dev/null || true
        pkill -f cpolar 2>/dev/null || true
        echo "[+] 已停止"
        ;;
    logs)
        tail -f ~/.cloudflared/cloudflared.log 2>/dev/null || echo "无日志文件"
        ;;
    *)
        show_help
        ;;
esac
TUNNELEOF

chmod +x ~/start-tunnel.sh

# BAL 一键启动脚本
cat > ~/start-bal.sh << 'BALEOF'
#!/data/data/com.termux/files/usr/bin/bash
# BAL 区块链攻击实验室 - 一键启动

cd ~/BAL 2>/dev/null || { echo "[!] BAL 目录不存在于 ~/BAL"; exit 1; }

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}     BAL 攻击实验室启动器${NC}"
echo -e "${GREEN}========================================${NC}"

# 检查依赖
echo -e "${YELLOW}[1/5] 检查依赖...${NC}"
command -v npx >/dev/null 2>&1 || { echo -e "${RED}[!] 未找到 npx，请先运行 npm install${NC}"; exit 1; }

# 清理旧进程
echo -e "${YELLOW}[2/5] 清理旧进程...${NC}"
pkill -f "hardhat node" 2>/dev/null || true
pkill -f "next dev" 2>/dev/null || true
sleep 1

# 启动 Hardhat 节点
echo -e "${YELLOW}[3/5] 启动 Hardhat 本地节点...${NC}"
nohup npx hardhat node > ~/hardhat.log 2>&1 &
HARDHAT_PID=$!
echo "[+] Hardhat PID: $HARDHAT_PID"
sleep 4

# 检查节点是否启动
if ! curl -s http://localhost:8545 -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' >/dev/null 2>&1; then
    echo -e "${YELLOW}[!] 节点启动较慢，继续等待...${NC}"
    sleep 3
fi

# 部署合约
echo -e "${YELLOW}[4/5] 部署攻击合约...${NC}"
npx hardhat run scripts/deploy.js --network localhost > ~/deploy.log 2>&1 &
sleep 2

# 启动前端
echo -e "${YELLOW}[5/5] 启动 Next.js 前端...${NC}"
cd frontend 2>/dev/null || cd src/frontend 2>/dev/null || { echo "[!] 未找到前端目录"; exit 1; }
nohup npm run dev > ~/frontend.log 2>&1 &
FRONTEND_PID=$!
echo "[+] 前端 PID: $FRONTEND_PID"
sleep 3

# 显示状态
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  ✓ BAL 已启动!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "  本地前端: http://localhost:3000"
echo -e "  本地 RPC: http://localhost:8545"
echo ""
echo -e "${YELLOW}  启动内网穿透:${NC}"
echo -e "  cloudflared: ~/start-tunnel.sh frontend"
echo -e "  cpolar:      ~/start-tunnel.sh cpolar"
echo ""
echo -e "  日志文件:"
echo -e "  ~/hardhat.log"
echo -e "  ~/deploy.log"
echo -e "  ~/frontend.log"
echo -e "${GREEN}========================================${NC}"

# 等待用户输入
read -p "是否立即启动内网穿透? (y/n): " START_TUNNEL
if [ "$START_TUNNEL" = "y" ] || [ "$START_TUNNEL" = "Y" ]; then
    ~/start-tunnel.sh frontend
fi
BALEOF

chmod +x ~/start-bal.sh

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  ✓ 安装完成!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "使用步骤:"
echo "1. 登录 Cloudflare: ~/start-tunnel.sh login"
echo "2. 创建隧道:       ~/start-tunnel.sh create"
echo "3. 编辑配置:       nano ~/.cloudflared/config.yml"
echo "4. 启动 BAL:       ~/start-bal.sh"
echo ""
echo "快速穿透 (无需配置):"
echo "  ~/start-tunnel.sh frontend  # 穿透 localhost:3000"
echo "  ~/start-tunnel.sh rpc       # 穿透 localhost:8545"
echo ""
