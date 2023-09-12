// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../contracts/CrossChainRelayUpgradeable.sol";
import "../contracts/CrossChainRelayProxy.sol";
import "./BaseScript.s.sol";
import "./OperationHelper.s.sol";

contract RelayHelper is BaseScript, OperationHelper {
    function upgradeRelay(address proxyAddress) internal returns (address) {
        CrossChainRelayUpgradeable newRelay = new CrossChainRelayUpgradeable();
        CrossChainRelayUpgradeable proxy = CrossChainRelayUpgradeable(payable(proxyAddress));
        proxy.upgradeTo(address(newRelay));
        return address(newRelay);
    }

    function deployRelay(address lzEndpoint) internal returns (address, address) {
        CrossChainRelayUpgradeable relay = new CrossChainRelayUpgradeable();
        CrossChainRelayProxy proxy = new CrossChainRelayProxy(address(relay), bytes(""));
        CrossChainRelayUpgradeable relayUpgradeable = CrossChainRelayUpgradeable(payable(address(proxy)));
        relayUpgradeable.initialize(lzEndpoint);
        return (address(relay), address(proxy));
    }

    function addRelayLzChainMapping(address proxyAddress, string memory network) internal {
        CrossChainRelayUpgradeable relay = CrossChainRelayUpgradeable(payable(proxyAddress));
        console.log("[addRelayLzChainMapping] add chain id mapping: ");
        console.log("[addRelayLzChainMapping] chainId: ", getChainId(network));
        console.log("[addRelayLzChainMapping] lzChainId: ", getLzChainId(network));
        relay.addChainIdMapping(getChainId(network), getLzChainId(network));
    }

    function setRelayLzTrustedRemote(address srcProxy, address dstProxy, string memory dstNetwork) internal {
        uint16 lzChainId = getLzChainId(dstNetwork);
        CrossChainRelayUpgradeable relay = CrossChainRelayUpgradeable(payable(srcProxy));
        console.log("[setRelayLzTrustedRemote] set trusted remote: ");
        console.log("[setRelayLzTrustedRemote] dstProxy: ", dstProxy);
        console.log("[setRelayLzTrustedRemote] srcProxy: ", srcProxy);
        console.log("[setRelayLzTrustedRemote] lzChainId: ", lzChainId);
        bytes memory remoteAndLocal = abi.encodePacked(dstProxy, srcProxy);
        relay.setTrustedRemote(lzChainId, remoteAndLocal);
    }

    function setRelayChainId(address proxy, string memory network) internal {
        CrossChainRelayUpgradeable relay = CrossChainRelayUpgradeable(payable(proxy));
        uint256 chainId = getChainId(network);
        console.log("[setRelayChainId] set src chain id: ");
        console.log("[setRelayChainId] chainId: ", chainId);
        relay.setSrcChainId(chainId);
    }

    function setRelayManager(address relayAddress, address manager) internal {
        CrossChainRelayUpgradeable relay = CrossChainRelayUpgradeable(payable(relayAddress));
        relay.setManagerAddress(manager);
    }
}
