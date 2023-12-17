import { addOperation } from "../../utils/config";
import { set_env_var, foundry_wrapper } from "../../foundry";
import { checkArgs } from "../../helper";
import { relay_deploy_json } from "../../utils/const";
import { addRelayLzChainMapping } from "./addRelayLzChainMapping";

// current file name
const method_name = "addRelayLzChainMappingAll";

export function addRelayLzChainMappingAllWithArgv(argv: any) {
    const required_flags = ["env", "network"]
    checkArgs(method_name, argv, required_flags);
    addRelayLzChainMappingAll(argv.env, argv.network, argv.broadcast, argv.simulate);
}

export function addRelayLzChainMappingAll(env: string, network: string, broadcast: boolean, simulate: boolean) {
    // read from json file
    const fs = require('fs');
    const filePath = relay_deploy_json;
    const fileContent = fs.readFileSync(filePath, 'utf8');
    const lzChainMapping = JSON.parse(fileContent);
    if (lzChainMapping[env] == undefined) {
        throw new Error(`env ${env} not found in ${relay_deploy_json}`);
    } else {
        for (const key in lzChainMapping[env]) {
            console.log(`adding chain id mapping for ${key} on ${network}`);
            addRelayLzChainMapping(env, network, key, broadcast, simulate);
        }
    }
}

addOperation(method_name, addRelayLzChainMappingAllWithArgv);
