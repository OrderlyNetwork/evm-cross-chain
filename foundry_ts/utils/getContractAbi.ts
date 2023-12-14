const fs = require('fs');
import { ethers } from 'ethers';
import { getContractAbiPath } from './const';

export function getContractAbi(contractName: string, funcName: string) {
    const contractOutPath = getContractAbiPath(contractName);
    // read json
    const fileContent = fs.readFileSync(contractOutPath, 'utf8');
    const contractOutJson = JSON.parse(fileContent);
    // find abi data from ['abi'] name == funcName and type == function
    const abiList = contractOutJson['abi'];
    for (const abi of abiList) {
        if (abi['name'] == funcName && abi['type'] == 'function') {
            return abi;
        }
    }
    // raise error with detail
    throw new Error('abi not found, contractName: ' + contractName + ', funcName: ' + funcName);
}

export function abiToSignature(abi: any) {
    const type = abi['type'];
    const name = abi['name'];
    const inputs = abi['inputs'];
    let signature = name + '(';
    for (const input of inputs) {
        console.log(input);
        if (input['type'] === 'tuple') {
            signature += '(';
            for (const tupleInput of input['components']) {
                if (tupleInput['type'] == 'tuple') {
                    throw new Error('tuple in tuple not supported');
                }
                signature += tupleInput['type'] + ',';
            }
            signature += '),';
        } else {
            signature += input['type'] + ',';
        }
    }
    // remove the last ','
    signature = signature.slice(0, -1);
    return signature + ')';
}

export function getFunctionSignature(contractName: string, funcName: string) {
    const abi = getContractAbi(contractName, funcName);
    return abiToSignature(abi);
}

export function genFunctionCalldata(contractName: string, funcName: string, params: any[]) {
    const abi = getContractAbi(contractName, funcName);
    const signature = abiToSignature(abi);

    const iface = new ethers.Interface([abi]);

    // encode params
    try {
        return iface.encodeFunctionData(signature, params);
    } catch (e) {
        throw new Error('encodeFunctionData error, signature: ' + signature + ', params: ' + params);
    }
}

export function genTxJsonFileName(env: string, network: string, contractName: string, funcName: string) {
    return env + '_' + network + '_' + contractName + '_' + funcName + '.json';
}