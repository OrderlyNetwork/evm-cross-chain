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

// current file name
const method_name = "deployAndSetupAnEnv";

export function deployAndSetupAnEnvWithArgv(argv: any) {
    const required_flags = ["env", "vaultNetwork", "ledgerNetwork", "initEther"];
    checkArgs(method_name, argv, required_flags);
    deployAndSetupAnEnv(argv.env, argv.vaultNetwork, argv.ledgerNetwork, argv.initEther, argv.broadcast, argv.simulate);
}

/// TODO
export function deployAndSetupAnEnv(env: string, vaultNetwork: string, ledgerNetwork: string, initEther: number, broadcast: boolean, simulate: boolean) {

    const networkList = [vaultNetwork, ledgerNetwork];
    // 1. deploy relay
    deployRelay(env, vaultNetwork, broadcast, simulate);
    deployRelay(env, ledgerNetwork, broadcast, simulate);

    // 2. deploy cc manager
    deployCCManager(env, vaultNetwork, "vault", broadcast, simulate);
    deployCCManager(env, ledgerNetwork, "ledger", broadcast, simulate);

    // 3. setup relay
    // 3.1 set chain id
    generalMethod("setRelayChainId", env, vaultNetwork, broadcast, simulate);
    generalMethod("setRelayChainId", env, ledgerNetwork, broadcast, simulate);
    // 3.2 chain id mapping
    addRelayLzChainMapping(env, vaultNetwork, vaultNetwork, broadcast, simulate);
    addRelayLzChainMapping(env, vaultNetwork, ledgerNetwork, broadcast, simulate);
    addRelayLzChainMapping(env, ledgerNetwork, vaultNetwork, broadcast, simulate);
    addRelayLzChainMapping(env, ledgerNetwork, ledgerNetwork, broadcast, simulate);

    // 3.3 layerzero fee
    setCrossChainFeeAll(env, vaultNetwork, "", broadcast, simulate);
    setCrossChainFeeAll(env, ledgerNetwork, "", broadcast, simulate);

    // 3.4 layerzero trusted remote
    setRelayTrustedRemote(env, vaultNetwork, ledgerNetwork, broadcast, simulate);
    setRelayTrustedRemote(env, ledgerNetwork, vaultNetwork, broadcast, simulate);

    // 3.5 configure cross-chain manager
    generalMethod("setRelayManager", env, vaultNetwork, broadcast, simulate);
    generalMethod("setRelayManager", env, ledgerNetwork, broadcast, simulate);

    // 3.6 transfer native token to relay(later, a lot of token required)

    // 4. setup cc manager
    // 4.1 set chain id
    setCCManagerChainId(env, vaultNetwork, broadcast, simulate);
    setCCManagerChainId(env, ledgerNetwork, broadcast, simulate);
    // 4.2 set vault & ledger
    setCCManagerVault(env, vaultNetwork, broadcast, simulate);
    setCCManagerLedger(env, ledgerNetwork, broadcast, simulate);
    // 4.3 set relay
    setCCManagerRelay(env, vaultNetwork, broadcast, simulate);
    setCCManagerRelay(env, ledgerNetwork, broadcast, simulate);

    // 4.4 set ledger manager
    setCCManagerLedgerManager(env, vaultNetwork, ledgerNetwork, broadcast, simulate);

    // 4.5 set Token Decimal (later, require other project's info)
    setCCManagerTokenDecimal(env, ledgerNetwork, ledgerNetwork, broadcast, simulate);
    setCCManagerTokenDecimal(env, ledgerNetwork, vaultNetwork, broadcast, simulate);

    // 4.6 set Operator (later, require other project's info)
    setCCManagerOperator(env, ledgerNetwork, broadcast, simulate);


}

addOperation(method_name, deployAndSetupAnEnvWithArgv);
