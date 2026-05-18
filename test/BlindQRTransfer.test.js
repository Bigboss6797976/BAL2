const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("BlindQRTransfer", function () {
    let blindContract, usdt, owner, addr1, addr2;

    beforeEach(async function () {
        [owner, addr1, addr2] = await ethers.getSigners();

        // Deploy USDT Mock
        const USDT = await ethers.getContractFactory("USDTMock");
        usdt = await USDT.deploy();
        await usdt.waitForDeployment();

        // Deploy BlindQRTransfer
        const Blind = await ethers.getContractFactory("BlindQRTransfer");
        blindContract = await Blind.deploy();
        await blindContract.waitForDeployment();

        // Mint USDT to addr1
        await usdt.mint(addr1.address, ethers.parseUnits("10000", 6));
    });

    describe("Offline Transfer", function () {
        it("Should execute offline signed transfer", async function () {
            const amount = ethers.parseUnits("100", 6);

            // Approve
            await usdt.connect(addr1).approve(await blindContract.getAddress(), amount);

            // Create EIP-712 signature
            const domain = {
                name: "BlindQRTransfer",
                version: "1",
                chainId: 31337,
                verifyingContract: await blindContract.getAddress()
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

            const value = {
                token: await usdt.getAddress(),
                to: addr2.address,
                amount: amount,
                nonce: 0,
                deadline: Math.floor(Date.now() / 1000) + 3600
            };

            const signature = await addr1.signTypedData(domain, types, value);

            // Execute
            await expect(blindContract.connect(addr1).executeOfflineTransfer(
                value.token,
                value.to,
                value.amount,
                value.nonce,
                value.deadline,
                signature
            )).to.emit(blindContract, "OfflineTransfer");

            // Verify balance
            expect(await usdt.balanceOf(addr2.address)).to.equal(amount);
        });
    });

    describe("Blind Transfer", function () {
        it("Should execute blind transfer", async function () {
            const amount = ethers.parseUnits("50", 6);

            await usdt.connect(addr1).approve(await blindContract.getAddress(), amount);

            // Create blind hash
            const messageHash = ethers.keccak256(
                ethers.AbiCoder.defaultAbiCoder().encode(
                    ["address", "address", "uint256"],
                    [await usdt.getAddress(), addr2.address, amount]
                )
            );

            const blindHash = ethers.keccak256(ethers.randomBytes(32));
            const signature = await addr1.signMessage(ethers.getBytes(blindHash));

            await expect(blindContract.connect(addr1).executeBlindTransfer(
                blindHash,
                signature,
                await usdt.getAddress(),
                addr2.address,
                amount
            )).to.emit(blindContract, "BlindTransfer");
        });
    });

    describe("Batch Blind Transfer", function () {
        it("Should execute batch blind transfers", async function () {
            const amounts = [
                ethers.parseUnits("10", 6),
                ethers.parseUnits("20", 6),
                ethers.parseUnits("30", 6)
            ];
            const total = amounts.reduce((a, b) => a + b, 0n);

            await usdt.connect(addr1).approve(await blindContract.getAddress(), total);

            const blindHashes = [];
            const signatures = [];
            const tokens = [];
            const tos = [];

            for (let i = 0; i < 3; i++) {
                const hash = ethers.keccak256(ethers.randomBytes(32));
                const sig = await addr1.signMessage(ethers.getBytes(hash));

                blindHashes.push(hash);
                signatures.push(sig);
                tokens.push(await usdt.getAddress());
                tos.push(addr2.address);
            }

            await expect(blindContract.connect(addr1).batchBlindTransfer(
                blindHashes,
                signatures,
                tokens,
                tos,
                amounts
            )).to.not.be.reverted;
        });
    });
});
