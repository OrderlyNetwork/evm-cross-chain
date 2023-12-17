// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "evm-cross-chain/script/baseScripts/BaseScript.s.sol";
import "evm-cross-chain/script/baseScripts/ConfigHelper.s.sol";
import "evm-cross-chain/script/baseScripts/CCManagerHelper.s.sol";
import "evm-cross-chain/contracts/VaultCrossChainManagerUpgradeable.sol";
import "evm-cross-chain/contracts/LedgerCrossChainManagerUpgradeable.sol";
import "evm-cross-chain/contracts/CrossChainManagerProxy.sol";
import "evm-cross-chain/contracts/interface/ICrossChainManager.sol";

contract PrintCCManagerLedger is BaseScript, ConfigHelper, CCManagerHelper {
    using StringUtils for string;

    function run() external {
        string memory env = vm.envString("FS_printCCManagerLedger_env");
        string memory network = vm.envString("FS_printCCManagerLedger_network");
        CCManagerDeployData memory managerData = getCCManagerDeployData(env, network);

        vmSelectRpcAndBroadcast(network);

        LedgerCrossChainManagerUpgradeable ledgerManager =
            LedgerCrossChainManagerUpgradeable(payable(managerData.proxy));

        // print everything on ledgerManager
        // print chain Id
        console.log("chainId: ", ledgerManager.chainId());
        // print ledger address
        console.log("ledger address: ", address(ledgerManager.ledger()));
        // print relay address
        console.log("relay address: ", address(ledgerManager.crossChainRelay()));
        // print token decimal
        TokenDecimalConfig[] memory tokenConfigs = getTokenDecimals(env, network);
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
        // print operator
        console.log("operator: ", address(ledgerManager.operatorManager()));

        vm.stopBroadcast();
    }
}
