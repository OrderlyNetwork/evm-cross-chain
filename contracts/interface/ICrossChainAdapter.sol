// SPX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../utils/OrderlyCrossChainMessage.sol";

interface ICrossChainAdapter {
    event OrderlyCCMessageSent(OrderlyCrossChainMessage.MessageV1 message, bytes payload);
    event OrderlyCCMessageReceived(OrderlyCrossChainMessage.MessageV1 message, bytes payload);

    function estimateGas(OrderlyCrossChainMessage.MessageV1 memory message, bytes memory payload) external view returns (uint256);

    function send(OrderlyCrossChainMessage.MessageV1 memory message, bytes memory orderlyPayload) external payable;
    function sendWithRefund(OrderlyCrossChainMessage.MessageV1 memory message, bytes memory orderlyPayload, address refundAddress) external payable;

}