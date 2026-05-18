import { ethers } from 'ethers';

export class BlindSignatureTool {
    /**
     * 盲化消息 - 隐藏真实交易内容
     */
    static blind(messageHash: string): {
        blindHash: string;
        unblindFactor: string;
    } {
        // 生成随机盲化因子
        const r = ethers.hexlify(ethers.randomBytes(32));
        const rBig = BigInt(r);

        // 简化盲化：hash * r mod curve_order
        const hashBig = BigInt(messageHash);
        const order = BigInt("0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141");

        const blindHash = ((hashBig * rBig) % order).toString(16);

        return {
            blindHash: '0x' + blindHash.padStart(64, '0'),
            unblindFactor: r
        };
    }

    /**
     * 解盲签名
     */
    static unblind(blindSig: string, unblindFactor: string): string {
        // 简化实现：实际需 s' = s * r^-1 mod n
        return blindSig;
    }

    /**
     * 构造转账消息哈希
     */
    static hashTransfer(
        token: string,
        to: string,
        amount: bigint,
        nonce: bigint,
        deadline: number
    ): string {
        return ethers.keccak256(
            ethers.AbiCoder.defaultAbiCoder().encode(
                ['bytes32', 'address', 'address', 'uint256', 'uint256', 'uint256'],
                [
                    ethers.id("Transfer(address token,address to,uint256 amount,uint256 nonce,uint256 deadline)"),
                    token,
                    to,
                    amount,
                    nonce,
                    deadline
                ]
            )
        );
    }
}
