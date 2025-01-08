// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./BaseTest.sol";
import "./CrossChainRelaySetup.t.sol";

contract CrossChainRelayTest is BaseTest, CrossChainRelaySetup {
    function setUp() public {
        deployCrossChainRelay();
        setupCrossChainRelay();
    }

    function test_initialization() public {
        CrossChainRelayUpgradeable relay = CrossChainRelayUpgradeable(payable(address(_srcRelayProxy)));
        
        // Check initial state
        assertEq(relay._callers(address(this)), 1, "Owner should be a caller");
        assertEq(relay._callers(address(_srcEndpoint)), 1, "Endpoint should be a caller");
        
        // Verify cannot initialize again
        vm.expectRevert("Initializable: contract is already initialized");
        relay.initialize(address(_srcEndpoint));
    }

    function test_callerManagement() public {
        CrossChainRelayUpgradeable relay = CrossChainRelayUpgradeable(payable(address(_srcRelayProxy)));
        
        // Test caller addition
        address newCaller = address(0xBEEF);
        relay.addCaller(newCaller);
        assertEq(relay._callers(newCaller), 1, "Caller should be added");
        
        // Test caller removal
        relay.removeCaller(newCaller);
        assertEq(relay._callers(newCaller), 0, "Caller should be removed");
        
        // Test non-owner cannot add callers
        vm.prank(newCaller);
        vm.expectRevert("Ownable: caller is not the owner");
        relay.addCaller(newCaller);
    }

    function test_chainIdMapping() public {
        CrossChainRelayUpgradeable relay = CrossChainRelayUpgradeable(payable(address(_srcRelayProxy)));
        
        uint256 newChainId = 123;
        uint16 newLzChainId = 456;
        
        relay.addChainIdMapping(newChainId, newLzChainId);
        
        assertEq(relay._chainIdMapping(newChainId), newLzChainId, "Chain ID mapping failed");
        assertEq(relay._lzChainIdMapping(newLzChainId), newChainId, "LZ Chain ID mapping failed");
    }

    function test_crossChainPing() public {
        CrossChainRelayUpgradeable srcRelay = CrossChainRelayUpgradeable(payable(address(_srcRelayProxy)));
        
        // Fund contracts for gas
        fundContract(address(srcRelay), 1 ether);
        fundContract(address(_dstRelayProxy), 1 ether);
        
        // Expect events in correct order
        vm.expectEmit(true, true, true, true);
        emit MsgReceived(uint8(OrderlyCrossChainMessage.CrossChainMethod.PingPong));
        
        vm.expectEmit(true, true, true, true);
        emit Ping();
        
        vm.expectEmit(true, true, true, true);
        emit Pong();
        
        srcRelay.pingPong(LEDGER_CHAIN_ID);
    }

    function test_messageWithFee() public {
        CrossChainRelayUpgradeable srcRelay = CrossChainRelayUpgradeable(payable(address(_srcRelayProxy)));
        fundContract(address(_dstRelayProxy), 1 ether);
        
        OrderlyCrossChainMessage.MessageV1 memory message = createCrossChainMessage(
            uint8(OrderlyCrossChainMessage.CrossChainMethod.PingPong),
            address(0),
            address(0),
            VAULT_CHAIN_ID,
            LEDGER_CHAIN_ID
        );
        
        uint256 fee = srcRelay.estimateGasFee(message, bytes(""));
        
        vm.expectEmit(true, true, true, true);
        emit MessageSent(message, bytes(""));
        
        srcRelay.sendMessageWithFee{value: fee}(message, bytes(""));
    }

    function testFail_invalidChainId() public {
        CrossChainRelayUpgradeable srcRelay = CrossChainRelayUpgradeable(payable(address(_srcRelayProxy)));
        srcRelay.pingPong(999); // Non-existent chain ID
    }
}
