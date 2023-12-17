pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "../contracts/CrossChainRelayUpgradeable.sol";
import "../contracts/CrossChainRelayProxy.sol";
import "../contracts/utils/OrderlyCrossChainMessage.sol";
import "../contracts/layerzero/mocks/LZEndpointMock.sol";
import "./CrossChainRelaySetup.t.sol";

contract CrossChainRelayTest is Test, CrossChainRelaySetup {
    event MsgReceived(uint8);
    event Ping();
    event Pong();

    function setUp() public {
        deployCrossChainRelay();
        setupCrossChainRelay();
    }

    // should not be initialized again
    function testFail_initialize() public {
        CrossChainRelayUpgradeable(payable(address(_srcRelayProxy))).initialize(address(_srcEndpoint));
    }

    function test_OwnerIsCaller() public {
        CrossChainRelayUpgradeable relay = CrossChainRelayUpgradeable(payable(address(_srcRelayProxy)));
        assertEq(relay._callers(address(this)), 1);
    }

    function test_EndpointIsCaller() public {
        CrossChainRelayUpgradeable relay = CrossChainRelayUpgradeable(payable(address(_srcRelayProxy)));
        assertEq(relay._callers(address(_srcEndpoint)), 1);
    }

    function testFuzz_AddRemoveCaller(address other) public {
        CrossChainRelayUpgradeable relay = CrossChainRelayUpgradeable(payable(address(_srcRelayProxy)));
        assertEq(relay._callers(other), 0);
        relay.addCaller(other);
        assertEq(relay._callers(other), 1);
        relay.removeCaller(other);
        assertEq(relay._callers(other), 0);
    }

    function testFuzz_updateEndpoint(address endpoint) public {
        CrossChainRelayUpgradeable relay = CrossChainRelayUpgradeable(payable(address(_srcRelayProxy)));
        relay.updateEndpoint(endpoint);
        assertEq(address(relay.lzEndpoint()), endpoint);
    }

    // upgrade should fail because random implementation is not UUPS
    function testFail_upgradeTo() public {
        address newImplementation = 0x1234567890123456789012345678901234567890;
        CrossChainRelayUpgradeable relay = CrossChainRelayUpgradeable(payable(address(_srcRelayProxy)));
        relay.upgradeTo(newImplementation);
    }

    function test_upgradeTo() public {
        CrossChainRelayUpgradeable relay = CrossChainRelayUpgradeable(payable(address(_srcRelayProxy)));
        relay.upgradeTo(address(new CrossChainRelayUpgradeable()));
    }

    function testFuzz_addChainIdMapping(uint256 chainId, uint16 lzChainId) public {
        CrossChainRelayUpgradeable relay = CrossChainRelayUpgradeable(payable(address(_srcRelayProxy)));
        relay.addChainIdMapping(chainId, lzChainId);
        assertEq(relay._chainIdMapping(chainId), lzChainId);
        assertEq(relay._lzChainIdMapping(lzChainId), chainId);
    }

    function testFuzz_addCrossChainManagerMapping(uint256 chainId, address ccmanager) public {
        CrossChainRelayUpgradeable relay = CrossChainRelayUpgradeable(payable(address(_srcRelayProxy)));
        relay.addCrossChainManagerMapping(chainId, ccmanager);
        assertEq(relay._crossChainManagerMapping(chainId), ccmanager);
    }

    function test_sendPingPong() public {
        CrossChainRelayUpgradeable srcRelay = CrossChainRelayUpgradeable(payable(address(_srcRelayProxy)));
        (bool success,) = payable(srcRelay).call{value: 1 ether}("");
        require(success, "failed to send ether");
        (success,) = payable(_dstRelayProxy).call{value: 1 ether}("");
        require(success, "failed to send ether");
        vm.expectEmit(true, true, true, true);
        emit MsgReceived(uint8(OrderlyCrossChainMessage.CrossChainMethod.PingPong));
        vm.expectEmit(true, true, true, true);
        emit Ping();
        vm.expectEmit(true, true, true, true);
        emit Pong();

        srcRelay.pingPong(_ledgerChainId);
    }

    function testFail_sendPingPongWrongChainId() public {
        CrossChainRelayUpgradeable srcRelay = CrossChainRelayUpgradeable(payable(address(_srcRelayProxy)));
        srcRelay.pingPong(_ledgerChainId + 1);
    }

    function test_sendMessageWithFee() public {
        OrderlyCrossChainMessage.MessageV1 memory data = OrderlyCrossChainMessage.MessageV1({
            method: uint8(OrderlyCrossChainMessage.CrossChainMethod.PingPong),
            option: 0,
            payloadDataType: 0,
            srcCrossChainManager: address(0),
            dstCrossChainManager: address(0),
            srcChainId: _vaultChainId,
            dstChainId: _ledgerChainId
        });
        CrossChainRelayUpgradeable srcRelay = CrossChainRelayUpgradeable(payable(address(_srcRelayProxy)));
        (bool success,) = payable(_dstRelayProxy).call{value: 1 ether}("");
        require(success, "failed to send ether");
        uint256 fee = srcRelay.estimateGasFee(data, bytes(""));

        vm.expectEmit(true, true, true, true);
        emit MsgReceived(uint8(OrderlyCrossChainMessage.CrossChainMethod.PingPong));
        vm.expectEmit(true, true, true, true);
        emit Ping();
        vm.expectEmit(true, true, true, true);
        emit Pong();
        srcRelay.sendMessageWithFee{value: fee}(data, bytes(""));
    }
}
