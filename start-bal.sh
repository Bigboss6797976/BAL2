#!/data/data/com.termux/files/usr/bin/bash
# ============================================
# BAL 区块链攻击实验室 - 一键启动器
# ============================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BAL_DIR="${1:-~/BAL}"
cd "$BAL_DIR" 2>/dev/null || { 
    echo -e "${RED}[!] 未找到 BAL 目录: $BAL_DIR${NC}"
    echo "用法: $0 [BAL目录路径]"
    exit 1
}

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}     BAL 攻击实验室启动器${NC}"
echo -e "${GREEN}========================================${NC}"

# 检查 Node 环境
if ! command -v node &> /dev/null; then
    echo -e "${YELLOW}[!] Node.js 未安装，尝试安装...${NC}"
    pkg install -y nodejs-lts
fi

# 检查 hardhat
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}[!] 未找到 node_modules，运行 npm install...${NC}"
    npm install
fi

# 清理旧进程
echo -e "${YELLOW}[*] 清理旧进程...${NC}"
pkill -f "hardhat node" 2>/dev/null || true
pkill -f "next dev" 2>/dev/null || true
sleep 1

# 启动 Hardhat 节点
echo -e "${BLUE}[1/4] 启动 Hardhat 本地节点...${NC}"
nohup npx hardhat node > ~/hardhat.log 2>&1 &
HARDHAT_PID=$!
echo -e "${GREEN}[+] Hardhat PID: $HARDHAT_PID${NC}"

# 等待节点就绪
echo -e "${YELLOW}[*] 等待节点启动 (约 5 秒)...${NC}"
for i in {1..10}; do
    sleep 1
    if curl -s http://localhost:8545 -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' >/dev/null 2>&1; then
        echo -e "${GREEN}[+] 节点已就绪${NC}"
        break
    fi
    echo -n "."
done
echo ""

# 部署合约
echo -e "${BLUE}[2/4] 部署攻击合约...${NC}"
if [ -f "scripts/deploy.js" ]; then
    npx hardhat run scripts/deploy.js --network localhost > ~/deploy.log 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[+] 合约部署完成${NC}"
    else
        echo -e "${RED}[!] 合约部署失败，查看 ~/deploy.log${NC}"
    fi
else
    echo -e "${YELLOW}[!] 未找到 scripts/deploy.js，跳过部署${NC}"
fi

# 启动前端
echo -e "${BLUE}[3/4] 启动前端服务...${NC}"
FRONTEND_DIR=""
for dir in frontend src/frontend web app; do
    [ -d "$dir" ] && FRONTEND_DIR="$dir" && break
done

if [ -n "$FRONTEND_DIR" ]; then
    cd "$FRONTEND_DIR"
    nohup npm run dev > ~/frontend.log 2>&1 &
    FRONTEND_PID=$!
    echo -e "${GREEN}[+] 前端 PID: $FRONTEND_PID${NC}"
    cd ..
else
    echo -e "${RED}[!] 未找到前端目录${NC}"
fi

# 等待前端启动
sleep 3

# 显示状态
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  ✓ BAL 启动完成!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}本地访问地址:${NC}"
echo -e "  前端: ${YELLOW}http://localhost:3000${NC}"
echo -e "  RPC:  ${YELLOW}http://localhost:8545${NC}"
echo ""
echo -e "${BLUE}内网穿透选项:${NC}"
echo -e "  1. Cloudflared 临时: ${YELLOW}cloudflared tunnel --url http://localhost:3000${NC}"
echo -e "  2. 使用 quick-tunnel: ${YELLOW}~/quick-tunnel.sh${NC}"
echo -e "  3. Cpolar:            ${YELLOW}cpolar http 3000${NC}"
echo ""
echo -e "${BLUE}日志文件:${NC}"
echo -e "  ~/hardhat.log"
echo -e "  ~/deploy.log"  
echo -e "  ~/frontend.log"
echo -e "${GREEN}========================================${NC}"

# 自动检测并提示穿透
if command -v cloudflared &> /dev/null; then
    read -p "是否启动 cloudflared 穿透? (y/n): " ANSWER
    if [ "$ANSWER" = "y" ] || [ "$ANSWER" = "Y" ]; then
        echo -e "${YELLOW}[*] 启动穿透...${NC}"
        cloudflared tunnel --url http://localhost:3000
    fi
fi
