import { set_env_var, foundry_wrapper } from "../foundry";
import * as ethers from "ethers";

// current file name
const method_name = "transferNativeToken";

export function transferNativeToken(network: string, to: string, ether: number, broadcast: boolean) {

    // convert to BN
    const amount = ethers.toBigInt(10**18 * ether);

    set_env_var(method_name, "network", network);
    set_env_var(method_name, "to", to);
    set_env_var(method_name, "amount", amount.toString());
    foundry_wrapper(method_name, broadcast);

}

