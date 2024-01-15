import { addArgvType, addOperation } from "../../utils/config";
import { set_env_var, foundry_wrapper } from "../../foundry";
import { checkArgs } from "../../helper";
import { getContractAddress } from "../../utils/getDeployData";
import { getChainId, getLzChainId } from "../../utils/envUtils";
import { writeToProposal } from "../../utils/writeProposal";

addArgvType("boolean", "multisig");

// current file name
const method_name = "addRelayLzChainMapping";

export function addRelayLzChainMappingWithArgv(argv: any) {
    const required_flags = ["env", "relayNetwork", "addNetwork"]
    checkArgs(method_name, argv, required_flags);
    addRelayLzChainMapping(argv.env, argv.relayNetwork, argv.addNetwork, argv.broadcast, argv.simulate, argv.multisig);
}

export function addRelayLzChainMapping(env: string, relayNetwork: string, addNetwork: string, broadcast: boolean, simulate: boolean, multisig: boolean = false) {
    set_env_var(method_name, "env", env);
    set_env_var(method_name, "relayNetwork", relayNetwork);
    set_env_var(method_name, "addNetwork", addNetwork);
    if (multisig) {
        // get relay address
        const relayAddress = getContractAddress(env, relayNetwork, "CCRelay", true);
        const value = "0";
        const method = "addChainIdMapping(uint256,uint16)";
        const params = [getChainId(addNetwork).toString(),  getLzChainId(addNetwork).toString()];
        const filename = "addRelayLzChainMapping";
        writeToProposal(filename, env, relayNetwork, relayAddress, value, method, params);

    } else {
        foundry_wrapper(method_name, broadcast, simulate);
    }

}

addOperation(method_name, addRelayLzChainMappingWithArgv);
