// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Importing necessary utility libraries and types
import "../utils/OrderlyCrossChainMessage.sol";
import "contract-evm/src/library/types/AccountTypes.sol";
import "contract-evm/src/library/types/VaultTypes.sol";
import "contract-evm/src/library/types/RebalanceTypes.sol";

/// @title IVaultCrossChainManager Interface
/// @notice Interface for managing cross-chain activities related to the vault.
interface IVaultCrossChainManager {
    /// @notice Triggers a withdrawal from the ledger.
    /// @param withdraw Struct containing withdrawal data.
    function withdraw(VaultTypes.VaultWithdraw memory withdraw) external;

    /// @notice Triggers a finish msg from vault to ledger to inform the status of burn
    /// @param data Struct containing burn data.
    function burnFinish(RebalanceTypes.RebalanceBurnCCFinishData memory data) external;

    /// @notice Triggers a finish msg from vault to ledger to inform the status of mint
    /// @param data Struct containing mint data.
    function mintFinish(RebalanceTypes.RebalanceMintCCFinishData memory data) external;

    /// @notice Initiates a deposit to the vault.
    /// @param data Struct containing deposit data.
    function deposit(VaultTypes.VaultDeposit memory data) external;

    /// @notice Initiates a deposit to the vault along with native fees.
    /// @param data Struct containing deposit data.
    function depositWithFee(VaultTypes.VaultDeposit memory data) external payable;

    /// @notice Fetches the deposit fee based on deposit data.
    /// @param data Struct containing deposit data.
    /// @return fee The calculated deposit fee.
    function getDepositFee(VaultTypes.VaultDeposit memory data) external view returns (uint256);

    /// @notice Sets the vault address.
    /// @param vault Address of the new vault.
    function setVault(address vault) external;

    /// @notice Sets the cross-chain relay address.
    /// @param crossChainRelay Address of the new cross-chain relay.
    function setCrossChainRelay(address crossChainRelay) external;
}
