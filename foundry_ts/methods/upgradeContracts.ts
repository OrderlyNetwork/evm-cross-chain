import { set_env_var, foundry_wrapper } from "../foundry";
import * as ethers from "ethers";
import { checkArgs } from "../helper";
import { addOperation, addArgvType } from "../utils/config";
import { getExplorerApiUrl, getChainId, getEtherscanApiKey } from "../utils/envUtils";
import { exec } from "shelljs";
import { getContractAddress } from "../utils/getDeployData";
import { CONTRACT_META, ContractMetaKey, compilerVersionMap } from "../utils/const";
import { upgradeRelay } from "./relay/upgradeRelay";
import { getAllNetworks, getEnvConfig } from "../utils/getEnvConfig";
import { upgradeCCManager } from "./ccmanager/upgradeCCManager";

// current file name
const method_name = "upgradeContracts";

addArgvType("string", "constructorArgs")
addArgvType("boolean", "relay")
addArgvType("boolean", "ccmanager")

export function upgradeContractsWithArgv(argv: any) {
    const required_flags = ["env", "networks", "relay", "ccmanager"];
    checkArgs(method_name, argv, required_flags);
    upgradeContracts(argv.env, argv.networks, argv.relay, argv.ccmanager, argv.broadcast, argv.simulate);
}

export function upgradeContracts(env: string, networks: string, relay: boolean, ccmanager: boolean, broadcast: boolean, simulate: boolean) {
    let networkList;
    if (networks == "all") {
        networkList = getAllNetworks(env);
    } else {
        networkList = networks.split(",");
    }

    for (const network of networkList) {
        const role = getEnvConfig(env, network);
        if (relay) {
            upgradeRelay(env, network, broadcast, simulate);
        }
        if (ccmanager) {
            upgradeCCManager(env, network, role, broadcast, simulate);
        }
    }
}

addOperation(method_name, upgradeContractsWithArgv);

