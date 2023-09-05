// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../contracts/CrossChainRelayUpgradeable.sol";
import "../contracts/CrossChainRelayProxy.sol";

contract RelayHelper {
    function upgradeRelay(address proxyAddress) internal returns (address) {
        CrossChainRelayUpgradeable newRelay = new CrossChainRelayUpgradeable();
        CrossChainRelayUpgradeable proxy = CrossChainRelayUpgradeable(payable(proxyAddress));
        proxy.upgradeTo(address(newRelay));
        return address(newRelay);
    }

    function deployRelay(address lzEndpoint) internal returns (address, address) {
        CrossChainRelayUpgradeable newRelay = new CrossChainRelayUpgradeable();
        CrossChainRelayProxy proxy = new CrossChainRelayProxy(address(newRelay), bytes(""));
        CrossChainRelayUpgradeable relayUpgradeable = CrossChainRelayUpgradeable(payable(address(proxy)));
        relayUpgradeable.initialize(lzEndpoint);
        return (address(newRelay), address(proxy));
    }
}
