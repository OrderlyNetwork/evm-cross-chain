// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "evm-cross-chain/script/foundry_scripts/baseScripts/BaseScript.s.sol";
import "evm-cross-chain/script/foundry_scripts/baseScripts/ConfigHelper.s.sol";
import "evm-cross-chain/script/foundry_scripts/baseScripts/CCManagerHelper.s.sol";
import "evm-cross-chain/contracts/VaultCrossChainManagerUpgradeable.sol";
import "evm-cross-chain/contracts/LedgerCrossChainManagerUpgradeable.sol";
import "evm-cross-chain/contracts/OrderlyProxy.sol";
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

        vmSelectRpcAndBroadcast(env, network);

        LedgerCrossChainManagerUpgradeable ledgerManager =
            LedgerCrossChainManagerUpgradeable(payable(managerData.proxy));

        // print token decimal
        TokenDecimalConfig memory tokenConfig = getUsdcDecimal();
        console.log("token: ", tokenConfig.name);
        console.log("tokenHash: ");
        console.logBytes32(tokenConfig.tokenHash);
        console.log("tokenDecimal: ", tokenConfig.decimals);
        console.log(
            "in contract decimal: ",
            ledgerManager.tokenDecimalMapping(tokenConfig.tokenHash, getChainId(network))
        );

        vm.stopBroadcast();
    }
}
