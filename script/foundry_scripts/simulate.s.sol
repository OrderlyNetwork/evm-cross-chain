// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "evm-cross-chain/script/baseScripts/BaseScript.s.sol";
import "evm-cross-chain/script/baseScripts/ConfigHelper.s.sol";
import "evm-cross-chain/contracts/CrossChainRelayUpgradeable.sol";
import "evm-cross-chain/contracts/CrossChainRelayProxy.sol";
import "evm-cross-chain/contracts/layerzero/interfaces/ILayerZeroEndpoint.sol";

contract Simulate is BaseScript, ConfigHelper {
    using StringUtils for string;

    function run() external {
        string memory network = vm.envString("FS_simulate_network");
        address to = vm.envAddress("FS_simulate_to");
        bytes memory data = vm.envBytes("FS_simulate_data");

        vmSelectRpcAndBroadcast(network);

        console.log("simulate...");
        // call on address with raw call data
        (bool success,) = to.call(data);
        require(success, "call failed");

        vm.stopBroadcast();
    }
}
