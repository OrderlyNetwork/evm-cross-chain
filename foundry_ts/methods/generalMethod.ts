import { addOperation } from "../utils/config";
import { set_env_var, foundry_wrapper } from "../foundry";
import { checkArgs } from "../helper";

export function generalMethodWithArgv(argv: any) {
    const required_flags = ["env", "network"]
    checkArgs(argv.method, argv, required_flags);
    generalMethod(argv.method, argv.env, argv.network, argv.broadcast, argv.simulate);
}

export function generalMethod(method_name: string, env: string, network: string, broadcast: boolean, simulate: boolean) {

    set_env_var(method_name, "env", env);
    set_env_var(method_name, "network", network);
    set_env_var(method_name, "broadcast", broadcast.toString());
    foundry_wrapper(method_name, broadcast, simulate);

}

addOperation("setRelayManager", generalMethodWithArgv);
addOperation("setRelayChainId", generalMethodWithArgv);
addOperation("printCCManagerLedger", generalMethodWithArgv);
addOperation("printCCManagerVault", generalMethodWithArgv);
