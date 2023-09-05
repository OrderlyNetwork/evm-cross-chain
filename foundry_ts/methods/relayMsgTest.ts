import { set_env_var, foundry_wrapper } from "../foundry";

// current file name
const method_name = "relayMsgTest";

export function relayMsgTest(env: string, srcNetwork: string, dstNetwork: string, broadcast: boolean) {

    set_env_var(method_name, "env", env);
    set_env_var(method_name, "srcNetwork", srcNetwork);
    set_env_var(method_name, "dstNetwork", dstNetwork)
    set_env_var(method_name, "broadcast", broadcast.toString());
    foundry_wrapper(method_name, broadcast);

}

