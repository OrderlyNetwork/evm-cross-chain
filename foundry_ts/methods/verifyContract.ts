import { set_env_var, foundry_wrapper } from "../foundry";
import * as ethers from "ethers";
import { checkArgs } from "../helper";
import { addOperation, addArgvType } from "../utils/config";
import { getExplorerApiUrl, getChainId, getEtherscanApiKey } from "../utils/envUtils";
import { exec } from "shelljs";
import { getContractAddress } from "../utils/getDeployData";
import { CONTRACT_META, ContractMetaKey, compilerVersionMap } from "../utils/const";

// current file name
const method_name = "verifyContract";

addArgvType("string", "constructorArgs")

export function verifyContractWithArgv(argv: any) {
    const required_flags = ["env", "network", "contract"];
    checkArgs(method_name, argv, required_flags);
    verifyContract(argv.env, argv.network, argv.contract, argv.proxy as boolean, argv.constructorArgs, argv.compilerVersion, argv.simulate);
}

export function verifyContract(env: string, network: string, contract: string, proxy: boolean, constructorArgs: string | undefined, compilerVeresion: string, simulate: boolean) {
    let blockscout = false;
    if (network === "orderlyop" || network === "orderlymain") {
        blockscout = true;
    }

    const explorerApiUrl = getExplorerApiUrl(network);
    const chainId = getChainId(network);
    const contractAddress = getContractAddress(env, network, contract, proxy); 
    const implementationAddress = getContractAddress(env, network, contract, false);
    let contractPath;
    if (proxy) {
        contractPath = CONTRACT_META[contract as ContractMetaKey].proxyPath + ":" + CONTRACT_META[contract as ContractMetaKey].proxyName;
    } else {
        contractPath = CONTRACT_META[contract as ContractMetaKey].path + ":" + CONTRACT_META[contract as ContractMetaKey].name;
    }

    let cmd = "";

    // run command
    if (blockscout) {
        // forge verify-contract 0xd1c426290eaf9C16dC55e9bd10b624abb827DEef contracts/LedgerCrossChainManagerUpgradeable.sol:LedgerCrossChainManagerUpgradeable --chain-id 291 --verifier-url https://explorer.orderly.networ/api\? --verifier blockscout 
        cmd = (`forge verify-contract ${contractAddress} ${contractPath} --chain-id ${chainId} --verifier-url ${explorerApiUrl} --verifier blockscout`);


    } else {
        const etherscanApiKey = getEtherscanApiKey(network);
        // forge verify-contract <contract-address> contracts/CrossChainRelayUpgradeable.sol:CrossChainRelayUpgradeable --chain-id 421613 --verifier-url https://api-goerli.arbiscan.io/api -e <etherscan-api-key>
        if (proxy && !constructorArgs) {
            // using ethers abi encode, implementaion address and bytes("")
            const abi = new ethers.AbiCoder();
            constructorArgs = abi.encode(["address", "bytes"], [implementationAddress, "0x"]);
        }
        const constructorArgsFlag = constructorArgs ? `--constructor-args ${constructorArgs}` : "";
        const compilerVersionFlag = compilerVeresion ? `--compiler-version ${compilerVersionMap[compilerVeresion as keyof typeof compilerVersionMap]}` : "";
        cmd = (`forge verify-contract ${contractAddress} ${contractPath} --chain-id ${chainId} --verifier-url ${explorerApiUrl} -e ${etherscanApiKey} ${constructorArgsFlag} ${compilerVersionFlag}`)
    }
    console.log(cmd);
    if (!simulate) {
        exec(cmd);
    }

}

addOperation(method_name, verifyContractWithArgv);

