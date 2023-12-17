import * as hre from "hardhat";
import { lzEndpoints } from "../constants/lzEndpoints";

async function main() {

    const network = hre.network.name;

    // print all lz endpoints
    console.log('lzEndpoints: ', lzEndpoints)

    const endpointAddress = lzEndpoints[network];

    // print endpoint address
    console.log('endpointAddress: ', endpointAddress);

    const deployer = (await hre.ethers.getSigners())[0];

    // print deployer
    console.log('deployer: ', deployer.address);

    const { deploy } = hre.deployments;

    const manualGasPrice = hre.ethers.parseUnits("10", "gwei").toString();
    console.log('manual gas price: ', manualGasPrice);

    // deploy cross-chain relay
    const relay = await deploy('CrossChainRelayUpgradeable', {
        from: deployer.address,
        args: [],
        log: true,
        // gasPrice: manualGasPrice,
        deterministicDeployment: true,
    });

    // deploy proxy
    const proxy = await deploy('CrossChainRelayProxy', {
        from: deployer.address,
        args: [relay.address, "0x"],
        log: true,
        // manaually set gas price to 10gwei
        // gasPrice: manualGasPrice,
        deterministicDeployment: true,
    });

    const relayContract = await hre.ethers.getContractAt('CrossChainRelayUpgradeable', proxy.address);

    const relayOwner = await relayContract.owner();

    console.log(relayOwner);

    const tx = await relayContract.initialize(endpointAddress);

    // wait for tx
    tx.wait();

    // print tx hash
    console.log('tx hash: ', tx.hash);


    // print deployed address
    console.log('relay: ', relay.address);
    console.log('proxy: ', proxy.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
