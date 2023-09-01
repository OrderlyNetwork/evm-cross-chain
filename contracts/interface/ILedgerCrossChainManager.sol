// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Importing types
import "contract-evm/src/library/types/EventTypes.sol";
import "contract-evm/src/library/types/AccountTypes.sol";

/// @title ILedgerCrossChainManager Interface
/// @notice Interface for managing cross-chain activities related to the ledger.
interface ILedgerCrossChainManager {
    /// @notice Approves a cross-chain withdrawal from the ledger to the vault.
    /// @param data Struct containing withdrawal data.
    function withdraw(EventTypes.WithdrawData memory data) external;

    /// @notice Sets the ledger address.
    /// @param _ledger Address of the new ledger.
    function setLedger(address _ledger) external;

    /// @notice Sets the operator manager address.
    /// @param _operatorManager Address of the new operator manager.
    function setOperatorManager(address _operatorManager) external;

    /// @notice Sets the cross-chain relay address.
    /// @param _crossChainRelay Address of the new cross-chain relay.
    function setCrossChainRelay(address _crossChainRelay) external;
}
