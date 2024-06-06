import { ethers } from 'ethers';

function decodeDeposit(data: string) {
    // decode: event MessageSent(OrderlyCrossChainMessage.MessageV1 message, bytes payload);
    // where MessageV1 is a struct
    //     // The structure of the message
    // struct MessageV1 {
    //     uint8 method; // enum CrossChainMethod to uint8
    //     uint8 option; // enum CrossChainOption to uint8
    //     uint8 payloadDataType; // enum PayloadDataType to uint8
    //     address srcCrossChainManager; // Source cross-chain manager address
    //     address dstCrossChainManager; // Target cross-chain manager address
    //     uint256 srcChainId; // Source blockchain ID
    //     uint256 dstChainId; // Target blockchain ID
    // }
    // decode MessageSent Event data
    const decodeData = ethers.AbiCoder.defaultAbiCoder().decode( ["tuple(uint8,uint8,uint8,address,address,uint256,uint256,bytes)", "bytes"], data);

    // payload the the encoded data of
    //     struct VaultDeposit {
    //     bytes32 accountId;
    //     address userAddress;
    //     bytes32 brokerHash;
    //     bytes32 tokenHash;
    //     uint128 tokenAmount;
    //     uint64 depositNonce; // deposit nonce
    // }
    const payloadDecoded = ethers.AbiCoder.defaultAbiCoder().decode( ["bytes32", "address", "bytes32", "bytes32", "uint128", "uint64"], decodeData[0][7]);

    console.log(decodeData);

    console.log(payloadDecoded);
}

// run the function
const sampleData = "0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003000000000000000000000000a0a07a78c7d31e6f8698f48fc9219f9a3030f38c000000000000000000000000a0a07a78c7d31e6f8698f48fc9219f9a3030f38c000000000000000000000000000000000000000000000000000000000000a4b10000000000000000000000000000000000000000000000000000000000000123000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000c0803dd86bd281412031397f5b31fe70f2020f7c14cbe3a34dcf9f0ebbc6ff29e0000000000000000000000000edaedf29ee4b6c54335bf8ada7dece235315729595d85ced8adb371760e4b6437896a075632fbd6cefe699f8125a8bc1d9b19e5bd6aca1be9729c13d677335161321649cccae6a591554772516700f986f942eaa000000000000000000000000000000000000000000000000000000000016e3600000000000000000000000000000000000000000000000000000000000041a10"

// run
decodeDeposit(sampleData);