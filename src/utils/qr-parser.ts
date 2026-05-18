import { ethers } from 'ethers';

export interface QRPayload {
    address: string;
    amount?: string;
    token?: string;
    memo?: string;
    type: 'address' | 'eip681' | 'json' | 'bip21';
}

export function parseQR(content: string): QRPayload {
    // 纯地址
    if (ethers.isAddress(content)) {
        return { address: content, type: 'address' };
    }

    // EIP-681 (ethereum:0x...?value=...)
    if (content.startsWith('ethereum:')) {
        const clean = content.replace('ethereum:', '');
        const [addr, query] = clean.split('?');
        const params = new URLSearchParams(query || '');

        return {
            address: addr,
            amount: params.get('value') || undefined,
            token: params.get('token') || undefined,
            type: 'eip681'
        };
    }

    // BIP21 (bitcoin:... 适配)
    if (content.startsWith('bitcoin:')) {
        const clean = content.replace('bitcoin:', '');
        const [addr, query] = clean.split('?');
        const params = new URLSearchParams(query || '');

        return {
            address: addr,
            amount: params.get('amount') || undefined,
            type: 'bip21'
        };
    }

    // JSON 格式
    try {
        const json = JSON.parse(content);
        return {
            address: json.address || json.to,
            amount: json.amount?.toString(),
            token: json.token,
            memo: json.memo,
            type: 'json'
        };
    } catch {
        throw new Error('无法识别的二维码格式');
    }
}
