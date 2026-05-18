#!/bin/bash
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🚀 BAL2 - 启动所有服务${NC}"

# 检查 tmux
if command -v tmux &> /dev/null; then
    echo -e "${YELLOW}使用 tmux 启动...${NC}"
    
    # 如果已有会话，先杀掉
    tmux kill-session -t bal2 2>/dev/null || true
    
    tmux new-session -d -s bal2 -n 'hardhat-node'
    tmux send-keys -t bal2:0 'echo "启动 Hardhat 节点..." && npx hardhat node' C-m
    
    tmux new-window -t bal2 -n 'deploy'
    tmux send-keys -t bal2:1 'sleep 5 && echo "部署合约..." && npx hardhat run scripts/deploy-all.js --network hardhat' C-m
    
    tmux new-window -t bal2 -n 'signer'
    tmux send-keys -t bal2:2 'sleep 8 && echo "启动离线签名服务..." && cd offline-signer && SIGNER_KEY=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d node server.js' C-m
    
    tmux new-window -t bal2 -n 'frontend'
    tmux send-keys -t bal2:3 'sleep 10 && echo "启动前端..." && npm run dev' C-m
    
    echo -e "${GREEN}✅ 所有服务已在 tmux 会话中启动${NC}"
    echo ""
    echo "tmux 命令:"
    echo "  查看所有窗口: tmux ls"
    echo "  连接会话: tmux attach -t bal2"
    echo "  切换窗口: Ctrl+B 然后按数字 0-3"
    echo "  分离会话: Ctrl+B 然后按 D"
    echo ""
    echo -e "${YELLOW}是否现在连接 tmux 会话? (y/n)${NC}"
    read -r answer
    if [ "$answer" = "y" ]; then
        tmux attach -t bal2
    fi
    
elif command -v screen &> /dev/null; then
    echo -e "${YELLOW}使用 screen 启动...${NC}"
    
    screen -dmS bal2-node bash -c 'npx hardhat node; exec bash'
    screen -dmS bal2-deploy bash -c 'sleep 5 && npx hardhat run scripts/deploy-all.js --network hardhat; exec bash'
    screen -dmS bal2-signer bash -c 'sleep 8 && cd offline-signer && SIGNER_KEY=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d node server.js; exec bash'
    screen -dmS bal2-frontend bash -c 'sleep 10 && npm run dev; exec bash'
    
    echo -e "${GREEN}✅ 所有服务已在 screen 会话中启动${NC}"
    echo "查看会话: screen -ls"
    echo "连接节点: screen -r bal2-node"
    
else
    echo -e "${YELLOW}未检测到 tmux/screen，使用后台进程启动...${NC}"
    
    # 日志目录
    mkdir -p logs
    
    npx hardhat node > logs/node.log 2>&1 &
    NODE_PID=$!
    echo "Hardhat Node PID: $NODE_PID"
    
    sleep 5
    npx hardhat run scripts/deploy-all.js --network hardhat > logs/deploy.log 2>&1 &
    DEPLOY_PID=$!
    echo "Deploy PID: $DEPLOY_PID"
    
    sleep 3
    cd offline-signer
    SIGNER_KEY=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d node server.js > ../logs/signer.log 2>&1 &
    SIGNER_PID=$!
    cd ..
    echo "Signer PID: $SIGNER_PID"
    
    sleep 2
    npm run dev > logs/frontend.log 2>&1 &
    DEV_PID=$!
    echo "Frontend PID: $DEV_PID"
    
    echo ""
    echo -e "${GREEN}✅ 所有服务已后台启动${NC}"
    echo ""
    echo "日志文件:"
    echo "  节点: logs/node.log"
    echo "  部署: logs/deploy.log"
    echo "  签名: logs/signer.log"
    echo "  前端: logs/frontend.log"
    echo ""
    echo "查看日志: tail -f logs/*.log"
    echo "停止所有: kill $NODE_PID $DEPLOY_PID $SIGNER_PID $DEV_PID"
    echo ""
    
    # 保存 PID
    echo "$NODE_PID $DEPLOY_PID $SIGNER_PID $DEV_PID" > .pids
fi
