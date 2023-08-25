// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../baseScripts/BaseScript.s.sol";
import "../baseScripts/ConfigHelper.s.sol";
import "../contracts/LedgerCrossChainManagerUpgradeable.sol";
import "../contracts/CrossChainManagerProxy.sol";
import "../contracts/VaultCrossChainManagerUpgradeable.sol";

contract SendCCTest is BaseScript, ConfigHelper {
    using StringUtils for string;

    // variable order must be alphabetical
    struct SendCCTestConfig {
        string env;
        string ledgerNetwork;
        string vaultNetwork;
    }

    function run() external {
        bytes memory encodedData = getConfigFileData("SEND_CC_TEST_CONFIG_FILE");
        SendCCTestConfig memory config = abi.decode(encodedData, (SendCCTestConfig));
        console.log("vaultNetwork: ", config.vaultNetwork);
        console.log("ledgerNetwork: ", config.ledgerNetwork);
        console.log("env: ", config.env);

        CCManagerDeployData memory ledgerDeployData = getCCManagerDeployData(config.env, config.ledgerNetwork);

        LedgerCrossChainManagerUpgradeable ledger = LedgerCrossChainManagerUpgradeable(payable(ledgerDeployData.proxy));

        uint256 dstChainId = getChainId(config.vaultNetwork);

        vmSelectRpcAndBroadcast(config.ledgerNetwork);

        ledger.sendTestWithdraw(dstChainId);

        vm.stopBroadcast();
    }
}
