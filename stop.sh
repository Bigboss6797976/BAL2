#!/bin/bash
echo "🛑 停止服务..."
if [ -f ~/BAL-logs/.pids ]; then
    kill $(cat ~/BAL-logs/.pids) 2>/dev/null || true
    rm ~/BAL-logs/.pids
fi
pkill -f "hardhat node" 2>/dev/null || true
pkill -f "node server.js" 2>/dev/null || true
pkill -f "react-scripts" 2>/dev/null || true
echo "✅ 已停止"
