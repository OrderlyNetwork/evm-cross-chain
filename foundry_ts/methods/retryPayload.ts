import { set_env_var, foundry_wrapper } from "../foundry";

// current file name
const method_name = "retryPayload";

export function retryPayload(network: string, data: string, broadcast: boolean) {

    set_env_var(method_name, "network", network);
    set_env_var(method_name, "data", data);
    set_env_var(method_name, "broadcast", broadcast.toString());
    foundry_wrapper(method_name, broadcast);

}

