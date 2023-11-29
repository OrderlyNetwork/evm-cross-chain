import { set_env_var, foundry_wrapper } from "../foundry";
import * as ethers from "ethers";
import { checkArgs } from "../helper";
import { addArgvType, addOperation } from "../utils/config";

// current file name
const method_name = "transferNativeToken";

addArgvType("string", "to");

export function transferNativeTokenWithArgv(argv: any) {
    const required_flags = ["network", "to", "ether"];
    checkArgs(method_name, argv, required_flags);
    transferNativeToken(argv.network, argv.to, argv.ether, argv.broadcast, argv.simulate);
}

export function transferNativeToken(network: string, to: string, ether: number, broadcast: boolean, simulate: boolean) {

    // convert to BN
    const amount = ethers.parseEther(ether.toString());
    

    set_env_var(method_name, "network", network);
    set_env_var(method_name, "to", to);
    set_env_var(method_name, "amount", amount.toString());
    foundry_wrapper(method_name, broadcast, simulate);

}

addOperation(method_name, transferNativeTokenWithArgv);

