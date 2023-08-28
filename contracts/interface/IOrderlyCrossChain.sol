// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../utils/OrderlyCrossChainMessage.sol";

// Interface for the Cross Chain Operations
interface IOrderlyCrossChain {
    // Event to be emitted when a message is sent
    event MessageSent(OrderlyCrossChainMessage.MessageV1 message, bytes payload);

    // Event to be emitted when a message is received
    event MessageReceived(OrderlyCrossChainMessage.MessageV1 message, bytes payload);

    /**
     * Estimate the gas fee for sending a message to another chain
     */
    function estimateGasFee(OrderlyCrossChainMessage.MessageV1 memory data, bytes memory payload)
        external
        view
        returns (uint256);

    /**
     * Send a message to another chain
     *
     * @param payload The payload to be sent to the other chain
     */
    function sendMessage(OrderlyCrossChainMessage.MessageV1 memory message, bytes memory payload) external payable;

    /**
     * Receive a message from another chain
     *
     * @param payload The payload received from the other chain
     */
    function receiveMessage(OrderlyCrossChainMessage.MessageV1 memory message, bytes memory payload) external payable;
}

// Interface for the Cross Chain Receiver
interface IOrderlyCrossChainReceiver {
    /**
     * Receive a message from another chain
     *
     * @param payload The payload received from the other chain
     */
    function receiveMessage(OrderlyCrossChainMessage.MessageV1 memory message, bytes memory payload) external;
}
