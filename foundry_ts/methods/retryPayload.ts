import { addOperation, addArgvType } from "../utils/config";
import { set_env_var, foundry_wrapper } from "../foundry";
import { checkArgs } from "../helper";

// current file name
const method_name = "retryPayload";

addArgvType("string", "data");

export function retryPayloadWithArgv(argv: any) {
    const required_flags = ["network", "data"];
    checkArgs(method_name, argv, required_flags);
    retryPayload(argv.network, argv.data, argv.broadcast, argv.simulate);
}

export function retryPayload(network: string, data: string, broadcast: boolean, simulate: boolean) {

    set_env_var(method_name, "network", network);
    set_env_var(method_name, "data", data);
    set_env_var(method_name, "broadcast", broadcast.toString());
    foundry_wrapper(method_name, broadcast, simulate);

}

addOperation(method_name, retryPayloadWithArgv);

