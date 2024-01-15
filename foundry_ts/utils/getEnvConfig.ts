
const filePath = "config/env-config.json";
const fs = require('fs');

export function getEnvConfig(env: string, network: string) {
    // read json file
    const jsonString = fs.readFileSync(filePath);
    const envConfig = JSON.parse(jsonString);

    return envConfig[env][network];

}

export function getAllNetworks(env: string) {
    // read json file
    const jsonString = fs.readFileSync(filePath);
    const envConfig = JSON.parse(jsonString);

    return envConfig[env]["networks"];
}

export function getTokenDecimal(env: string, network: string, token: string) {

    const filePath = "config/token-decimals.json";
    // read json file
    const jsonString = fs.readFileSync(filePath);
    const envConfig = JSON.parse(jsonString);

    const tokenDecimals = envConfig[env][network];
    // it is an array of token decimal
    for (const tokenInfo of tokenDecimals) {
        if (tokenInfo["name"] === token) {
            return tokenInfo;
        }
    }

}