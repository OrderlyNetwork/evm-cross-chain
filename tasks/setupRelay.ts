import { getDeploymentAddresses } from "../utils/readStatic.js";
import { lzChainIdMapping } from "../constants/lzChainIdMapping";
import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { types } from "hardhat/config";

async function setupRelay(taskArgs: any, hre: HardhatRuntimeEnvironment) {

    // handle arguments parsing
    // I have a targetNetwork argument
    // get target network from arguments
    const targetNetwork = taskArgs.targetNetwork;
    console.log('targetNetwork: ', targetNetwork);

    const network = hre.network.name;

    const proxyAddress = getDeploymentAddresses(network)['CrossChainRelayProxy'];
    const targetContractAddress = getDeploymentAddresses(targetNetwork)['CrossChainRelayProxy'];

    // print addresses
    console.log('proxyAddress: ', proxyAddress);
    console.log('targetContractAddress: ', targetContractAddress);

    const relayContract = await hre.ethers.getContractAt('CrossChainRelayUpgradeable', proxyAddress);

    const manualGasPrice = hre.ethers.parseUnits("10", "gwei").toString();
    console.log('manual gas price: ', manualGasPrice);

    if (!taskArgs.transferOnly) {
        if (!taskArgs.skipChainIdMapping) {
            for (const [key, value] of Object.entries(lzChainIdMapping)) {
                // print key and value
                console.log('key: ', key);
                console.log('value: ', value);
                const tx = await relayContract.addChainIdMapping(value[0], value[1], 
                    {
                        gasPrice: manualGasPrice,
                    });
                // wait for tx
                tx.wait();
                console.log('tx hash: ', tx.hash);
            }
        }
        // get network chain id from hre
        const chainId = hre.network.config.chainId;
        if (chainId !== undefined) {
            const tx = await relayContract.setSrcChainId(chainId, 
                {
                    gasPrice: manualGasPrice,
                });
            tx.wait();
            console.log('setSrcChainId tx hash: ', tx.hash);
        } else {
            throw new Error('chainId not found');
        }

        const lzDstChainId = lzChainIdMapping[targetNetwork][1];
        let remoteAndLocal = hre.ethers.solidityPacked(
            ['address', 'address'],
            [targetContractAddress, proxyAddress]
        )

        const tx = await relayContract.setTrustedRemote(lzDstChainId, remoteAndLocal, {
            gasPrice: manualGasPrice,
        })
        tx.wait();
        console.log('setTrustedRemote tx hash: ', tx.hash);
    }

    // transfer some money to the relay contract
    const deployer = (await hre.ethers.getSigners())[0];
    const tx2 = await deployer.sendTransaction({
        to: proxyAddress,
        value: hre.ethers.parseEther(taskArgs.transferAmount.toString()),
    });
    tx2.wait();
    console.log('transfer tx hash: ', tx2.hash);

}

task("setupRelay",
    "Setup relay for a target network",
    setupRelay
)
    .addParam("targetNetwork", "The target network", "")
    .addParam("skipChainIdMapping", "Skip chain id mapping", false, types.boolean)
    .addParam("transferOnly", "onlyTransferETH", false, types.boolean)
    .addParam("transferAmount", "transferAmount", 2, types.int)

