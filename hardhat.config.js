require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-verify");

const PRIVATE_KEY = process.env.PRIVATE_KEY || "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";

module.exports = {
    solidity: {
        version: "0.8.19",
        settings: {
            optimizer: {
                enabled: true,
                runs: 200
            }
        }
    },
    networks: {
        hardhat: {
            chainId: 31337,
            forking: {
                url: "https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY",
                enabled: false
            }
        },
        sepolia: {
            url: "https://rpc.sepolia.org",
            accounts: [PRIVATE_KEY],
            chainId: 11155111
        },
        bscTestnet: {
            url: "https://data-seed-prebsc-1-s1.binance.org:8545",
            accounts: [PRIVATE_KEY],
            chainId: 97
        }
    },
    etherscan: {
        apiKey: {
            mainnet: "YOUR_ETHERSCAN_KEY",
            sepolia: "YOUR_ETHERSCAN_KEY",
            bscTestnet: "YOUR_BSCSCAN_KEY"
        }
    },
    gasReporter: {
        enabled: true,
        currency: "USD"
    }
};
