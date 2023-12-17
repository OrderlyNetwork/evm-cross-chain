// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "evm-cross-chain/script/baseScripts/BaseScript.s.sol";
import "evm-cross-chain/script/baseScripts/ConfigHelper.s.sol";
import "evm-cross-chain/script/baseScripts/CCManagerHelper.s.sol";
import "evm-cross-chain/contracts/VaultCrossChainManagerUpgradeable.sol";
import "evm-cross-chain/contracts/LedgerCrossChainManagerUpgradeable.sol";
import "evm-cross-chain/contracts/CrossChainManagerProxy.sol";
import "evm-cross-chain/contracts/interface/ICrossChainManager.sol";

contract PrintCCManagerTokenDecimal is BaseScript, ConfigHelper, CCManagerHelper {
    using StringUtils for string;

    function run() external {
        string memory env = vm.envString("FS_printCCManagerTokenDecimal_env");
        string memory network = vm.envString("FS_printCCManagerTokenDecimal_network");
        string memory tokenNetwork = vm.envString("FS_printCCManagerTokenDecimal_tokenNetwork");

        // print all
        console.log("[PrintCCManagerTokenDecimal] env: ", env);
        console.log("[PrintCCManagerTokenDecimal] network: ", network);
        console.log("[PrintCCManagerTokenDecimal] tokenNetwork: ", tokenNetwork);

        CCManagerDeployData memory managerData = getCCManagerDeployData(env, network);

        vmSelectRpcAndBroadcast(network);

        LedgerCrossChainManagerUpgradeable ledgerManager =
            LedgerCrossChainManagerUpgradeable(payable(managerData.proxy));

        // print token decimal
        TokenDecimalConfig[] memory tokenConfigs = getTokenDecimals(env, tokenNetwork);
        for (uint256 i = 0; i < tokenConfigs.length; i++) {
            console.log("token: ", tokenConfigs[i].name);
            console.log("tokenHash: ");
            console.logBytes32(tokenConfigs[i].tokenHash);
            console.log("tokenDecimal: ", tokenConfigs[i].decimals);
            console.log(
                "in contract decimal: ",
                ledgerManager.tokenDecimalMapping(tokenConfigs[i].tokenHash, getChainId(network))
            );
        }

        vm.stopBroadcast();
    }
}
