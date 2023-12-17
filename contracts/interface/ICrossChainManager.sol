// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @title ICrossChainManager Interface
/// @notice Interface for managing cross-chain common operations
interface ICrossChainManager {
    /// @notice set chain id
    /// @param _chainId chain id
    function setChainId(uint256 _chainId) external;

    /// @notice Sets the cross-chain relay address.
    /// @param _crossChainRelay Address of the new cross-chain relay.
    function setCrossChainRelay(address _crossChainRelay) external;

    /// @notice upgrade implementation
    /// @param _newImplementation new implementation of manager
    function upgradeTo(address _newImplementation) external;
}
