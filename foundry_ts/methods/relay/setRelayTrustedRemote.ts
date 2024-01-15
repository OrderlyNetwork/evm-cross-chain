import { addArgvType, addOperation } from "../../utils/config";
import { relay_deploy_json } from "../../utils/const";
import { set_env_var, foundry_wrapper } from "../../foundry";
import { checkArgs } from "../../helper";
import { getContractAddress } from "../../utils/getDeployData";
import { ethers } from "ethers";
import { getLzChainId } from "../../utils/envUtils";
import { writeToProposal } from "../../utils/writeProposal";

addArgvType("boolean", "multisig");

// current file name
const method_name = "setRelayTrustedRemote";

export function setRelayTrustedRemoteWithArgv(argv: any) {
    const required_flags = ["env", "srcNetwork", "dstNetwork"];
    checkArgs(method_name, argv, required_flags);
    setRelayTrustedRemote(argv.env, argv.srcNetwork, argv.dstNetwork, argv.broadcast, argv.simulate, argv.multisig);
}

export function setRelayTrustedRemote(env: string, srcNetwork: string, dstNetwork: string, broadcast: boolean, simulate: boolean, multisig: boolean = false) {

    if (multisig) {
        const relayAddress = getContractAddress(env, srcNetwork, "CCRelay", true);
        const dstRelayAddress = getContractAddress(env, dstNetwork, "CCRelay", true);
        const filename = "setRelayTrustedRemote";
        const value = "0";
        const method = "setTrustedRemote(uint16,bytes)";
        // encode packed bytes dstRelayAddress, relayAddress
        const path = ethers.solidityPacked(["address", "address"], [dstRelayAddress, relayAddress]);
        const params = [getLzChainId(dstNetwork).toString(), path];
        writeToProposal(filename, env, srcNetwork, relayAddress, value, method, params);
        return;
    }
    
    set_env_var(method_name, "env", env);
    set_env_var(method_name, "srcNetwork", srcNetwork);
    set_env_var(method_name, "dstNetwork", dstNetwork);
    foundry_wrapper(method_name, broadcast, simulate);

}

addOperation(method_name, setRelayTrustedRemoteWithArgv);