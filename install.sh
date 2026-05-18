#!/bin/bash
set -e
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
echo -e "${GREEN}🚀 BAL2 - 区块链攻击实验室 安装${NC}"
if ! command -v node &> /dev/null; then
    echo -e "${YELLOW}未检测到 Node.js${NC}"
    if [ -n "$TERMUX_VERSION" ]; then
        pkg update -y && pkg install -y nodejs git python build-essential
    else
        echo "请安装 Node.js 18+"
        exit 1
    fi
fi
echo -e "${GREEN}[1/4] 安装依赖...${NC}"
npm install --legacy-peer-deps 2>&1 | tail -5
echo -e "${GREEN}[2/4] 安装签名服务...${NC}"
cd offline-signer && npm install 2>&1 | tail -3 && cd ..
echo -e "${GREEN}[3/4] 编译合约...${NC}"
npx hardhat compile
echo -e "${GREEN}[4/4] 运行测试...${NC}"
npx hardhat test || true
echo -e "${GREEN}✅ 安装完成！${NC}"
echo "启动: bash start.sh"
