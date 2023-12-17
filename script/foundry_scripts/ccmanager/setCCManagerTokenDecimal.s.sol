// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "evm-cross-chain/script/baseScripts/BaseScript.s.sol";
import "evm-cross-chain/script/baseScripts/ConfigHelper.s.sol";
import "evm-cross-chain/script/baseScripts/CCManagerHelper.s.sol";
import "evm-cross-chain/contracts/VaultCrossChainManagerUpgradeable.sol";
import "evm-cross-chain/contracts/LedgerCrossChainManagerUpgradeable.sol";
import "evm-cross-chain/contracts/CrossChainManagerProxy.sol";
import "evm-cross-chain/contracts/interface/ICrossChainManager.sol";

contract SetCCManagerTokenDecimal is BaseScript, ConfigHelper, CCManagerHelper {
    using StringUtils for string;

    function run() external {
        string memory env = vm.envString("FS_setCCManagerTokenDecimal_env");
        string memory network = vm.envString("FS_setCCManagerTokenDecimal_network");
        string memory tokenNetwork = vm.envString("FS_setCCManagerTokenDecimal_tokenNetwork");

        CCManagerDeployData memory managerData = getCCManagerDeployData(env, network);

        TokenDecimalConfig[] memory tokenDecimals = getTokenDecimals(env, tokenNetwork);

        vmSelectRpcAndBroadcast(network);

        for (uint256 i = 0; i < tokenDecimals.length; i++) {
            setTokenDecimal(
                managerData.proxy, tokenDecimals[i].tokenHash, tokenNetwork, uint128(tokenDecimals[i].decimals)
            );
        }

        vm.stopBroadcast();
    }
}
