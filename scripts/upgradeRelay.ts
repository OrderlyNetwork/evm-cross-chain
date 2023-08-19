import * as hre from "hardhat";
import { lzEndpoints } from "../constants/lzEndpoints";

async function main() {

    const network = hre.network.name;

    const endpointAddress = lzEndpoints[network];

    // print endpoint address
    console.log('endpointAddress: ', endpointAddress);

    const deployer = (await hre.ethers.getSigners())[0];

    // print deployer
    console.log('deployer: ', deployer.address);

    const { deploy } = hre.deployments;

    // manual gas
    const manualGasPrice = hre.ethers.parseUnits("10", "gwei").toString();

    // deploy cross-chain relay
    const relay = await deploy('CrossChainRelayUpgradeable', {
        from: deployer.address,
        args: [],
        log: true,
        gasPrice: manualGasPrice

    });

    // get deployed proxy address
    const proxy = await hre.deployments.get('CrossChainRelayProxy');

    const relayContract = await hre.ethers.getContractAt('CrossChainRelayUpgradeable', proxy.address);

    const tx = await relayContract.upgradeTo(relay.address,{
            gasPrice: manualGasPrice,
    });

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
