import { addOperation } from "../../utils/config";
import { relay_deploy_json } from "../../utils/const";
import { set_env_var, foundry_wrapper } from "../../foundry";
import { checkArgs } from "../../helper";
import { addRelayLzChainMapping } from "./addRelayLzChainMapping";
import { generalMethod } from "../generalMethod";
import { setRelayTrustedRemote } from "./setRelayTrustedRemote";
import { transferNativeTokenToRelay } from "./transferNativeTokenToRelay";

// current file name
const method_name = "setupRelayWith1Dst";

export function setRelayWith1DstWithArgv(argv: any) {
    const required_flags = ["env", "relayNetwork", "dstNetwork", "initEther"];
    checkArgs(method_name, argv, required_flags);
    setupRelayWith1Dst(argv.env, argv.relayNetwork, argv.dstNetwork, argv.initEther, argv.broadcast, argv.simulate);
}

export function setupRelayWith1Dst(env: string, relayNetwork: string, dstNetwork: string, initEther: number, broadcast: boolean, simulate: boolean) {
    // 1. set current chain id
    generalMethod("setRelayChainId", env, relayNetwork, broadcast, simulate);    

    // 2. transfer native token
    transferNativeTokenToRelay(env, relayNetwork, initEther, broadcast, simulate);

    // 3. add chain id to lz chain id mapping
    addRelayLzChainMapping(env, relayNetwork, relayNetwork, broadcast, simulate);
    addRelayLzChainMapping(env, relayNetwork, dstNetwork, broadcast, simulate);

    // 4. set relay cc manager
    generalMethod("setRelayManager", env, relayNetwork, broadcast, simulate);

    // 5. set trusted remote
    setRelayTrustedRemote(env, relayNetwork, dstNetwork, broadcast, simulate);
}

addOperation(method_name, setRelayWith1DstWithArgv)