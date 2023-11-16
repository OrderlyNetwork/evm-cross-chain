import { addOperation } from "../utils/config";
import { set_env_var, foundry_wrapper } from "../foundry";
import { checkArgs } from "../helper";
import { setupDeployJson } from "../utils/setupDeployJson";
import { deployRelay } from "./relay/deployRelay";
import { generalMethod } from "./generalMethod";
import { transferNativeToken } from "./transferNativeToken";
import { transferNativeTokenToRelay } from "./relay/transferNativeTokenToRelay";
import { deployCCManager } from "./ccmanager/deployCCManager";
import { addRelayLzChainMapping } from "./relay/addRelayLzChainMapping";
import { setCrossChainFee } from "./relay/setCrossChainFee";
import { setCrossChainFeeAll } from "./relay/setCrossChainFeeAll";
import { setRelayTrustedRemote } from "./relay/setRelayTrustedRemote";
import { setCCManagerChainId } from "./ccmanager/setCCManagerChainId";
import { setCCManagerVault } from "./ccmanager/setCCManagerVault";
import { setCCManagerLedger } from "./ccmanager/setCCManagerLedger";
import { setCCManagerRelay } from "./ccmanager/setCCManagerRelay";
import { setCCManagerTokenDecimal } from "./ccmanager/setCCManagerTokenDecimal";
import { setCCManagerLedgerManager } from "./ccmanager/setCCManagerLedgerManager";
import { setCCManagerOperator } from "./ccmanager/setCCManagerOperator";
import { getDeployData } from "@openzeppelin/hardhat-upgrades/dist/utils/deploy-impl";
import { getContractAddress } from "../utils/getDeployData";

// current file name
const method_name = "addVaultCCService";

export function addVaultCCServiceWithArgv(argv: any) {
    const required_flags = ["env", "vaultNetwork", "ledgerNetwork", "initEther"];
    checkArgs(method_name, argv, required_flags);
    // print all args
    console.log("argv: ", argv);
    addVaultCCService(argv.env, argv.vaultNetwork, argv.ledgerNetwork, argv.connectVault, argv.initEther, argv.broadcast, argv.simulate);
}

/// TODO
export function addVaultCCService(env: string, vaultNetwork: string, ledgerNetwork: string, connectVault: boolean, initEther: number, broadcast: boolean, simulate: boolean) {

    // 1. deploy relay
    deployRelay(env, vaultNetwork, broadcast, simulate);

    // 2. deploy cc manager
    deployCCManager(env, vaultNetwork, "vault", broadcast, simulate);

    // 3. setup relay
    // 3.1 set chain id
    generalMethod("setRelayChainId", env, vaultNetwork, broadcast, simulate);
    // 3.2 chain id mapping
    addRelayLzChainMapping(env, vaultNetwork, vaultNetwork, broadcast, simulate);
    addRelayLzChainMapping(env, vaultNetwork, ledgerNetwork, broadcast, simulate);

    // 3.3 layerzero fee
    setCrossChainFeeAll(env, vaultNetwork, broadcast, simulate);

    // 3.4 layerzero trusted remote
    setRelayTrustedRemote(env, vaultNetwork, ledgerNetwork, broadcast, simulate);

    // 3.5 configure cross-chain manager
    generalMethod("setRelayManager", env, vaultNetwork, broadcast, simulate);

    // 3.6 transfer native token to relay(later, a lot of token required)
    const vaultRelayAddress = getContractAddress(env, vaultNetwork, "CCRelay", true);
    transferNativeToken(vaultNetwork, vaultRelayAddress, initEther, broadcast, simulate);

    // 4. setup cc manager
    // 4.1 set chain id
    setCCManagerChainId(env, vaultNetwork, broadcast, simulate);
    // 4.2 set vault 
    if (connectVault) {
        setCCManagerVault(env, vaultNetwork, broadcast, simulate);
    }
    // 4.3 set relay
    setCCManagerRelay(env, vaultNetwork, broadcast, simulate);

    // 4.4 set ledger manager
    setCCManagerLedgerManager(env, vaultNetwork, ledgerNetwork, broadcast, simulate);


    // 5. update settings on ledger side
    // 5.1 set token decimal
    setCCManagerTokenDecimal(env, ledgerNetwork, vaultNetwork, broadcast, simulate);
    // 5.2 set trusted remote
    setRelayTrustedRemote(env, ledgerNetwork, vaultNetwork, broadcast, simulate);
    // 5.3 add lz chain mapping
    addRelayLzChainMapping(env, ledgerNetwork, vaultNetwork, broadcast, simulate);

}

addOperation(method_name, addVaultCCServiceWithArgv);
