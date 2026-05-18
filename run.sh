#!/bin/bash
echo "🚀 BAL2 启动"
cd /storage/emulated/0/Download/BAL
export PATH="$PATH:/storage/emulated/0/Download/BAL/node_modules/.bin"

# 自动安装缺失依赖
[ ! -f "node_modules/.bin/hardhat" ] && npm install --legacy-peer-deps hardhat @nomicfoundation/hardhat-toolbox
[ ! -d "node_modules/react-scripts" ] && npm install --legacy-peer-deps react-scripts react react-dom
[ ! -f "offline-signer/node_modules/express/package.json" ] && (cd offline-signer && npm install express cors mime)

# 停止旧进程
pkill -f "hardhat node" 2>/dev/null || true
pkill -f "node server.js" 2>/dev/null || true
pkill -f "react-scripts" 2>/dev/null || true
sleep 2

# 启动4个服务
mkdir -p ~/BAL-logs
echo "[1/4] 节点..." && nohup npx hardhat node > ~/BAL-logs/node.log 2>&1 & sleep 8
echo "[2/4] 部署..." && nohup npx hardhat run scripts/deploy-all.js --network hardhat > ~/BAL-logs/deploy.log 2>&1 & sleep 6
echo "[3/4] 签名..." && cd offline-signer && nohup node server.js > ~/BAL-logs/signer.log 2>&1 & cd .. && sleep 4
echo "[4/4] 前端..." && nohup npx react-scripts start > ~/BAL-logs/dev.log 2>&1 &

echo "✅ 启动完成！"
echo "查看日志: tail -f ~/BAL-logs/*.log"
