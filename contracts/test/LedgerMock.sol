// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "contract-evm/src/interface/ILedger.sol";
import "contract-evm/src/dataLayout/LedgerDataLayout.sol";
import "contract-evm/src/library/types/RebalanceTypes.sol";
import "../interface/ILedgerCrossChainManager.sol";

    // function initialize() external;

    // // Functions called by cross chain manager on Ledger side
    // function accountDeposit(AccountTypes.AccountDeposit calldata data) external;
    // function accountWithDrawFinish(AccountTypes.AccountWithdraw calldata withdraw) external;

    // // functions for rebalance
    // function rebalanceBurnFinish(RebalanceTypes.RebalanceBurnCCFinishData memory data) external;
    // function rebalanceMintFinish(RebalanceTypes.RebalanceMintCCFinishData memory data) external;

    // // Functions called by operator manager to executre actions
    // function executeProcessValidatedFutures(PerpTypes.FuturesTradeUpload calldata trade) external;
    // function executeWithdrawAction(EventTypes.WithdrawData calldata withdraw, uint64 eventId) external;
    // function executeSettlement(EventTypes.Settlement calldata ledger, uint64 eventId) external;
    // function executeLiquidation(EventTypes.Liquidation calldata liquidation, uint64 eventId) external;
    // function executeAdl(EventTypes.Adl calldata adl, uint64 eventId) external;
    // function executeRebalanceBurn(RebalanceTypes.RebalanceBurnUploadData calldata data) external;
    // function executeRebalanceBurnResult(
    //     uint64 rebalanceId,
    //     bytes32 tokenHash,
    //     uint256 burnChainId,
    //     uint128 amount,
    //     bool success
    // ) external;
    // function executeRebalanceMint(RebalanceTypes.RebalanceMintUploadData calldata data) external;
    // function executeRebalanceMintResult(
    //     uint64 rebalanceId,
    //     bytes32 tokenHash,
    //     uint256 mintChainId,
    //     uint128 amount,
    //     bool success
    // ) external;

    // // view call
    // function getFrozenWithdrawNonce(bytes32 accountId, uint64 withdrawNonce, bytes32 tokenHash)
    //     external
    //     view
    //     returns (uint128);
    // // omni view call
    // function batchGetUserLedger(bytes32[] calldata accountIds, bytes32[] memory tokens, bytes32[] memory symbols)
    //     external
    //     view
    //     returns (AccountTypes.AccountSnapshot[] memory);
    // function batchGetUserLedger(bytes32[] calldata accountIds)
    //     external
    //     view
    //     returns (AccountTypes.AccountSnapshot[] memory);
    // function getRebalanceStatus(uint64 rebalanceId) external view returns (RebalanceTypes.RebalanceStatus memory);

    // // admin call
    // function setOperatorManagerAddress(address _operatorManagerAddress) external;
    // function setCrossChainManager(address _crossChainManagerAddress) external;
    // function setVaultManager(address _vaultManagerAddress) external;
    // function setMarketManager(address _marketManagerAddress) external;
    // function setFeeManager(address _feeManagerAddress) external;

contract LedgerMock is ILedger, LedgerDataLayout{

    event MintFinish();
    event BurnFinish();

    function setOperatorManagerAddress(address) public override {
    }

    function setCrossChainManager(address _crossChainManagerAddress) public override  {
        crossChainManagerAddress = _crossChainManagerAddress;
    }

    function setVaultManager(address _vaultManagerAddress) public override  {
    }

    function setMarketManager(address _marketManagerAddress) public override  {
    }

    function setFeeManager(address _feeManagerAddress) public override  {
    }

    function getFrozenWithdrawNonce(bytes32 accountId, uint64 withdrawNonce, bytes32 tokenHash)
        public
        view
        override
        returns (uint128)
    {
        return 0;
    }

    function batchGetUserLedger(bytes32[] calldata accountIds, bytes32[] memory tokens, bytes32[] memory symbols)
        public
        view
        override
        returns (AccountTypes.AccountSnapshot[] memory accountSnapshots)
    {
        accountSnapshots = new AccountTypes.AccountSnapshot[](0);
    }

    function accountDeposit(AccountTypes.AccountDeposit calldata data) external override {
    }

    function executeProcessValidatedFutures(PerpTypes.FuturesTradeUpload calldata trade)
        external
        override
    { }

    function executeWithdrawAction(EventTypes.WithdrawData calldata withdraw, uint64 eventId)
        external
        override
    {
    }

    function accountWithDrawFinish(AccountTypes.AccountWithdraw calldata withdraw)
        external
        override
    {
    }

    function executeSettlement(EventTypes.Settlement calldata settlement, uint64 eventId)
        external
        override
    {
    }

    function executeLiquidation(EventTypes.Liquidation calldata liquidation, uint64 eventId)
        external
        override
    {
       
    }

    function executeAdl(EventTypes.Adl calldata adl, uint64 eventId) external override  {
       
    }

    function executeRebalanceBurn(RebalanceTypes.RebalanceBurnUploadData calldata data)
        external
        override
        
    {
       
    }

    function executeRebalanceMint(RebalanceTypes.RebalanceMintUploadData calldata data)
        external
        override
    {
      
    }

    function executeRebalanceMintResult(
        uint64 rebalanceId,
        bytes32 tokenHash,
        uint256 mintChainId,
        uint128 amount,
        bool success
    ) external {
    }

    function getRebalanceStatus(uint64 rebalanceId)
        external
        view
        
        returns (RebalanceTypes.RebalanceStatus memory)
    {
        RebalanceTypes.RebalanceStatus memory status = RebalanceTypes.RebalanceStatus({
            rebalanceId: rebalanceId,
            burnStatus: RebalanceTypes.RebalanceStatusEnum.Pending,
            mintStatus: RebalanceTypes.RebalanceStatusEnum.Pending
        });
        return status;
    }

    function rebalanceBurnFinish(RebalanceTypes.RebalanceBurnCCFinishData memory )
        external
        override
    {
        emit BurnFinish();
    }

    function rebalanceMintFinish(RebalanceTypes.RebalanceMintCCFinishData memory )
        external
        override
    {
        emit MintFinish();
    }

    function batchGetUserLedger(bytes32[] calldata accountIds)
        external
        view
        override
        returns (AccountTypes.AccountSnapshot[] memory)
    {
        AccountTypes.AccountSnapshot[] memory accountSnapshots = new AccountTypes.AccountSnapshot[](0);
        return accountSnapshots;
    }

    function initialize() external override {
    }



    function sendTestRebalanceBurn(uint256 burnChainId, uint256 mintChainId) external {
        // uint32 dstDomain;
        // uint64 rebalanceId;
        // uint128 amount;
        // bytes32 tokenHash;
        // uint256 burnChainId;
        // uint256 mintChainId;
        // address dstVaultAddress;
        RebalanceTypes.RebalanceBurnCCData memory data = RebalanceTypes.RebalanceBurnCCData({
            dstDomain: 0,
            rebalanceId: 0,
            amount: 0,
            tokenHash: 0,
            burnChainId:burnChainId, 
            mintChainId: mintChainId,
            dstVaultAddress: address(0)
        });
        ILedgerCrossChainManager crossChainManager = ILedgerCrossChainManager(crossChainManagerAddress);
        crossChainManager.burn(data);
    }

    function sendTestRebalanceMint(uint256 burnChainId, uint256 mintChainId) external {
        // uint64 rebalanceId;
        // uint128 amount;
        // bytes32 tokenHash;
        // uint256 burnChainId;
        // uint256 mintChainId;
        // bytes messageBytes;
        // bytes messageSignature;
        RebalanceTypes.RebalanceMintCCData memory data = RebalanceTypes.RebalanceMintCCData({
            rebalanceId: 0,
            amount: 0,
            tokenHash: 0,
            burnChainId:burnChainId, 
            mintChainId: mintChainId,
            messageBytes: new bytes(0),
            messageSignature: new bytes(0)
        });
        ILedgerCrossChainManager crossChainManager = ILedgerCrossChainManager(crossChainManagerAddress);
        crossChainManager.mint(data);
    }

}
