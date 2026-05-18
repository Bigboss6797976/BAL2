#!/bin/bash
cd /storage/emulated/0/Download/BAL

# 停止旧进程
pkill -f "hardhat|node server|react-scripts" 2>/dev/null || true
sleep 2

# 安装核心依赖
npm install --legacy-peer-deps hardhat react-scripts 2>&1 | tail -5

# 启动服务
echo "🚀 启动服务..."

nohup npx hardhat node > /tmp/node.log 2>&1 &
sleep 8

nohup npx hardhat run scripts/deploy-all.js --network hardhat > /tmp/deploy.log 2>&1 &
sleep 5

cd offline-signer
nohup PORT=3002 node server.js > /tmp/signer.log 2>&1 &
cd ..

sleep 3
nohup npx react-scripts start > /tmp/dev.log 2>&1 &

echo "✅ 服务已启动"
echo "查看日志: tail -f /tmp/deploy.log /tmp/signer.log /tmp/dev.log"
