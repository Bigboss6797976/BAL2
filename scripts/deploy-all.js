const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying with:", deployer.address);

    // 部署 Mock USDT
    const USDT = await hre.ethers.getContractFactory("USDTMock");
    const usdt = await USDT.deploy();
    await usdt.waitForDeployment();
    console.log("USDTMock:", await usdt.getAddress());

    // 部署 BlindQRTransfer
    const Blind = await hre.ethers.getContractFactory("BlindQRTransfer");
    const blind = await Blind.deploy();
    await blind.waitForDeployment();
    console.log("BlindQRTransfer:", await blind.getAddress());

    // 部署 QRTransfer
    const QR = await hre.ethers.getContractFactory("QRTransfer");
    const qr = await QR.deploy();
    await qr.waitForDeployment();
    console.log("QRTransfer:", await qr.getAddress());

    // 给部署者铸造一些 USDT
    await usdt.mint(deployer.address, hre.ethers.parseUnits("10000", 6));
    console.log("Minted 10000 USDT to deployer");

    // 保存地址到前端配置
    const fs = require("fs");
    const config = {
        USDT: await usdt.getAddress(),
        BlindQRTransfer: await blind.getAddress(),
        QRTransfer: await qr.getAddress(),
        network: hre.network.name,
        chainId: Number((await hre.ethers.provider.getNetwork()).chainId)
    };

    fs.writeFileSync(
        "./src/utils/constants.ts",
        `export const CONTRACTS = ${JSON.stringify(config, null, 2)} as const;\n\nexport const OFFLINE_SIGNER_URL = "http://localhost:3001";\n`
    );

    // 同时保存 JSON 版本供脚本使用
    fs.writeFileSync("./contract-addresses.json", JSON.stringify(config, null, 2));

    console.log("\n✅ 部署完成！地址已写入 src/utils/constants.ts");
    console.log("\n合约地址:");
    console.log("- USDTMock:", config.USDT);
    console.log("- BlindQRTransfer:", config.BlindQRTransfer);
    console.log("- QRTransfer:", config.QRTransfer);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
