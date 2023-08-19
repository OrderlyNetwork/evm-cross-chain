import { getDeploymentAddresses } from "../utils/readStatic.js";
import { lzChainIdMapping } from "../constants/lzChainIdMapping";
import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { types } from "hardhat/config";

async function sendPing(taskArgs: any, hre: HardhatRuntimeEnvironment) {
    const network = hre.network.name;

    const dstNetwork = taskArgs.targetNetwork;

    const proxyAddress = getDeploymentAddresses(network)['CrossChainRelayProxy'];

    const relay = await hre.ethers.getContractAt('CrossChainRelayUpgradeable', proxyAddress);

    const dstChainId = lzChainIdMapping[dstNetwork][0];

    // manual gas
    const manualGasPrice = hre.ethers.parseUnits("10", "gwei").toString();

    if (taskArgs.pong) {
        const tx = await relay.pingPong(dstChainId);
        tx.wait();
        console.log('pingPong tx hash: ', tx.hash);
    } else {
        const tx = await relay.ping(dstChainId, {
            gasPrice: manualGasPrice,
        });
        tx.wait();
        console.log('ping tx hash: ', tx.hash);
    }
}

task("sendPing", "Send ping to the relay contract")
    .addParam("targetNetwork", "The target network")
    .addParam("pong", "whether require pong", false, types.boolean)
    .setAction(sendPing);
