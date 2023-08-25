// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../baseScripts/BaseScript.s.sol";
import "../baseScripts/ConfigHelper.s.sol";
import "../contracts/LedgerCrossChainManagerUpgradeable.sol";
import "../contracts/CrossChainManagerProxy.sol";
import "../contracts/VaultCrossChainManagerUpgradeable.sol";

contract SetTokenDecimal is BaseScript, ConfigHelper {
    using StringUtils for string;

    // variable order must be alphabetical
    struct SetTokenDecimalConfig {
        string env;
        string managerNetwork;
        string[] networks;
    }

    function run() external {
        bytes memory encodedData = getConfigFileData("SET_TOKEN_DECIMAL_CONFIG_FILE");
        SetTokenDecimalConfig memory config = abi.decode(encodedData, (SetTokenDecimalConfig));

        vmSelectRpcAndBroadcast(config.managerNetwork);
        CCManagerDeployData memory managerDeployData = getCCManagerDeployData(config.env, config.managerNetwork);

        LedgerCrossChainManagerUpgradeable ledger = LedgerCrossChainManagerUpgradeable(payable(managerDeployData.proxy));

        for (uint256 i = 0; i < config.networks.length; i++) {
            TokenDecimalConfig[] memory tokenDecimalConfigs = getTokenDecimals(config.env, config.networks[i]);
            uint256 chainId = getChainId(config.networks[i]);
            for (uint256 j = 0; j < tokenDecimalConfigs.length; j++) {
                console.log("token name: ", tokenDecimalConfigs[j].name);
                console.log("token hash: ");
                console.logBytes32(tokenDecimalConfigs[j].tokenHash);
                console.log("token decimals: ", tokenDecimalConfigs[j].decimals);
                ledger.setTokenDecimal(
                    tokenDecimalConfigs[j].tokenHash, chainId, uint128(tokenDecimalConfigs[j].decimals)
                );
            }
        }

        vm.stopBroadcast();
    }
}
