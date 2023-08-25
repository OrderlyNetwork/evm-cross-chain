// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

import "contract-evm/src/library/types/EventTypes.sol";
import "contract-evm/src/library/types/AccountTypes.sol";

interface ILedgerCrossChainManager {
    // cross chain call deposit | from vault to leger
    //function deposit(
    //  AccountTypes.AccountDeposit memory message
    //) external;

    // cross chain withdraw approve | from leger to vault
    function withdraw(EventTypes.WithdrawData memory data) external;
    // cross chain withdraw finish | from vault to leger
    //function withdrawFinish(AccountTypes.AccountWithdraw memory message) external;

    // admin call
    function setLedger(address _ledger) external;
    function setOperatorManager(address _operatorManager) external;
    function setCrossChainRelay(address _crossChainRelay) external;
}
