// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

import "../utils/OrderlyCrossChainMessage.sol";
import "contract-evm/src/library/types/AccountTypes.sol";
import "contract-evm/src/library/types/VaultTypes.sol";

interface IVaultCrossChainManager {
    function withdraw(VaultTypes.VaultWithdraw memory withdraw) external;

    function deposit(VaultTypes.VaultDeposit memory data) external;

    function setVault(address _vault) external;
    function setCrossChainRelay(address _crossChainRelay) external;
}
