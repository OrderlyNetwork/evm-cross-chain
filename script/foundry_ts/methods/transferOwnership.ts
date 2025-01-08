import { set_env_var, foundry_wrapper } from "../foundry";
import * as ethers from "ethers";
import { checkArgs } from "../helper";
import { addOperation, addArgvType } from "../utils/config";

// current file name
const method_name = "transferOwnership";

addArgvType("string", "contract");
addArgvType("string", "newOwner");

export function transferOwnershipWithArgv(argv: any) {
    const required_flags = ["network", "contract", "newOwner"];
    checkArgs(method_name, argv, required_flags);
    transferOwnership(argv.network, argv.contract, argv.newOwner, argv.broadcast, argv.simulate);
}

export function transferOwnership(network: string, contract: string, newOwner: string, broadcast: boolean, simulate: boolean) {

    set_env_var(method_name, "network", network);
    set_env_var(method_name, "contract", contract);
    set_env_var(method_name, "newOwner", newOwner);
    foundry_wrapper(method_name, broadcast, simulate);

}

addOperation(method_name, transferOwnershipWithArgv);

