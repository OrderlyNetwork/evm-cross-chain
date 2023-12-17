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
import { verifyContract } from "./verifyContract";

// current file name
const method_name = "addVaultCCService";

export function addVaultCCServiceWithArgv(argv: any) {
    const required_flags = ["env", "vaultNetwork", "ledgerNetwork", "initEther"];
    checkArgs(method_name, argv, required_flags);
    // print all args
    console.log("argv: ", argv);
    addVaultCCService(argv.env, argv.vaultNetwork, argv.ledgerNetwork, argv.connectVault, argv.initEther, argv.broadcast, argv.simulate, argv.skip);
}

/// TODO
export function addVaultCCService(env: string, vaultNetwork: string, ledgerNetwork: string, connectVault: boolean, initEther: number, broadcast: boolean, simulate: boolean, skip: number) {

    // default compiler version
    const compilerVersion = "0.8.19";
    if (!skip) {
        skip = -1;
    }
    let operationCnt = 0;

    // 1. deploy relay
    if (operationCnt > skip) { // 0
        deployRelay(env, vaultNetwork, broadcast, simulate);
    }
    operationCnt++;

    // 2. deploy cc manager
    if (operationCnt > skip) { // 1
        deployCCManager(env, vaultNetwork, "vault", broadcast, simulate);
    }
    operationCnt++;

    // 3. setup relay
    // 3.1 set chain id
    if (operationCnt > skip) { // 2
        generalMethod("setRelayChainId", env, vaultNetwork, broadcast, simulate);
    }
    operationCnt++;
    // 3.2 chain id mapping
    if (operationCnt > skip) { // 3
        addRelayLzChainMapping(env, vaultNetwork, vaultNetwork, broadcast, simulate);
    }
    operationCnt++;
    if (operationCnt > skip) { // 4
        addRelayLzChainMapping(env, vaultNetwork, ledgerNetwork, broadcast, simulate);
    }
    operationCnt++;

    // 3.3 layerzero fee
    if (operationCnt > skip) { // 5
        setCrossChainFeeAll(env, vaultNetwork, "", broadcast, simulate);
    }
    operationCnt++;

    // 3.4 layerzero trusted remote
    if (operationCnt > skip) { // 6
        setRelayTrustedRemote(env, vaultNetwork, ledgerNetwork, broadcast, simulate);
    }
    operationCnt++;

    // 3.5 configure cross-chain manager
    if (operationCnt > skip) { // 7
        generalMethod("setRelayManager", env, vaultNetwork, broadcast, simulate);
    }
    operationCnt++;

    // 3.6 transfer native token to relay(later, a lot of token required)
    const vaultRelayAddress = getContractAddress(env, vaultNetwork, "CCRelay", true);
    if (operationCnt > skip) { // 8
        transferNativeToken(vaultNetwork, vaultRelayAddress, initEther, broadcast, simulate);
    }
    operationCnt++;

    // 4. setup cc manager
    // 4.1 set chain id
    if (operationCnt > skip) { // 9
        setCCManagerChainId(env, vaultNetwork, broadcast, simulate);
    }
    operationCnt++;
    // 4.2 set vault 
    if (connectVault) {
        if (operationCnt > skip) { // 10
            setCCManagerVault(env, vaultNetwork, broadcast, simulate);
        }
    }
    operationCnt++;
    // 4.3 set relay
    if (operationCnt > skip) { // 11
        setCCManagerRelay(env, vaultNetwork, broadcast, simulate);
    }
    operationCnt++;

    // 4.4 set ledger manager
    if (operationCnt > skip) { // 12
        setCCManagerLedgerManager(env, vaultNetwork, ledgerNetwork, broadcast, simulate);
    }
    operationCnt++;


    // 5. update settings on ledger side
    // 5.1 set token decimal
    if (operationCnt > skip) { // 13
        setCCManagerTokenDecimal(env, ledgerNetwork, vaultNetwork, broadcast, simulate);
    }
    operationCnt++;
    // 5.2 set trusted remote
    if (operationCnt > skip) { // 14
        setRelayTrustedRemote(env, ledgerNetwork, vaultNetwork, broadcast, simulate);
    }
    operationCnt++;
    // 5.3 add lz chain mapping
    if (operationCnt > skip) { // 15
        addRelayLzChainMapping(env, ledgerNetwork, vaultNetwork, broadcast, simulate);
    }
    operationCnt++;

    // 6. verify contracts
    if (operationCnt > skip) { // 16
        verifyContract(env, vaultNetwork, "CCRelay", true, undefined, compilerVersion, simulate);
        verifyContract(env, vaultNetwork, "VaultCCManager", true, undefined, compilerVersion, simulate);
        verifyContract(env, vaultNetwork, "CCRelay", false, undefined, compilerVersion, simulate);
        verifyContract(env, vaultNetwork, "VaultCCManager", false, undefined, compilerVersion, simulate);
    }

}

addOperation(method_name, addVaultCCServiceWithArgv);
