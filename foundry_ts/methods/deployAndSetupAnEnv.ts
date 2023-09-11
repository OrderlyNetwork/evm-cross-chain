import { set_env_var, foundry_wrapper } from "../foundry";
import { setupDeployJson } from "../utils/setup_json";
import { deployRelay } from "./deployRelay";
import { generalMethod } from "./generalMethod";
import { transferNativeToken } from "./transferNativeToken";
import { transferNativeTokenToRelay } from "./transferNativeTokenToRelay";

// current file name
const method_name = "deployAndSetupAnEnv";

/// TODO
export function deployAndSetupAnEnv(env: string, vaultNetwork: string, ledgerNetwork: string, initEther: number, broadcast: boolean, simulate: boolean) {

    const networkList = [vaultNetwork, ledgerNetwork];
    // 1. deploy relay
    deployRelay(env, vaultNetwork, broadcast, simulate);
    deployRelay(env, ledgerNetwork, broadcast, simulate);
    // set relay chain ids
    for (let i = 0; i < networkList.length; i++) {
        generalMethod("setRelayChainId", env, networkList[i], broadcast, simulate);
    }

    // transfer native token
    for (let i = 0; i < networkList.length; i++) {
        transferNativeTokenToRelay(env, networkList[i], initEther, broadcast);
    }

    // 

}

