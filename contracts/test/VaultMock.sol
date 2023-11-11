// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "contract-evm/src/interface/IVault.sol";
import "contract-evm/src/library/types/RebalanceTypes.sol";
import "../interface/IVaultCrossChainManager.sol";

// empty contract for test
contract VaultMock is IVault{

    address public crossChainManagerAddress;

    function initialize() external override {
    }

    function deposit(VaultTypes.VaultDepositFE calldata data) external payable override {
    }

    function depositTo(address receiver, VaultTypes.VaultDepositFE calldata data) external payable override {
    }

    function getDepositFee(VaultTypes.VaultDepositFE calldata data, address recevier) external view override returns (uint256) {
        return 0;
    }

    function enableDepositFee(bool _enabled) external override {
    }

    function withdraw(VaultTypes.VaultWithdraw calldata data) external override {
    }

    // functions for receive rebalance msg 
    function rebalanceMint(RebalanceTypes.RebalanceMintCCData memory data) external override {
        RebalanceTypes.RebalanceMintCCFinishData memory finishData = RebalanceTypes.RebalanceMintCCFinishData({
            rebalanceStatus: 0,
            rebalanceId: data.rebalanceId,
            amount: data.amount,
            tokenHash: data.tokenHash,
            srcChainId: data.dstChainId,
            dstChainId: data.srcChainId
        });
        // the rebalance logic @zion for your reference
        IVaultCrossChainManager(crossChainManagerAddress).mintFinish(data);
    }

    function rebalanceBurn(RebalanceTypes.RebalanceBurnCCData memory data) external override {
        RebalanceTypes.RebalanceBurnCCFinishData memory finishData = RebalanceTypes.RebalanceBurnCCFinishData({
            rebalanceStatus: 0,
            rebalanceId: data.rebalanceId,
            amount: data.amount,
            tokenHash: data.tokenHash,
            srcChainId: data.srcChainId,
            dstChainId: data.dstChainId
        });
        // the rebalance logic @zion for your reference
        IVaultCrossChainManager(crossChainManagerAddress).burnFinish(finishData);
    }

    // CCTP
    function depositForBurn(
        uint64 rebalanceId,
        uint128 amount,
        bytes32 tokenHash,
        uint256 srcChainId,
        uint256 dstChainId,
        uint32 destinationDomain,
        bytes32 mintRecipient
    ) external override {
    }

    function receiveMessage(
        uint64 rebalanceId,
        uint128 amount,
        bytes32 tokenHash,
        uint256 srcChainId,
        uint256 dstChainId,
        bytes calldata message,
        bytes calldata attestation
    ) external override {
    }

    // admin call
    function setCrossChainManager(address _crossChainManagerAddress) external override {
        crossChainManagerAddress = _crossChainManagerAddress;
    }

    function emergencyPause() external override {
    }

    function emergencyUnpause() external override {
    }

    // whitelist
    function setAllowedToken(bytes32 _tokenHash, bool _allowed) external override {
    }

    function setAllowedBroker(bytes32 _brokerHash, bool _allowed) external override {
    }

    function changeTokenAddressAndAllow(bytes32 _tokenHash, address _tokenAddress) external override {
    }

    function getAllowedToken(bytes32 _tokenHash) external view override returns (address) {
        return address(0);
    }

    function getAllowedBroker(bytes32 _brokerHash) external view override returns (bool) {
        return false;
    }

    function getAllAllowedToken() external view override returns (bytes32[] memory) {
        return new bytes32[](0);
    }

    function getAllAllowedBroker() external view override returns (bytes32[] memory) {
        return new bytes32[](0);
    }


}