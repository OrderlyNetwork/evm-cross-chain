// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "evm-cross-chain/script/foundry_scripts/baseScripts/BaseScript.s.sol";
import "evm-cross-chain/script/foundry_scripts/baseScripts/ConfigHelper.s.sol";
import "evm-cross-chain/script/foundry_scripts/baseScripts/CCManagerHelper.s.sol";
import "evm-cross-chain/contracts/VaultCrossChainManagerUpgradeable.sol";
import "evm-cross-chain/contracts/LedgerCrossChainManagerUpgradeable.sol";
import "evm-cross-chain/contracts/OrderlyProxy.sol";
import "evm-cross-chain/contracts/interface/ICrossChainManager.sol";

contract SetCCManagerTokenDecimal is BaseScript, ConfigHelper, CCManagerHelper {
    using StringUtils for string;

    function run() external {
        string memory env = vm.envString("FS_setCCManagerTokenDecimal_env");
        string memory network = vm.envString("FS_setCCManagerTokenDecimal_network");
        string memory tokenNetwork = vm.envString("FS_setCCManagerTokenDecimal_tokenNetwork");

        CCManagerDeployData memory managerData = getCCManagerDeployData(env, network);

        TokenDecimalConfig memory tokenDecimal = getUsdcDecimal();

        vmSelectRpcAndBroadcast(env, network);

        setTokenDecimal(
            managerData.proxy, tokenDecimal.tokenHash, tokenNetwork, uint128(tokenDecimal.decimals)
        );

        vm.stopBroadcast();
    }
}
