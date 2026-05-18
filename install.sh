#!/bin/bash
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}"
echo "=========================================="
echo "🚀 BAL2 - 区块链攻击实验室"
echo "GitHub: https://github.com/Bigboss6797976/BAL2"
echo "=========================================="
echo -e "${NC}"

# 检测环境
if [ -n "$TERMUX_VERSION" ] || [ -d "/data/data/com.termux" ]; then
    ENV="termux"
    echo -e "${BLUE}📱 检测到 Termux 环境${NC}"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    ENV="linux"
    echo -e "${BLUE}🐧 检测到 Linux 环境${NC}"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    ENV="macos"
    echo -e "${BLUE}🍎 检测到 macOS 环境${NC}"
else
    ENV="unknown"
    echo -e "${YELLOW}⚠️ 未知环境，尝试继续...${NC}"
fi

# 检查 Node.js
if ! command -v node &> /dev/null; then
    echo -e "${YELLOW}未检测到 Node.js${NC}"
    if [ "$ENV" = "termux" ]; then
        echo -e "${GREEN}正在安装 Node.js...${NC}"
        pkg update -y
        pkg install -y nodejs git python build-essential
    else
        echo "请手动安装 Node.js 18+: https://nodejs.org"
        exit 1
    fi
fi

NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    echo -e "${RED}❌ Node.js 版本过低，需要 18+${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Node.js 版本: $(node -v)${NC}"

# 安装依赖
echo -e "${GREEN}[1/5] 安装主项目依赖...${NC}"
npm install --legacy-peer-deps 2>&1 | tail -10

echo -e "${GREEN}[2/5] 安装离线签名服务依赖...${NC}"
cd offline-signer
npm install 2>&1 | tail -5
cd ..

echo -e "${GREEN}[3/5] 编译智能合约...${NC}"
npx hardhat compile

echo -e "${GREEN}[4/5] 运行测试...${NC}"
npx hardhat test || echo -e "${YELLOW}⚠️ 测试失败，继续安装...${NC}"

echo -e "${GREEN}[5/5] 构建前端...${NC}"
npm run build || echo -e "${YELLOW}⚠️ 构建失败，开发模式可用${NC}"

echo ""
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}✅ BAL2 安装完成！${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
echo -e "${BLUE}🚀 启动方式:${NC}"
echo ""
echo "方式1 - 手动启动（推荐，开4个窗口）:"
echo "  窗口1: npx hardhat node"
echo "  窗口2: npx hardhat run scripts/deploy-all.js --network hardhat"
echo "  窗口3: cd offline-signer && SIGNER_KEY=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d node server.js"
echo "  窗口4: npm run dev"
echo ""
echo "方式2 - 一键启动（需要 tmux/screen）:"
echo "  bash start.sh"
echo ""
echo "方式3 - 仅前端（连接已有节点）:"
echo "  npm run dev"
echo ""
echo -e "${YELLOW}⚠️ 安全提示:${NC}"
echo "  - 离线签名服务应在隔离环境运行"
echo "  - 生产环境请修改默认私钥"
echo "  - 仅用于安全研究目的"
echo ""
