import { addOperation } from "../../utils/config";
import { relay_deploy_json } from "../../utils/const";
import { set_env_var, foundry_wrapper } from "../../foundry";
import { checkArgs } from "../../helper";
import { setupDeployJson } from "../../utils/setupDeployJson";
import { getExporerType } from "../../utils/envUtils";

// current file name
const method_name = "deployRelay";

export function deployRelayWithArgv(argv: any) {
    const required_flags = ["env", "network"]
    checkArgs(method_name, argv, required_flags);
    deployRelay(argv.env, argv.network, argv.broadcast, argv.simulate);
}

export function deployRelay(env: string, network: string, broadcast: boolean, simulate: boolean) {
    setupDeployJson(relay_deploy_json, env, network, "relay");
    set_env_var(method_name, "env", env);
    set_env_var(method_name, "network", network);
    set_env_var(method_name, "broadcast", broadcast.toString());

    const explorerType = getExporerType(network);
    foundry_wrapper(method_name, broadcast, simulate, true, explorerType, network);

}

addOperation(method_name, deployRelayWithArgv);