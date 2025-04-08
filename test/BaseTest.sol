// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/CrossChainRelayUpgradeable.sol";
import "../contracts/OrderlyProxy.sol";
import "../contracts/layerzero/mocks/LZEndpointMock.sol";

/// @notice Base test contract with common setup and utilities
contract BaseTest is Test {
    // Common constants
    uint16 constant VAULT_LZ_CHAIN_ID = 1001;
    uint16 constant LEDGER_LZ_CHAIN_ID = 1002;
    uint16 constant VAULT_CHAIN_ID = 1;
    uint16 constant LEDGER_CHAIN_ID = 2;
    
    // Test addresses
    address constant MOCK_USER = address(0x123);
    address constant MOCK_OPERATOR = address(0x456);
    
    // Events for testing
    event MessageSent(OrderlyCrossChainMessage.MessageV1 message, bytes payload);
    event MessageReceived(OrderlyCrossChainMessage.MessageV1 message, bytes payload);
    event MsgReceived(uint8);
    event Ping();
    event Pong();

    // Helper to fund contracts with ETH
    function fundContract(address contractAddr, uint256 amount) internal {
        (bool success,) = payable(contractAddr).call{value: amount}("");
        require(success, "Failed to fund contract");
    }

    // Helper to create cross-chain message
    function createCrossChainMessage(
        uint8 method,
        address srcManager,
        address dstManager,
        uint256 srcChainId,
        uint256 dstChainId
    ) internal pure returns (OrderlyCrossChainMessage.MessageV1 memory) {
        return OrderlyCrossChainMessage.MessageV1({
            method: method,
            option: uint8(OrderlyCrossChainMessage.CrossChainOption.LayerZeroV1),
            payloadDataType: 0,
            srcCrossChainManager: srcManager,
            dstCrossChainManager: dstManager,
            srcChainId: srcChainId,
            dstChainId: dstChainId
        });
    }
} 