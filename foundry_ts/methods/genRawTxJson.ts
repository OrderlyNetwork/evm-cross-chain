import { ethers } from "ethers";
import { genFunctionCalldata, genTxJsonFileName, getContractAbi } from "../utils/getContractAbi";
import { getContractAddress } from "../utils/getDeployData";
import { addArgvType, addOperation } from "../utils/config";
import { checkArgs } from "../helper";

const method_name = "genRawTx";

addArgvType("string", "value");
addArgvType("string", "params");

function genRawTxWithArgv(argv: any) {
    const required_flags = ["env", "network", "contractName", "funcName", "value", "params"];
    checkArgs(argv.method, argv, required_flags);
    genRawTx(argv.env, argv.network, argv.contractName, argv.funcName, argv.params, argv.value);
}

export function genRawTx(env: string, network: string, contractName: string, funcName: string, params: string, value: string) {
    const proxyAddress = getContractAddress(env, network, contractName, true);
    const paramsArray = params.split(',');
    const calldata = genFunctionCalldata(contractName, funcName, paramsArray);

    // write tx json under ./data
    const fs = require('fs');
    const dataDir = './data';
    if (!fs.existsSync(dataDir)) {
        fs.mkdirSync(dataDir);
    }
    const txJsonPath = genTxJsonFileName(env, network, contractName, funcName);
    
    // sample tx json
    // {
    // "operation": 0,
    // "safeTxGas": 0,
    // "baseGas": 0,
    // "gasPrice": 0,
    // "gasToken": "0x0000000000000000000000000000000000000000",
    // "refundReceiver": "0x0000000000000000000000000000000000000000",
    // "to": "0xB327191924Fde508AeCAe9F79b253CC5031DceA2",
    // "data": "0x39ce5e17000000000000000000000000b327191924fde508aecae9f79b253cc5031dcea2",
    // "value": "0"
    // }

    // json
    const txJson = {
        "operation": 0,
        "safeTxGas": 0,
        "baseGas": 0,
        "gasPrice": 0,
        "gasToken": "0x0000000000000000000000000000000000000000",
        "refundReceiver": "0x0000000000000000000000000000000000000000",
        "to": proxyAddress,
        "data": calldata,
        "value": ethers.parseEther(value).toString()
    }

    // write to file
    fs.writeFileSync(dataDir + '/' + txJsonPath, JSON.stringify(txJson));
    console.log('tx json file generated: ' + txJsonPath);

}

addOperation(method_name, genRawTxWithArgv);