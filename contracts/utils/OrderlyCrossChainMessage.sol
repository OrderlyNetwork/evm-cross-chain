// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Library to handle the conversion of the message structure to bytes array and vice versa
library OrderlyCrossChainMessage {
    // List of methods that can be called cross-chain
    enum CrossChainOption {LayerZeroV1, LayerZeroV2}

    enum CrossChainMethod {
        Deposit, // from vault to ledger
        Withdraw, // from ledger to vault
        WithdrawFinish, // from vault to ledger
        Ping, // for message testing
        PingPong, // ABA message testing
        RebalanceBurn, // burn request from ledger to vault
        RebalanceBurnFinish, // burn request finish from vault to ledger
        RebalanceMint, // mint request from ledger to vault
        RebalanceMintFinish, //  mint request finish from vault to ledger
        Withdraw2Contract // withdraw to contract address
    }

    enum PayloadDataType {
        EventTypesWithdrawData,
        AccountTypesAccountDeposit,
        AccountTypesAccountWithdraw,
        VaultTypesVaultDeposit,
        VaultTypesVaultWithdraw,
        RebalanceBurnCCData,
        RebalanceBurnCCFinishData,
        RebalanceMintCCData,
        RebalanceMintCCFinishData,
        EventTypesWithdraw2Contract
    }

    // The structure of the message
    struct MessageV1 {
        uint8 method; // enum CrossChainMethod to uint8
        uint8 option; // enum CrossChainOption to uint8
        uint8 payloadDataType; // enum PayloadDataType to uint8
        address srcCrossChainManager; // Source cross-chain manager address
        address dstCrossChainManager; // Target cross-chain manager address
        uint256 srcChainId; // Source blockchain ID
        uint256 dstChainId; // Target blockchain ID
    }

    // Encode the message structure to bytes array
    function encodeMessageV1AndPayload(MessageV1 memory message, bytes memory payload)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode(message, payload);
    }

    // Decode the bytes array to message structure
    function decodeMessageV1AndPayload(bytes memory data) internal pure returns (MessageV1 memory, bytes memory) {
        (MessageV1 memory message, bytes memory payload) = abi.decode(data, (MessageV1, bytes));
        return (message, payload);
    }
}
