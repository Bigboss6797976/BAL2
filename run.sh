#!/bin/bash
set -e

# 切换到项目目录
cd /storage/emulated/0/Download/BAL || exit

echo "📦 安装依赖..."
pnpm install --shamefully-hoist

echo "🔨 编译合约..."
npx hardhat compile

echo "🧪 运行测试..."
npx hardhat test

echo "⚡ 启动本地区块链节点 (后台运行)..."
nohup npx hardhat node > hardhat-node.log 2>&1 &

sleep 5  # 等待节点启动

echo "🚀 部署合约到本地节点..."
npx hardhat run scripts/deploy-all.js --network localhost

echo "🌐 启动前端应用..."
pnpm start