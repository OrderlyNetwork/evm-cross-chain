import { ethers } from "ethers";
import { genFunctionCalldata, genTxJsonFileName, getContractAbi } from "../utils/getContractAbi";
import { getContractAddress } from "../utils/getDeployData";
import { addArgvType, addOperation } from "../utils/config";
import { checkArgs } from "../helper";
import { getPk, getRpcUrl } from "../utils/envUtils";
import { deployRandomProxyContract } from "../../ts_scripts/deployRandomProxyContract";

const method_name = "deployProxyContract";

addArgvType("string", "contract");
addArgvType("string", "args");

function deployProxyContractWithArgv(argv: any) {
    const required_flags = ["env", "network", "contract"];
    checkArgs(argv.method, argv, required_flags);
    deployProxyContract(argv.env, argv.network, argv.contract, argv.args);
}

export function deployProxyContract(env: string, network: string, contract: string, args: string) {
    // split string by ","
    let splitArgs: string[];
    if (args) {
        splitArgs = args.split(',');
    } else {
        splitArgs = []
    }
    console.log('constructor args: ', splitArgs);

    const pk = getPk(network);
    const rpcUrl = getRpcUrl(network);

    deployRandomProxyContract(pk, rpcUrl, contract, splitArgs).then(() => {
        console.log('sucess');
    })
}

addOperation(method_name, deployProxyContractWithArgv);