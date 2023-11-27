// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "evm-cross-chain/script/baseScripts/BaseScript.s.sol";
import "evm-cross-chain/script/baseScripts/ConfigHelper.s.sol";
import "../contracts/CrossChainRelayUpgradeable.sol";
import "../contracts/VaultCrossChainManagerUpgradeable.sol";
import "contract-evm/src/library/types/VaultTypes.sol";

contract SetManager is BaseScript, ConfigHelper {
    using StringUtils for string;

    // variable order must be alphabetical
    struct EstimateGasConfig {
        string env;
        string network;
    }

    function run() external {
        bytes memory encodedData = getConfigFileData("ESTIMATE_GAS_CONFIG_FILE");
        EstimateGasConfig memory config = abi.decode(encodedData, (EstimateGasConfig));

        CCManagerDeployData memory managerData = getCCManagerDeployData(config.env, config.network);

        VaultCrossChainManagerUpgradeable manager = VaultCrossChainManagerUpgradeable(payable(managerData.proxy));

        // bytes32 accountId;
        // address userAddress;
        // bytes32 brokerHash;
        // bytes32 tokenHash;
        // uint128 tokenAmount;
        // uint64 depositNonce; // deposit nonce
        VaultTypes.VaultDeposit memory data = VaultTypes.VaultDeposit({
            accountId: bytes32(0),
            userAddress: address(0),
            brokerHash: bytes32(0),
            tokenHash: bytes32(0),
            tokenAmount: 0,
            depositNonce: 0
        });

        vmSelectRpcAndBroadcast(config.network);

        uint256 gas = manager.getDepositFee(data);
        manager.deposit(data);

        vm.stopBroadcast();

        console.log("gas: ", gas);
    }
}
