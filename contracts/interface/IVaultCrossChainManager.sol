// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Importing necessary utility libraries and types
import "../utils/OrderlyCrossChainMessage.sol";
import "contract-evm/src/library/types/AccountTypes.sol";
import "contract-evm/src/library/types/VaultTypes.sol";

/// @title IVaultCrossChainManager Interface
/// @notice Interface for managing cross-chain activities related to the vault.
interface IVaultCrossChainManager {
    /// @notice Triggers a withdrawal from the ledger.
    /// @param _withdraw Struct containing withdrawal data.
    function withdraw(VaultTypes.VaultWithdraw memory _withdraw) external;

    /// @notice Initiates a deposit to the vault.
    /// @param _data Struct containing deposit data.
    function deposit(VaultTypes.VaultDeposit memory _data) external;

    /// @notice Initiates a deposit to the vault along with native fees.
    /// @param _data Struct containing deposit data.
    /// @param _amount Amount of native fee.
    function depositWithFee(VaultTypes.VaultDeposit memory _data, uint256 _amount) external payable;

    /// @notice Fetches the deposit fee based on deposit data.
    /// @param _data Struct containing deposit data.
    /// @return fee The calculated deposit fee.
    function getDepositFee(VaultTypes.VaultDeposit memory _data) external view returns (uint256);

    /// @notice Sets the vault address.
    /// @param _vault Address of the new vault.
    function setVault(address _vault) external;

    /// @notice Sets the cross-chain relay address.
    /// @param _crossChainRelay Address of the new cross-chain relay.
    function setCrossChainRelay(address _crossChainRelay) external;
}
