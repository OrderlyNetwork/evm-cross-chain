import { addOperation } from "../utils/config";
import { set_env_var, foundry_wrapper } from "../foundry";
import { checkArgs } from "../helper";
import { setupDeployJson } from "../utils/setupDeployJson";
import { deployRelay } from "./relay/deployRelay";
import { generalMethod } from "./generalMethod";
import { transferNativeToken } from "./transferNativeToken";
import { transferNativeTokenToRelay } from "./relay/transferNativeTokenToRelay";

// current file name
const method_name = "deployAndSetupAnEnv";

export function deployAndSetupAnEnvWithArgv(argv: any) {
    const required_flags = ["env", "vaultNetwork", "ledgerNetwork", "initEther"];
    checkArgs(method_name, argv, required_flags);
    deployAndSetupAnEnv(argv.env, argv.vaultNetwork, argv.ledgerNetwork, argv.initEther, argv.broadcast, argv.simulate);
}

/// TODO
export function deployAndSetupAnEnv(env: string, vaultNetwork: string, ledgerNetwork: string, initEther: number, broadcast: boolean, simulate: boolean) {

    const networkList = [vaultNetwork, ledgerNetwork];
    // 1. deploy relay
    deployRelay(env, vaultNetwork, broadcast, simulate);
    deployRelay(env, ledgerNetwork, broadcast, simulate);

    // 2. deploy cc manager

}

addOperation(method_name, deployAndSetupAnEnvWithArgv);
