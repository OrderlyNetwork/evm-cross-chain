import { CONTRACT_META, ContractMetaKey } from "./const";

export function getContractAddress(env: string, network: string, contract: string, proxy: boolean): string {
    const contractDeployJsonPath = CONTRACT_META[contract as ContractMetaKey].deployJson;
    const role = CONTRACT_META[contract as ContractMetaKey].role;
    const fs = require('fs');
    const json = JSON.parse(fs.readFileSync(contractDeployJsonPath, 'utf8'));
    if (proxy) {
        return json[env][network]["proxy"]
    }
    return json[env][network][role]
}