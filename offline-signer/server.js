const express = require('express');
const { ethers } = require('ethers');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

// ⚠️ 攻击实验室：硬编码测试私钥（Anvil/Hardhat 测试账户 #1）
const PRIVATE_KEY = process.env.SIGNER_KEY || "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d";
const wallet = new ethers.Wallet(PRIVATE_KEY);

console.log("🔒 Offline Signer Service");
console.log("Signer Address:", wallet.address);
console.log("⚠️  WARNING: Keep this server in an isolated environment!");

// 健康检查
app.get('/', (req, res) => {
    res.json({ 
        status: "alive", 
        signer: wallet.address,
        timestamp: new Date().toISOString()
    });
});

// ========== 离线签名（EIP-712） ==========
app.post('/sign-transfer', async (req, res) => {
    try {
        const { token, to, amount, nonce, deadline, chainId, verifyingContract } = req.body;

        const domain = {
            name: "BlindQRTransfer",
            version: "1",
            chainId: Number(chainId),
            verifyingContract
        };

        const types = {
            Transfer: [
                { name: "token", type: "address" },
                { name: "to", type: "address" },
                { name: "amount", type: "uint256" },
                { name: "nonce", type: "uint256" },
                { name: "deadline", type: "uint256" }
            ]
        };

        const value = { token, to, amount, nonce, deadline };

        const signature = await wallet.signTypedData(domain, types, value);

        res.json({
            signature,
            signer: wallet.address,
            message: value,
            domain
        });
    } catch (error) {
        console.error("Sign transfer error:", error);
        res.status(500).json({ error: error.message });
    }
});

// ========== 盲签接口 ==========
app.post('/sign-blind', async (req, res) => {
    try {
        const { blindHash } = req.body;

        // 直接对盲化哈希签名（签名者不知道真实内容）
        const signature = await wallet.signMessage(ethers.getBytes(blindHash));

        res.json({
            blindSignature: signature,
            signer: wallet.address,
            note: "Signer does not know the actual transaction content"
        });
    } catch (error) {
        console.error("Blind sign error:", error);
        res.status(500).json({ error: error.message });
    }
});

// ========== 批量盲签 ==========
app.post('/sign-batch-blind', async (req, res) => {
    try {
        const { blindHashes } = req.body;

        const signatures = await Promise.all(
            blindHashes.map(hash => 
                wallet.signMessage(ethers.getBytes(hash))
            )
        );

        res.json({ 
            signatures, 
            signer: wallet.address,
            count: signatures.length
        });
    } catch (error) {
        console.error("Batch blind sign error:", error);
        res.status(500).json({ error: error.message });
    }
});

// ========== 获取签名者信息 ==========
app.get('/signer-info', (req, res) => {
    res.json({
        address: wallet.address,
        publicKey: wallet.signingKey.publicKey,
        note: "This is the offline signer's public information"
    });
});

const PORT = process.env.PORT || 3001;
const HOST = process.env.HOST || '0.0.0.0';

app.listen(PORT, HOST, () => {
    console.log(`🚀 Server running on http://${HOST}:${PORT}`);
    console.log(`📡 Endpoints:`);
    console.log(`   GET  /           - Health check`);
    console.log(`   GET  /signer-info - Signer public info`);
    console.log(`   POST /sign-transfer - EIP-712 offline signing`);
    console.log(`   POST /sign-blind    - Blind signing`);
    console.log(`   POST /sign-batch-blind - Batch blind signing`);
});
