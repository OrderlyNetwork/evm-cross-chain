// a function to set key value in json file

export function setupDeployJson(file_path: string, env: string, network: string, role: string) {
    // load json file
    const fs = require('fs');
    const json = JSON.parse(fs.readFileSync(file_path, 'utf8'));
    // set key value, the value goes like this "env.network"
    // if env not exist, create it
    if (!json[env]) {
        json[env] = {};
    }

    // if network not exist, create it
    if (!json[env][network]) {
        json[env][network] = {};
    }
    
    if (role === "relay") {
        json[env][network] = {
            "owner": "",
            "proxy": "",
            "relay": "",
        }
    } else if (role === "vault") {
        json[env][network] = {
            "owner": "",
            "manager": "",
            "proxy": "",
            "role": "vault"
        }
    } else if (role === "ledger") {
        json[env][network] = {
            "owner": "",
            "manager": "",
            "proxy": "",
            "role": "ledger"
        }
    } else {
        throw new Error("role not supported");
    }

    //write updated json back to file_path
    // write json into file_path
    fs.writeFileSync(file_path, JSON.stringify(json, null, 4));

}