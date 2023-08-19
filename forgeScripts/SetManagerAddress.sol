// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../baseScripts/BaseScript.s.sol";
import "../contracts/CrossChainRelayUpgradeable.sol";

contract SetManagerAddress is BaseScript {
    function run() external {
        string memory network = vm.envString("CURRENT_NETWORK");
        address relayProxyAddress = getRelayProxyAddress(network);
        address managerProxyAddress = getManagerProxyAddress(network);
        vm.startBroadcast(getPrivateKey(network));

        CrossChainRelayUpgradeable relay = CrossChainRelayUpgradeable(payable(relayProxyAddress));
        relay.setManagerAddress(managerProxyAddress);
        vm.stopBroadcast();
    }

}
