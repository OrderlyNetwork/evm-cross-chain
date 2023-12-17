
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