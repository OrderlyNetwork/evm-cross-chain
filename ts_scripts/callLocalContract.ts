import * as hre from "hardhat";
import { getPk, getRpcUrl } from "../foundry_ts/utils/envUtils";
import { findFile } from "../foundry_ts/utils/findFile";
import * as fs from "fs";

export function callLocalContract(
    network: string,
    contract: string,
    address: string,
    method: string,
    args: any[],
    value: string) {
    const artifactFileName = contract + '.json';
    // search the current path recursively for artifact file
    const rpcUrl = getRpcUrl(network);
    const pk = getPk(network);
    
    const artifactFile = findFile('./', artifactFileName);
    if (!artifactFile) {
        throw Error(`${artifactFileName} not found, please compile your contracts first.`)
    }
    let artifact = JSON.parse(fs.readFileSync(artifactFile, 'utf8'));
    if (!artifact.abi) {
        throw Error(`abi not found in artifact, please check your compilation.`)
    }
    const abi = artifact.abi;

    callLocalContractWithAbi(pk, rpcUrl, address, abi, method, args, value).then( () => {
        console.log("contract call succeed.");
    }).catch((e) => {
        console.log(`contract call failed: ${e}`)
    });
}

export async function callLocalContractWithAbi(
    pk: string,
    rpcUrl: string,
    address: string,
    abi: any,
    method: string,
    args: any[],
    value: string) {

    const provider = new hre.ethers.JsonRpcProvider(rpcUrl);
    const wallet = new hre.ethers.Wallet(pk, provider);

    console.log('abi: ', abi);
    console.log('method: ', method);

    const contractInst = new hre.ethers.Contract(address, abi, wallet);

    // Dynamically call the function based on funcName and params
    const result = await contractInst[method](...args, {
        value: hre.ethers.parseEther(value)
    });
    console.log(`Result for call ${address} with args: ${args} at ${address}:`, result);

}