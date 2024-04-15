import { getContractAbiPath } from "./const";

const fs = require('fs');

export function getContractBytecode(contractName: string) {
    const contractOutPath = getContractAbiPath(contractName);
    // read json
    const fileContent = fs.readFileSync(contractOutPath, 'utf8');
    const contractOutJson = JSON.parse(fileContent);

    // raise error with detail
    if (!contractOutJson['bytecode']) {
        throw new Error('bytecode not found, contractName: ' + contractName)
    }
    if (!contractOutJson['deployedBytecode']) {
        throw new Error('deployedBytecode not found, contractName: ' + contractName)
    }

    return {
        "bytecode": contractOutJson['bytecode']['object'],
        "deployedBytecode": contractOutJson['deployedBytecode']['object']
    }

}