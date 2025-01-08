// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "evm-cross-chain/script/foundry_scripts/baseScripts/BaseScript.s.sol";
import "evm-cross-chain/script/foundry_scripts/baseScripts/ConfigHelper.s.sol";
import "evm-cross-chain/script/foundry_scripts/baseScripts/CCManagerHelper.s.sol";
import "evm-cross-chain/contracts/VaultCrossChainManagerUpgradeable.sol";
import "evm-cross-chain/contracts/LedgerCrossChainManagerUpgradeable.sol";
import "evm-cross-chain/contracts/OrderlyProxy.sol";
import "evm-cross-chain/contracts/interface/ICrossChainManager.sol";

contract PrintCCManagerLedger is BaseScript, ConfigHelper, CCManagerHelper {
    using StringUtils for string;

    function run() external {
        string memory env = vm.envString("FS_printCCManagerLedger_env");
        string memory network = vm.envString("FS_printCCManagerLedger_network");
        CCManagerDeployData memory managerData = getCCManagerDeployData(env, network);

        vmSelectRpcAndBroadcast(env, network);

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
        TokenDecimalConfig memory tokenConfig = getUsdcDecimal();
        console.log("token: ", tokenConfig.name);
        console.log("tokenHash: ");
        console.logBytes32(tokenConfig.tokenHash);
        console.log("tokenDecimal: ", tokenConfig.decimals);
        console.log(
            "in contract decimal: ",
            ledgerManager.tokenDecimalMapping(tokenConfig.tokenHash, getChainId(network))
        );
        // print operator
        console.log("operator: ", address(ledgerManager.operatorManager()));

        vm.stopBroadcast();
    }
}
