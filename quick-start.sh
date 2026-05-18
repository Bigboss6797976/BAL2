#!/bin/bash
echo "🚀 快速启动 BAL2"

# 创建日志目录（Termux 有权限）
mkdir -p ~/BAL-logs

# 1. 启动 Hardhat 节点
echo "[1/4] 启动节点..."
nohup npx hardhat node > ~/BAL-logs/node.log 2>&1 &
NODE_PID=$!
echo "  PID: $NODE_PID"
sleep 6

# 2. 部署合约
echo "[2/4] 部署合约..."
nohup npx hardhat run scripts/deploy-all.js --network hardhat > ~/BAL-logs/deploy.log 2>&1 &
DEPLOY_PID=$!
echo "  PID: $DEPLOY_PID"
sleep 4

# 3. 启动签名服务
echo "[3/4] 启动签名服务..."
cd offline-signer
nohup node server.js > ~/BAL-logs/signer.log 2>&1 &
SIGNER_PID=$!
cd ..
echo "  PID: $SIGNER_PID"
sleep 3

# 4. 启动前端
echo "[4/4] 启动前端..."
nohup npm run dev > ~/BAL-logs/dev.log 2>&1 &
DEV_PID=$!
echo "  PID: $DEV_PID"

# 保存 PID
echo "$NODE_PID $DEPLOY_PID $SIGNER_PID $DEV_PID" > ~/BAL-logs/.pids

echo ""
echo "✅ 全部启动完成！"
echo "查看日志: tail -f ~/BAL-logs/*.log"
echo "停止服务: kill $NODE_PID $DEPLOY_PID $SIGNER_PID $DEV_PID"
