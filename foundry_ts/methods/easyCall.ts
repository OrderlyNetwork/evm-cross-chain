import { ethers } from "ethers";
import { genFunctionCalldata, genTxJsonFileName, getContractAbi } from "../utils/getContractAbi";
import { getContractAddress } from "../utils/getDeployData";
import { addArgvType, addOperation } from "../utils/config";
import { checkArgs } from "../helper";
import { getPk, getRpcUrl } from "../utils/envUtils";
import { deployRandomProxyContract } from "../../ts_scripts/deployRandomProxyContract";
import { callLocalContract } from "../../ts_scripts/callLocalContract";

const method_name = "easyCall";

addArgvType("string", "contract");
addArgvType("string", "address");
addArgvType("string", "args");
addArgvType("string", "value");

function easyCallWithArgv(argv: any) {
    const required_flags = ["env", "network", "contract", "address", "func"];
    checkArgs(argv.method, argv, required_flags);
    easyCall(argv.env, argv.network, argv.contract, argv.address, argv.func, argv.value, argv.args);
}

export function easyCall(
    env: string,
    network: string,
    contract: string, 
    address: string, 
    method: string, 
    value: string, 
    args: string) {
    // split string by ","
    let splitArgs: string[] = [];
    if (args) {
        splitArgs = args.split(',');
    } 
    console.log('call args: ', splitArgs);

    let callValue = "0";
    if (value) { callValue = value; }

    callLocalContract(network, contract, address, method, splitArgs, callValue);

}

addOperation(method_name, easyCallWithArgv);