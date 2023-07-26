// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

import "./BaseScript.s.sol";
import "../contracts/CrossChainRelayUpgradeable.sol";

contract RelayRetry is BaseScript {
    function run() external {
        string memory network = vm.envString("CURRENT_NETWORK");
        uint256 pk = getPrivateKey(network);
        adddress accountAddress = vm.addr(pk);
        vm.startBroadcast(pk);
        withdraw(network, accountAddress);
        vm.stopBroadcast();
    }

    function withdraw(string memory network, address to) internal {
        address relayProxy = getRelayProxyAddress(network);
        CrossChainRelayUpgradeable relayProxyInstance = CrossChainRelayUpgradeable(payable(relayProxy));

        // balance of contract
        uint256 balance = relayProxy.balance;

        // withdraw
        relayProxyInstance.withdrawNativeToken(to, balance);

    }
}
