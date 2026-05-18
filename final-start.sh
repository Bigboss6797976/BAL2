#!/bin/bash
echo "🚀 BAL2 启动"
cd /storage/emulated/0/Download/BAL
mkdir -p ~/BAL-logs

# 检查依赖
ls node_modules/hardhat 2>/dev/null && echo "✅ hardhat 已安装" || npm install --no-save hardhat
ls node_modules/react-scripts 2>/dev/null && echo "✅ react-scripts 已安装" || npm install --no-save react-scripts

# 启动
nohup npx hardhat node > ~/BAL-logs/node.log 2>&1 &
sleep 10
nohup npx hardhat run scripts/deploy-all.js --network hardhat > ~/BAL-logs/deploy.log 2>&1 &
sleep 8
cd offline-signer && nohup node server.js > ~/BAL-logs/signer.log 2>&1 & && cd ..
sleep 5
nohup npx react-scripts start > ~/BAL-logs/dev.log 2>&1 &

echo "✅ 启动完成"
echo "日志: tail -f ~/BAL-logs/*.log"
