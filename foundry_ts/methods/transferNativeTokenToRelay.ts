import { relay_deploy_json } from "../const";
import { set_env_var, foundry_wrapper } from "../foundry";
import * as ethers from "ethers";
import { transferNativeToken } from "./transferNativeToken";

// current file name
const method_name = "transferNativeTokenToRelay";

export function transferNativeTokenToRelay(env: string, network: string, ether: number, broadcast: boolean) {

    // read from deploy json
    const relayDeployData = JSON.parse(require('fs').readFileSync(relay_deploy_json, 'utf-8'));

    const relayProxyAddress = relayDeployData[env][network]["proxy"];

    transferNativeToken(network, relayProxyAddress, ether, broadcast);
}

