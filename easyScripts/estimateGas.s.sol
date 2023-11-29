// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "evm-cross-chain/script/baseScripts/BaseScript.s.sol";
import "evm-cross-chain/script/baseScripts/ConfigHelper.s.sol";
import "../contracts/CrossChainRelayUpgradeable.sol";
import "../contracts/CrossChainRelayProxy.sol";
import "../contracts/utils/OrderlyCrossChainMessage.sol";

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

        RelayDeployData memory relayData = getRelayDeployData(config.env, config.network);

        console.log("relayData.proxy: ", relayData.proxy);

        CrossChainRelayUpgradeable relay = CrossChainRelayUpgradeable(payable(relayData.proxy));

        OrderlyCrossChainMessage.MessageV1 memory data = OrderlyCrossChainMessage.MessageV1({
            method: uint8(OrderlyCrossChainMessage.CrossChainMethod.Deposit),
            option: uint8(OrderlyCrossChainMessage.CrossChainOption.LayerZero),
            payloadDataType: uint8(OrderlyCrossChainMessage.PayloadDataType.VaultTypesVaultDeposit),
            srcCrossChainManager: address(0),
            dstCrossChainManager: address(0),
            srcChainId: 0,
            dstChainId: 4460
        });

        bytes memory payload = abi.encode(data);

        vmSelectRpcAndBroadcast(config.network);

        uint256 gas = relay.estimateGasFee(data, payload);

        vm.stopBroadcast();

        console.log("gas: ", gas);
    }
}
