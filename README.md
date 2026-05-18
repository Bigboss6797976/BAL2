# 🕵️ 区块链攻击实验室 (Blockchain Attack Lab)

> ⚠️ **警告**: 本项目仅用于安全研究和教育目的，请勿用于非法活动。

## 功能特性

### 🔍 扫码转账
- 支持多种 QR 码格式（纯地址、EIP-681、JSON）
- 自动解析收款地址和金额
- 实时查询 USDT 余额和授权额度

### 🔒 离线签名
- 私钥保存在隔离服务器，不触网
- 通过 API 请求 EIP-712 结构化签名
- 前端提交签名到链上执行

### 🕶️ 盲签攻击测试
- 盲化交易内容，隐藏真实转账信息
- 签名者无法知道实际签名内容
- **攻击面**: 用户无法验证实际交易金额和地址

### 💣 批量盲签攻击
- 一次请求多笔隐藏交易的签名
- 批量提交执行
- **攻击面**: 用户可能不知情地授权多笔转账

## 项目结构

```
~/BAL/
├── contracts/
│   ├── BlindQRTransfer.sol    # 盲签合约（离线签名 + 盲签 + 批量盲签）
│   ├── QRTransfer.sol          # 基础扫码合约
│   └── USDTMock.sol            # 测试用 USDT
├── offline-signer/
│   ├── server.js               # 隔离签名服务
│   └── package.json
├── scripts/
│   └── deploy-all.js           # 一键部署脚本
├── src/
│   ├── components/
│   │   ├── AdvancedQRTransfer.tsx  # 主界面
│   │   └── AdvancedQRTransfer.css   # 样式
│   ├── utils/
│   │   ├── qr-parser.ts        # QR 码解析
│   │   ├── blind-signature.ts  # 盲签工具
│   │   └── constants.ts        # 合约地址（自动生成）
│   ├── App.tsx
│   └── index.tsx
├── hardhat.config.js
├── package.json
└── termux-install.sh           # Termux 一键安装
```

## 快速开始

### Termux 安装

```bash
# 下载并运行安装脚本
curl -sL https://raw.githubusercontent.com/your-repo/termux-install.sh | bash

# 或手动执行
bash termux-install.sh
```

### 手动安装

```bash
# 1. 安装依赖
npm install

# 2. 编译合约
npx hardhat compile

# 3. 启动本地节点（窗口1）
npx hardhat node

# 4. 部署合约（窗口2）
npx hardhat run scripts/deploy-all.js --network hardhat

# 5. 启动离线签名服务（窗口3）
cd offline-signer
SIGNER_KEY=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d node server.js

# 6. 启动前端（窗口4）
npm run dev
```

## 四种转账模式

| 模式 | 私钥位置 | 用户可见性 | 安全风险 |
|------|----------|-----------|----------|
| **普通转账** | MetaMask | 完全可见 | 标准流程 |
| **离线签名** | 隔离服务器 | 完全可见 | API 可能被劫持 |
| **盲签** | 隔离服务器 | **完全不可见** | 用户无法验证交易内容 |
| **批量盲签** | 隔离服务器 | **完全不可见** | 多笔隐藏交易同时执行 |

## 攻击测试场景

### 场景1: 盲签金额篡改
```
前端显示: 转账 1 USDT 给 Alice
实际盲签: 转账 1000 USDT 给 Attacker
结果: 用户损失 1000 USDT
```

### 场景2: 批量盲签钓鱼
```
用户以为只签1笔，实际签了3笔:
- 100 USDT 给 Attacker_1
- 200 USDT 给 Attacker_2  
- 300 USDT 给 Attacker_3
```

## 安全建议

1. **永远不要盲签**你不完全理解的交易
2. **验证**离线签名服务的身份和代码
3. **检查**批量操作中的每一笔交易
4. **使用硬件钱包**进行关键操作

## 技术栈

- **合约**: Solidity 0.8.19 + OpenZeppelin
- **前端**: React 18 + TypeScript + Ethers.js v6
- **后端**: Node.js + Express + Ethers.js
- **测试**: Hardhat + Anvil

## License

MIT - 仅用于教育和安全研究目的。
