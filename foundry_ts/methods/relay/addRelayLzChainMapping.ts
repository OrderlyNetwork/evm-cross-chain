import { addOperation } from "../../utils/config";
import { set_env_var, foundry_wrapper } from "../../foundry";
import { checkArgs } from "../../helper";

// current file name
const method_name = "addRelayLzChainMapping";

export function addRelayLzChainMappingWithArgv(argv: any) {
    const required_flags = ["env", "relayNetwork", "addNetwork"]
    checkArgs(method_name, argv, required_flags);
    addRelayLzChainMapping(argv.env, argv.relayNetwork, argv.addNetwork, argv.broadcast, argv.simulate);
}

export function addRelayLzChainMapping(env: string, relayNetwork: string, addNetwork: string, broadcast: boolean, simulate: boolean) {
    set_env_var(method_name, "env", env);
    set_env_var(method_name, "relayNetwork", relayNetwork);
    set_env_var(method_name, "addNetwork", addNetwork);
    foundry_wrapper(method_name, broadcast, simulate);

}

addOperation(method_name, addRelayLzChainMappingWithArgv);
