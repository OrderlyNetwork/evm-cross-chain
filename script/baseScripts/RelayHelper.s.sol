// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "evm-cross-chain/contracts/CrossChainRelayUpgradeable.sol";
import "evm-cross-chain/contracts/CrossChainRelayProxy.sol";
import "evm-cross-chain/contracts/utils/OrderlyCrossChainMessage.sol";
import "./BaseScript.s.sol";
import "./OperationHelper.s.sol";
import "./Utils.sol";

contract RelayHelper is BaseScript, OperationHelper {
    using StringUtils for string;

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

    function forceResume(address relayAddress, uint16 chainId, bytes memory path) internal {
        CrossChainRelayUpgradeable relay = CrossChainRelayUpgradeable(payable(relayAddress));
        relay.forceResumeReceive(chainId, path);
    }

    function setCrossChainFee(address relayAddress, string memory method, uint256 fee) internal {
        CrossChainRelayUpgradeable relay = CrossChainRelayUpgradeable(payable(relayAddress));
        uint8 method_id = 0;
        if (method.equal("deposit")) {
            method_id = uint8(OrderlyCrossChainMessage.CrossChainMethod.Deposit);
        } else if (method.equal("withdraw")) {
            method_id = uint8(OrderlyCrossChainMessage.CrossChainMethod.Withdraw);
        } else if (method.equal("withdrawFinish")) {
            method_id = uint8(OrderlyCrossChainMessage.CrossChainMethod.WithdrawFinish);
        } else if (method.equal("ping")) {
            method_id = uint8(OrderlyCrossChainMessage.CrossChainMethod.Ping);
        } else if (method.equal("pingPong")) {
            method_id = uint8(OrderlyCrossChainMessage.CrossChainMethod.PingPong);
        } else if (method.equal("burn")) {
            method_id = uint8(OrderlyCrossChainMessage.CrossChainMethod.RebalanceBurn);
        } else if (method.equal("burnFinish")) {
            method_id = uint8(OrderlyCrossChainMessage.CrossChainMethod.RebalanceBurnFinish);
        } else if (method.equal("mint")) {
            method_id = uint8(OrderlyCrossChainMessage.CrossChainMethod.RebalanceMint);
        } else if (method.equal("mintFinish")) {
            method_id = uint8(OrderlyCrossChainMessage.CrossChainMethod.RebalanceMintFinish);
        } else {
            revert("[setCrossChainFee] wrong method");
        }

        relay.addFlowGasLimitMapping(method_id, fee);
    }

    function sendPingPong(address relayAddress, string memory dstNetwork) internal {
        CrossChainRelayUpgradeable relay = CrossChainRelayUpgradeable(payable(relayAddress));
        uint256 chainId = getChainId(dstNetwork);
        console.log("[sendPingPong] send ping pong: ");
        console.log("[sendPingPong] chainId: ", chainId);
        relay.pingPong(chainId);
    }
}
