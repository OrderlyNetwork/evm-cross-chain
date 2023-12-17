// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Importing types
import "contract-evm/src/library/types/EventTypes.sol";
import "contract-evm/src/library/types/AccountTypes.sol";
import "contract-evm/src/library/types/RebalanceTypes.sol";

/// @title ILedgerCrossChainManager Interface
/// @notice Interface for managing cross-chain activities related to the ledger.
interface ILedgerCrossChainManager {
    /// @notice Approves a cross-chain withdrawal from the ledger to the vault.
    /// @param data Struct containing withdrawal data.
    function withdraw(EventTypes.WithdrawData memory data) external;

    /// @notice Approves a cross-chain burn from the ledger to the vault.
    /// @param data Struct containing burn data.
    function burn(RebalanceTypes.RebalanceBurnCCData memory data) external;

    /// @notice Approves a cross-chain mint from the vault to the ledger.
    /// @param data Struct containing mint data.
    function mint(RebalanceTypes.RebalanceMintCCData memory data) external;

    /// @notice Sets the ledger address.
    /// @param ledger Address of the new ledger.
    function setLedger(address ledger) external;

    /// @notice Sets the operator manager address.
    /// @param operatorManager Address of the new operator manager.
    function setOperatorManager(address operatorManager) external;

    /// @notice Sets the cross-chain relay address.
    /// @param crossChainRelay Address of the new cross-chain relay.
    function setCrossChainRelay(address crossChainRelay) external;
}
