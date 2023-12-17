export const foundry_script_folder = "script/foundry_scripts";
export const relay_deploy_json = "config/cross-chain-relay.json";
export const ccmanager_deploy_json = "config/cross-chain-manager.json";
export const cc_gas_json = "config/cross-chain-method-gas.json";
export const decimal_config_json = "config/token-decimals.json";

export const CC_RELAY_CONTRACT_PATH = "contracts/CrossChainRelayUpgradeable.sol";
export const CC_RELAY_PROXY_CONTRACT_PATH = "contracts/CrossChainRelayProxy.sol";
export const LEDGER_CC_MANAGER_CONTRACT_PATH = "contracts/LedgerCrossChainManagerUpgradeable.sol";
export const VAULT_CC_MANAGER_CONTRACT_PATH = "contracts/VaultCrossChainManagerUpgradeable.sol";
export const CC_MANAGER_PROXY_CONTRACT_PATH = "contracts/CrossChainManagerProxy.sol";

export type ContractMetaKey = 'CCRelay' | 'LedgerCCManager' | 'VaultCCManager';

export interface ContractInfo {
    path: string;
    name: string;
    deployJson: string;
    role: string;
    proxyName: string;
    proxyPath: string;
}

export type ContractMeta = {
    [key in ContractMetaKey]: ContractInfo;
}

export const CONTRACT_META: ContractMeta = {
    "CCRelay": {
        "path": CC_RELAY_CONTRACT_PATH,
        "name": "CrossChainRelayUpgradeable",
        "proxyPath": CC_RELAY_PROXY_CONTRACT_PATH,
        "proxyName": "CrossChainRelayProxy",
        "deployJson": relay_deploy_json,
        "role": "relay"
    },
    "LedgerCCManager": {
        "path": LEDGER_CC_MANAGER_CONTRACT_PATH,
        "name": "LedgerCrossChainManagerUpgradeable",
        "proxyPath": CC_MANAGER_PROXY_CONTRACT_PATH,
        "proxyName": "CrossChainManagerProxy",
        "deployJson": ccmanager_deploy_json,
        "role": "manager"
    },
    "VaultCCManager": {
        "path": VAULT_CC_MANAGER_CONTRACT_PATH,
        "name": "VaultCrossChainManagerUpgradeable",
        "proxyPath": CC_MANAGER_PROXY_CONTRACT_PATH,
        "proxyName": "CrossChainManagerProxy",
        "deployJson": ccmanager_deploy_json,
        "role": "manager"
    }
}

export const compilerVersionMap = {
    "0.8.17": "v0.8.17+commit.8df45f5f",
    "0.8.18": "v0.8.18+commit.87f61d96",
    "0.8.19": "v0.8.19+commit.7dd6d404",
    "0.8.20": "v0.8.20+commit.a1b79de6",
}