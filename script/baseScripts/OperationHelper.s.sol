// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract OperationHelper {
    function transferNativeToken(address to, uint256 amount) internal {
        (bool success,) = to.call{value: amount}("");
        require(success, "[TransferNativeToken]Transfer failed.");
    }
}
