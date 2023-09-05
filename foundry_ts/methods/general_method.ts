import { set_env_var, foundry_wrapper } from "../foundry";

export function generalMethod(method_name: string, env: string, network: string, broadcast: boolean = false) {

    set_env_var(method_name, "env", env);
    set_env_var(method_name, "network", network);
    set_env_var(method_name, "broadcast", broadcast.toString());
    foundry_wrapper(method_name, broadcast);

}

