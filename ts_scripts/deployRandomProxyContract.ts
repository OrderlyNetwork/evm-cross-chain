import * as ethers from "ethers";
import * as hre from "hardhat";
import "@nomicfoundation/hardhat-ethers";

export async function deployRandomProxyContract(pk: string, rpc_url: string, contract: string, args: string[]) {
    const rpc = new ethers.JsonRpcProvider(rpc_url);
    const wallet = new ethers.Wallet(pk, rpc);

    const factory = await hre.ethers.getContractFactory(contract, wallet);
    const proxyFactory = await hre.ethers.getContractFactory("OrderlyProxy", wallet);

    const tx = await factory.deploy(args);
    const result = await tx.waitForDeployment();

    console.log('deploy result: ', result);
}