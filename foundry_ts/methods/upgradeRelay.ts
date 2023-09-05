import { set_env_var, foundry_wrapper } from "../foundry";

// current file name
const method_name = "upgradeRelay";

export function upgradeRelay(env: string, network: string, broadcast: boolean = false) {

    set_env_var(method_name, "env", env);
    set_env_var(method_name, "network", network);
    set_env_var(method_name, "broadcast", broadcast.toString());
    foundry_wrapper(method_name, broadcast);

}

