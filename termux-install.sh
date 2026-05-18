#!/bin/bash
# termux-install.sh
# 在 Termux 下完整安装区块链攻击实验室项目

set -e

echo "=========================================="
echo "🚀 区块链攻击实验室 - Termux 安装脚本"
echo "=========================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 检查是否在 Termux 环境
if [ -z "$TERMUX_VERSION" ] && [ ! -d "/data/data/com.termux" ]; then
    echo -e "${YELLOW}⚠️  未检测到 Termux 环境，继续安装...${NC}"
fi

# 更新包列表
echo -e "${GREEN}[1/8] 更新包列表...${NC}"
pkg update -y

# 安装必要依赖
echo -e "${GREEN}[2/8] 安装系统依赖...${NC}"
pkg install -y nodejs git python build-essential openssl

# 设置项目目录
PROJECT_DIR="${HOME}/BAL"

echo -e "${GREEN}[3/8] 准备项目目录...${NC}"
if [ -d "$PROJECT_DIR" ]; then
    echo -e "${YELLOW}检测到旧项目，备份并清理...${NC}"
    mv "$PROJECT_DIR" "${PROJECT_DIR}.backup.$(date +%s)"
fi

mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# 创建目录结构
echo -e "${GREEN}[4/8] 创建目录结构...${NC}"
mkdir -p contracts scripts src/components src/utils src/abis offline-signer public

# 写入 package.json
cat > package.json << 'EOF'
{
  "name": "blockchain-attack-lab",
  "version": "1.0.0",
  "description": "Blockchain Attack Lab - QR Transfer with Blind Signatures",
  "scripts": {
    "compile": "hardhat compile",
    "deploy": "hardhat run scripts/deploy-all.js --network hardhat",
    "deploy-sepolia": "hardhat run scripts/deploy-all.js --network sepolia",
    "test": "hardhat test",
    "node": "hardhat node",
    "signer": "cd offline-signer && node server.js",
    "dev": "react-scripts start"
  },
  "dependencies": {
    "ethers": "^6.9.0",
    "hardhat": "^2.19.0",
    "@nomicfoundation/hardhat-toolbox": "^4.0.0",
    "@nomicfoundation/hardhat-verify": "^2.0.0",
    "@openzeppelin/contracts": "^5.0.0",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-scripts": "^5.0.1",
    "react-qr-reader": "^3.0.0-beta-1",
    "typescript": "^5.3.0",
    "@types/react": "^18.2.0",
    "@types/react-dom": "^18.2.0",
    "axios": "^1.6.0"
  }
}
EOF

# 安装依赖
echo -e "${GREEN}[5/8] 安装 npm 依赖（可能需要几分钟）...${NC}"
npm install --legacy-peer-deps 2>&1 | tail -5

# 安装离线签名服务依赖
echo -e "${GREEN}[6/8] 安装离线签名服务依赖...${NC}"
cd offline-signer
npm install 2>&1 | tail -3
cd ..

# 创建 .env 模板
cat > .env.example << 'EOF'
# 私钥配置（仅用于测试！）
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# 离线签名服务私钥
SIGNER_KEY=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d

# API Keys（可选）
ETHERSCAN_API_KEY=your_etherscan_key
ALCHEMY_API_KEY=your_alchemy_key
EOF

echo -e "${GREEN}[7/8] 生成 ABI 文件...${NC}"
# ABI 文件将在编译后生成，这里先创建占位
mkdir -p artifacts/contracts/BlindQRTransfer.sol
touch artifacts/contracts/BlindQRTransfer.sol/BlindQRTransfer.json

echo -e "${GREEN}[8/8] 安装完成！${NC}"
echo ""
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}✅ 区块链攻击实验室安装成功！${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
echo "📁 项目目录: $PROJECT_DIR"
echo ""
echo "🚀 快速启动指南:"
echo ""
echo "1️⃣  启动 Hardhat 本地节点（窗口1）:"
echo "   cd $PROJECT_DIR && npx hardhat node"
echo ""
echo "2️⃣  编译并部署合约（窗口2）:"
echo "   cd $PROJECT_DIR && npx hardhat compile"
echo "   cd $PROJECT_DIR && npx hardhat run scripts/deploy-all.js --network hardhat"
echo ""
echo "3️⃣  启动离线签名服务（窗口3）:"
echo "   cd $PROJECT_DIR/offline-signer && SIGNER_KEY=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d node server.js"
echo ""
echo "4️⃣  启动前端开发服务器（窗口4）:"
echo "   cd $PROJECT_DIR && npm run dev"
echo ""
echo "⚠️  注意:"
echo "   - 确保 MetaMask 连接到 http://localhost:8545 (chainId: 31337)"
echo "   - 使用 Hardhat 测试账户私钥导入钱包"
echo "   - 离线签名服务应在隔离环境运行"
echo ""
echo "🔧 常用命令:"
echo "   npm run compile      - 编译合约"
echo "   npm run test         - 运行测试"
echo "   npm run deploy       - 部署到本地网络"
echo ""
