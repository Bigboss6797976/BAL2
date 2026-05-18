#!/bin/bash
set -e
GREEN='\033[0;32m'
NC='\033[0m'
echo -e "${GREEN}🚀 启动 BAL2...${NC}"
if command -v tmux &> /dev/null; then
    tmux new-session -d -s bal2 -n 'node'
    tmux send-keys -t bal2:0 'npx hardhat node' C-m
    tmux new-window -t bal2 -n 'deploy'
    tmux send-keys -t bal2:1 'sleep 5 && npx hardhat run scripts/deploy-all.js --network hardhat' C-m
    tmux new-window -t bal2 -n 'signer'
    tmux send-keys -t bal2:2 'sleep 8 && cd offline-signer && SIGNER_KEY=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d node server.js' C-m
    tmux new-window -t bal2 -n 'frontend'
    tmux send-keys -t bal2:3 'sleep 10 && npm run dev' C-m
    tmux attach -t bal2
else
    echo "未检测到 tmux，手动启动4个窗口:"
    echo "窗口1: npx hardhat node"
    echo "窗口2: npx hardhat run scripts/deploy-all.js --network hardhat"
    echo "窗口3: cd offline-signer && SIGNER_KEY=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d node server.js"
    echo "窗口4: npm run dev"
fi
