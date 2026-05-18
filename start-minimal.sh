#!/bin/bash
echo "🚀 BAL2 最小化启动"

# 使用 Ganache 作为节点（已运行）
echo "✅ Ganache 节点: http://127.0.0.1:8545"

# 启动离线签名服务
cd offline-signer
node server.js &
cd ..

# 启动前端（使用 mock 模式）
echo "启动前端..."
node -e "
const http = require('http');
const fs = require('fs');
const path = require('path');

const server = http.createServer((req, res) => {
    let filePath = '.' + req.url;
    if (filePath === './') filePath = './public/index.html';
    
    const extname = path.extname(filePath);
    const contentTypes = {
        '.html': 'text/html',
        '.js': 'text/javascript',
        '.css': 'text/css',
        '.json': 'application/json'
    };
    
    const contentType = contentTypes[extname] || 'application/octet-stream';
    
    fs.readFile(filePath, (err, content) => {
        if (err) {
            res.writeHead(404);
            res.end('File not found');
        } else {
            res.writeHead(200, { 'Content-Type': contentType });
            res.end(content, 'utf-8');
        }
    });
});

server.listen(3000, '0.0.0.0');
console.log('Server running at http://0.0.0.0:3000/');
"
