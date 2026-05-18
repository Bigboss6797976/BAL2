module.exports = {
    solidity: "0.8.19",
    networks: {
        ganache: {
            url: "http://127.0.0.1:8545",
            chainId: 1337,
            accounts: [
                "0xc9a2169db36f3c7830c89b54af0dfbee6a90537318fda4b8f0edf669eebee1be"
            ]
        }
    }
};
