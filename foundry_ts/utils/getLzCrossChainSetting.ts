// {
//     "withdraw": 400000,
//     "deposit": 250000,
//     "withdrawFinish": 200000,
//     "pingPong": 500000,
//     "ping": 500000,
//     "burn": 450000,
//     "burnFinish": 280000,
//     "mint": 550000,
//     "mintFinish": 280000
// } 

// define LzCCGasLimitSetting as key value mapping
export interface LzCCGasLimitSetting {
    [key: string]: number
}

export function getLzCrossChainGasLimitSetting() : LzCCGasLimitSetting {
    const path = "./config/cross-chain-method-gas.json";
    // load json file from path as LzCCGasLimitSetting
    const fs = require('fs');
    // read json file
    const fileContent = fs.readFileSync(path, 'utf8');
    // parse json
    const gasLimitSetting = JSON.parse(fileContent);

    return gasLimitSetting;

}

const defaultMethodNumber = {
    "withdraw": 0,
    "deposit": 1,
    "withdrawFinish": 2,
    "pingPong": 3,
    "ping": 4,
    "burn": 5,
    "burnFinish": 6,
    "mint": 7,
    "mintFinish": 8
}

export function ccMethodToNumber(method: string): number {
    return defaultMethodNumber[method as keyof typeof defaultMethodNumber];
}