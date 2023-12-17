import { addOperation } from "../../utils/config";
import { set_env_var, foundry_wrapper } from "../../foundry";
import { checkArgs } from "../../helper";

// current file name
const method_name = "relayMsgTest";

export function relayMsgTestWithArgv(argv: any) {
    const required_flags = ["env", "srcNetwork", "dstNetwork"];
    checkArgs(method_name, argv, required_flags);
    relayMsgTest(argv.env, argv.srcNetwork, argv.dstNetwork, argv.broadcast, argv.simulate);
}

export function relayMsgTest(env: string, srcNetwork: string, dstNetwork: string, broadcast: boolean, simulate: boolean) {

    set_env_var(method_name, "env", env);
    set_env_var(method_name, "srcNetwork", srcNetwork);
    set_env_var(method_name, "dstNetwork", dstNetwork)
    set_env_var(method_name, "broadcast", broadcast.toString());
    foundry_wrapper(method_name, broadcast, simulate);

}

addOperation(method_name, relayMsgTestWithArgv);

