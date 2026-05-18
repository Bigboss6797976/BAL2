import React, { useState, useCallback, useEffect } from 'react';
import { ethers } from 'ethers';
import { QrReader } from 'react-qr-reader';
import { parseQR, QRPayload } from '../utils/qr-parser';
import { BlindSignatureTool } from '../utils/blind-signature';
import { CONTRACTS, OFFLINE_SIGNER_URL } from '../utils/constants';
import './AdvancedQRTransfer.css';

const ABI = [
    "function executeOfflineTransfer(address _token, address _to, uint256 _amount, uint256 _nonce, uint256 _deadline, bytes _signature) returns (bool)",
    "function executeBlindTransfer(bytes32 _blindHash, bytes _signature, address _token, address _to, uint256 _amount) returns (bool)",
    "function batchBlindTransfer(bytes32[] _blindHashes, bytes[] _signatures, address[] _tokens, address[] _tos, uint256[] _amounts)",
    "function getNonce(address _user) view returns (uint256)",
    "function usedBlindSignatures(bytes32) view returns (bool)",
    "function userNonces(address) view returns (uint256)"
];

const USDT_ABI = [
    "function balanceOf(address) view returns (uint256)",
    "function approve(address, uint256) returns (bool)",
    "function allowance(address, address) view returns (uint256)",
    "function transfer(address, uint256) returns (bool)",
    "function decimals() view returns (uint8)"
];

type Mode = 'normal' | 'offline' | 'blind' | 'batch-blind';

export const AdvancedQRTransfer: React.FC = () => {
    const [provider, setProvider] = useState<ethers.BrowserProvider | null>(null);
    const [signer, setSigner] = useState<ethers.JsonRpcSigner | null>(null);
    const [contract, setContract] = useState<ethers.Contract | null>(null);
    const [scanResult, setScanResult] = useState<QRPayload | null>(null);
    const [balance, setBalance] = useState("0");
    const [allowance, setAllowance] = useState("0");
    const [mode, setMode] = useState<Mode>('normal');
    const [loading, setLoading] = useState(false);
    const [txHash, setTxHash] = useState("");
    const [error, setError] = useState("");
    const [logs, setLogs] = useState<string[]>([]);

    const addLog = (msg: string) => setLogs(prev => [...prev, `[${new Date().toLocaleTimeString()}] ${msg}`]);

    const connectWallet = async () => {
        if (!window.ethereum) {
            setError("请安装 MetaMask");
            return;
        }
        try {
            const provider = new ethers.BrowserProvider(window.ethereum);
            const signer = await provider.getSigner();
            const contract = new ethers.Contract(CONTRACTS.BlindQRTransfer, ABI, signer);

            setProvider(provider);
            setSigner(signer);
            setContract(contract);

            await updateBalance(signer);
            addLog("钱包已连接");
        } catch (err: any) {
            setError(err.message);
        }
    };

    const updateBalance = async (s: ethers.JsonRpcSigner) => {
        const addr = await s.getAddress();
        const usdt = new ethers.Contract(CONTRACTS.USDT, USDT_ABI, provider!);
        const [bal, allow] = await Promise.all([
            usdt.balanceOf(addr),
            usdt.allowance(addr, CONTRACTS.BlindQRTransfer)
        ]);
        setBalance(ethers.formatUnits(bal, 6));
        setAllowance(ethers.formatUnits(allow, 6));
    };

    const handleScan = useCallback((result: string | null) => {
        if (!result) return;
        try {
            const parsed = parseQR(result);
            setScanResult(parsed);
            setError("");
            addLog(`扫描成功: ${parsed.address.slice(0, 20)}...`);
        } catch (err: any) {
            setError(err.message);
        }
    }, []);

    const handleNormal = async () => {
        if (!signer || !scanResult?.amount) return;
        setLoading(true);
        try {
            const usdt = new ethers.Contract(CONTRACTS.USDT, USDT_ABI, signer);
            const amount = ethers.parseUnits(scanResult.amount, 6);

            addLog("执行普通转账...");
            const tx = await usdt.transfer(scanResult.address, amount);
            await tx.wait();

            setTxHash(tx.hash);
            addLog(`✅ 成功: ${tx.hash.slice(0, 20)}...`);
            await updateBalance(signer);
        } catch (err: any) {
            setError(err.message);
            addLog(`❌ 失败: ${err.message}`);
        }
        setLoading(false);
    };

    const handleOffline = async () => {
        if (!signer || !contract || !scanResult?.amount) return;
        setLoading(true);

        try {
            const address = await signer.getAddress();
            const nonce = await contract.getNonce(address);
            const deadline = Math.floor(Date.now() / 1000) + 3600;
            const amount = ethers.parseUnits(scanResult.amount, 6);
            const chainId = Number((await provider!.getNetwork()).chainId);

            addLog("请求离线签名服务...");

            const response = await fetch(`${OFFLINE_SIGNER_URL}/sign-transfer`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    token: CONTRACTS.USDT,
                    to: scanResult.address,
                    amount: amount.toString(),
                    nonce: nonce.toString(),
                    deadline,
                    chainId,
                    verifyingContract: CONTRACTS.BlindQRTransfer
                })
            });

            if (!response.ok) throw new Error("签名服务不可用");
            const { signature } = await response.json();

            addLog("收到离线签名，提交链上...");

            const tx = await contract.executeOfflineTransfer(
                CONTRACTS.USDT,
                scanResult.address,
                amount,
                nonce,
                deadline,
                signature
            );
            await tx.wait();

            setTxHash(tx.hash);
            addLog(`✅ 离线签名成功`);
            await updateBalance(signer);
        } catch (err: any) {
            setError(err.message);
            addLog(`❌ 离线签名失败: ${err.message}`);
        }
        setLoading(false);
    };

    const handleBlind = async () => {
        if (!signer || !contract || !scanResult?.amount) return;
        setLoading(true);

        try {
            const amount = ethers.parseUnits(scanResult.amount, 6);

            const realHash = BlindSignatureTool.hashTransfer(
                CONTRACTS.USDT,
                scanResult.address,
                amount,
                BigInt(0),
                0
            );

            addLog("盲化交易内容...");
            const { blindHash } = BlindSignatureTool.blind(realHash);

            addLog("请求盲签（签名者不知道内容）...");
            const response = await fetch(`${OFFLINE_SIGNER_URL}/sign-blind`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ blindHash })
            });

            const { blindSignature } = await response.json();

            addLog("提交盲签执行...");
            const tx = await contract.executeBlindTransfer(
                blindHash,
                blindSignature,
                CONTRACTS.USDT,
                scanResult.address,
                amount
            );
            await tx.wait();

            setTxHash(tx.hash);
            addLog(`✅ 盲签成功（攻击面：用户未验证内容）`);
        } catch (err: any) {
            setError(err.message);
            addLog(`❌ 盲签失败: ${err.message}`);
        }
        setLoading(false);
    };

    const handleBatchBlind = async () => {
        if (!signer || !contract) return;
        setLoading(true);

        try {
            addLog("构造批量盲签攻击...");

            const targets = [
                { to: scanResult?.address || "0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B", amount: ethers.parseUnits("100", 6) },
                { to: "0xdD870fA1b7C4700F2BD7f44238821C26f7392148", amount: ethers.parseUnits("200", 6) },
                { to: "0x583031D1113aD414F02576BD6afaBfb302140225", amount: ethers.parseUnits("300", 6) }
            ];

            const blindHashes: string[] = [];
            const signatures: string[] = [];
            const tokens: string[] = [];
            const tos: string[] = [];
            const amounts: bigint[] = [];

            for (const target of targets) {
                const hash = BlindSignatureTool.hashTransfer(
                    CONTRACTS.USDT, target.to, target.amount, BigInt(0), 0
                );
                const { blindHash } = BlindSignatureTool.blind(hash);

                const res = await fetch(`${OFFLINE_SIGNER_URL}/sign-blind`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ blindHash })
                });
                const { blindSignature } = await res.json();

                blindHashes.push(blindHash);
                signatures.push(blindSignature);
                tokens.push(CONTRACTS.USDT);
                tos.push(target.to);
                amounts.push(target.amount);
            }

            addLog("提交批量盲签（3笔隐藏交易）...");

            const tx = await contract.batchBlindTransfer(
                blindHashes,
                signatures,
                tokens,
                tos,
                amounts
            );
            await tx.wait();

            setTxHash(tx.hash);
            addLog(`✅ 批量盲签攻击完成！`);
        } catch (err: any) {
            setError(err.message);
            addLog(`❌ 批量攻击失败: ${err.message}`);
        }
        setLoading(false);
    };

    return (
        <div className="container">
            <h1>🕵️ 区块链攻击实验室 - 扫码转账</h1>

            {!signer ? (
                <button onClick={connectWallet} className="btn btn-primary">
                    🔗 连接 MetaMask
                </button>
            ) : (
                <>
                    <div className="wallet-info">
                        <span>💰 余额: {balance} USDT</span>
                        <span>🔓 授权: {allowance} USDT</span>
                    </div>

                    <div className="mode-tabs">
                        {(['normal', 'offline', 'blind', 'batch-blind'] as Mode[]).map(m => (
                            <button
                                key={m}
                                className={mode === m ? 'active' : ''}
                                onClick={() => setMode(m)}
                            >
                                {m === 'normal' && '🔄 普通'}
                                {m === 'offline' && '🔒 离线签名'}
                                {m === 'blind' && '🕶️ 盲签'}
                                {m === 'batch-blind' && '💣 批量盲签'}
                            </button>
                        ))}
                    </div>

                    <div className="scanner">
                        <QrReader
                            constraints={{ facingMode: 'environment' }}
                            onResult={(res) => handleScan(res?.getText())}
                            style={{ width: '100%' }}
                        />
                    </div>

                    {scanResult && (
                        <div className="scan-result">
                            <h3>📱 扫描结果</h3>
                            <p>类型: {scanResult.type}</p>
                            <p>地址: {scanResult.address}</p>
                            {scanResult.amount && <p>金额: {scanResult.amount} USDT</p>}
                            {scanResult.memo && <p>备注: {scanResult.memo}</p>}
                        </div>
                    )}

                    {scanResult && (
                        <div className="actions">
                            {mode === 'normal' && (
                                <button onClick={handleNormal} disabled={loading} className="btn btn-success">
                                    {loading ? '转账中...' : '确认转账'}
                                </button>
                            )}

                            {mode === 'offline' && (
                                <>
                                    <p className="hint">私钥保存在隔离服务器，通过 API 请求签名</p>
                                    <button onClick={handleOffline} disabled={loading} className="btn btn-warning">
                                        {loading ? '请求签名...' : '🔒 离线签名转账'}
                                    </button>
                                </>
                            )}

                            {mode === 'blind' && (
                                <>
                                    <p className="hint danger">⚠️ 攻击测试：用户无法验证实际交易内容</p>
                                    <button onClick={handleBlind} disabled={loading} className="btn btn-danger">
                                        {loading ? '盲签中...' : '🕶️ 执行盲签'}
                                    </button>
                                </>
                            )}

                            {mode === 'batch-blind' && (
                                <>
                                    <p className="hint danger">⚠️ 高级攻击：一次签名执行多笔隐藏转账</p>
                                    <button onClick={handleBatchBlind} disabled={loading} className="btn btn-danger">
                                        {loading ? '攻击中...' : '💣 批量盲签攻击'}
                                    </button>
                                </>
                            )}
                        </div>
                    )}

                    {txHash && (
                        <div className="success">
                            ✅ 交易成功: 
                            <a href={`https://sepolia.etherscan.io/tx/${txHash}`} target="_blank" rel="noreferrer">
                                {txHash.slice(0, 20)}...
                            </a>
                        </div>
                    )}

                    {error && <div className="error">❌ {error}</div>}

                    <div className="logs">
                        <h4>📋 操作日志</h4>
                        {logs.map((log, i) => <div key={i}>{log}</div>)}
                    </div>
                </>
            )}
        </div>
    );
};
