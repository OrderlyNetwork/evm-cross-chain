import { relay_deploy_json } from "../const";
import { set_env_var, foundry_wrapper } from "../foundry";
import { setupDeployJson } from "../utils/setup_json";

// current file name
const method_name = "deployRelay";

export function deployRelay(env: string, network: string, broadcast: boolean, simulate: boolean) {
    setupDeployJson(relay_deploy_json, env, network, "relay");
    set_env_var(method_name, "env", env);
    set_env_var(method_name, "network", network);
    set_env_var(method_name, "broadcast", broadcast.toString());
    foundry_wrapper(method_name, broadcast, simulate);

}

