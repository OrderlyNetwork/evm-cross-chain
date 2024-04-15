import { ethers } from "ethers";
import { genFunctionCalldata, genTxJsonFileName, getContractAbi } from "../utils/getContractAbi";
import { getContractAddress } from "../utils/getDeployData";
import { addArgvType, addOperation } from "../utils/config";
import { checkArgs } from "../helper";
import { getRpcUrl } from "../utils/envUtils";
import { getContractBytecode } from "../utils/getBytecode";

const method_name = "localVerifyDeployment";


function localVerifyDeploymentWithArgv(argv: any) {
    const required_flags = ["env", "network", "contractName"];
    checkArgs(argv.method, argv, required_flags);
    localVerifyDeployment(argv.env, argv.network, argv.contractName);
}

export function localVerifyDeployment(env: string, network: string, contractName: string) {
    const contractAddr = getContractAddress(env, network, contractName, false);
    const rpcUrl = getRpcUrl(network);

    const provider = new ethers.JsonRpcProvider(rpcUrl);
    // get bytecode from contract address
    provider.getCode(contractAddr).then((code) => {
        console.log("Contract address: " + contractAddr);
        console.log("Contract code: " + code);
        // get bytecode 
        const bytecode = getContractBytecode(contractName);
        
        const onChainCodeHash = ethers.keccak256(code);
        const localCodeHash = ethers.keccak256(bytecode['deployedBytecode']);
        console.log("local bytecode: " + bytecode['bytecode']);
        console.log("On chain code hash: " + onChainCodeHash);
        console.log("Local code hash: " + localCodeHash);
        // compare
        if (onChainCodeHash == localCodeHash) {
            console.log("Deployment verified: " + contractAddr);
        } else {
            console.log("Deployment verification failed: " + contractAddr);
        }
    });
}

addOperation(method_name, localVerifyDeploymentWithArgv);