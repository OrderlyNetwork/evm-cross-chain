import { relay_deploy_json } from "../../utils/const";
import { set_env_var, foundry_wrapper } from "../../foundry";
import * as ethers from "ethers";
import { transferNativeToken } from "../transferNativeToken";
import { checkArgs } from "../../helper";
import { addOperation } from "../../utils/config";

// current file name
const method_name = "transferNativeTokenToRelay";

export function transferNativeTokenToRelayWithArgv(argv: any) {
    const required_flags = ["env", "network", "ether"];
    checkArgs(method_name, argv, required_flags);
    transferNativeTokenToRelay(argv.env, argv.network, argv.ether, argv.broadcast, argv.simulate);
}

export function transferNativeTokenToRelay(env: string, network: string, ether: number, broadcast: boolean, simulate: boolean) {

    // read from deploy json
    const relayDeployData = JSON.parse(require('fs').readFileSync(relay_deploy_json, 'utf-8'));

    const relayProxyAddress = relayDeployData[env][network]["proxy"];

    transferNativeToken(network, relayProxyAddress, ether, broadcast, simulate);
}


addOperation(method_name, transferNativeTokenToRelayWithArgv);
