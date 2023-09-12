import { addOperation } from "../../utils/config";
import { relay_deploy_json } from "../../utils/const";
import { set_env_var, foundry_wrapper } from "../../foundry";
import { checkArgs } from "../../helper";

// current file name
const method_name = "setRelayTrustedRemote";

export function setRelayTrustedRemoteWithArgv(argv: any) {
    const required_flags = ["env", "srcNetwork", "dstNetwork"];
    checkArgs(method_name, argv, required_flags);
    setRelayTrustedRemote(argv.env, argv.srcNetwork, argv.dstNetwork, argv.broadcast, argv.simulate);
}

export function setRelayTrustedRemote(env: string, srcNetwork: string, dstNetwork: string, broadcast: boolean, simulate: boolean) {
    
    set_env_var(method_name, "env", env);
    set_env_var(method_name, "srcNetwork", srcNetwork);
    set_env_var(method_name, "dstNetwork", dstNetwork);
    foundry_wrapper(method_name, broadcast, simulate);

}

addOperation(method_name, setRelayTrustedRemoteWithArgv);