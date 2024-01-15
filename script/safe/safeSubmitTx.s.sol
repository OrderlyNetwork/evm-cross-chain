// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {QuickSort} from "./libraries/QuickSort.sol";
import {SignatureDecoder} from "safe/common/SignatureDecoder.sol";
import {Safe, Enum} from "safe/Safe.sol";

import "forge-std/console2.sol";
import "forge-std/StdJson.sol";
import "forge-std/Script.sol";

import "../baseScripts/Utils.sol";

contract SafeSubmitTx is Script, SignatureDecoder {
    using stdJson for string;
    using QuickSort for address[];

    address[] signers;
    bytes[] signatures;
    mapping(address => bytes) signatureOf;

    struct SafeTxData {
        address to;
        uint256 value;
        bytes data;
        Enum.Operation operation;
        uint256 safeTxGas;
        uint256 baseGas;
        uint256 gasPrice;
        address gasToken;
        address payable refundReceiver;
        bytes signatures;
    }

    // keccak256(
    //     "SafeTx(address to,uint256 value,bytes data,uint8 operation,uint256 safeTxGas,uint256 baseGas,uint256 gasPrice,address gasToken,address refundReceiver,uint256 nonce)"
    // );
    bytes32 private constant SAFE_TX_TYPEHASH = 0xbb8310d486368db6bd6f849402fdd73ad53d316b5a4b2644ad6efe0f941286d8;

    string internal ROOT = vm.projectRoot();
    string internal SIGNATURES_DIR = string.concat(ROOT, "/data/");

    string internal TX_FILE = vm.envString("FS_safeSubmitTx_txFile");
    string internal HASH_DATA_FILE = string.concat(SIGNATURES_DIR, "hashData.txt");
    string internal SIGNATURES_FILE = string.concat(SIGNATURES_DIR, "signatures.txt");

    Safe SAFE;
    address internal SENDER;
    uint256 internal NONCE;
    uint256 internal THRESHOLD;
    bytes32 internal DOMAIN_SEPARATOR;

    function setUp() public {
        string memory network = vm.envString("FS_safeSubmitTx_network");
        string memory networkUpCase = StringUtils.toUpperCase(network);
        uint256 pk = vm.envUint(string.concat(networkUpCase, "_PRIVATE_KEY"));
        SENDER = vm.addr(pk);
        string memory rpcUrl = vm.envString(string.concat("RPC_URL_", networkUpCase));
        vm.createSelectFork(rpcUrl);
        vm.startBroadcast(pk);
        SAFE = Safe(payable(vm.envAddress("SAFE")));

        NONCE = vm.envOr("SAFE_NONCE", SAFE.nonce());
        THRESHOLD = SAFE.getThreshold();
        DOMAIN_SEPARATOR = SAFE.domainSeparator();
    }

    function loadSafeTxData() internal returns (SafeTxData memory txData) {
        string memory json = vm.readFile(TX_FILE);

        txData.to = json.readAddress("$.to");
        txData.value = json.readUint("$.value");
        txData.data = json.readBytes("$.data");
        txData.operation = Enum.Operation(json.readUint("$.operation"));
        txData.safeTxGas = json.readUint("$.safeTxGas");
        txData.baseGas = json.readUint("$.baseGas");
        txData.gasPrice = json.readUint("$.gasPrice");
        txData.gasToken = json.readAddress("$.gasToken");
        txData.refundReceiver = payable(json.readAddress("$.refundReceiver"));
    }

    function hashData(SafeTxData memory txData) internal view returns (bytes32) {
        return SAFE.getTransactionHash(
            txData.to,
            txData.value,
            txData.data,
            txData.operation,
            txData.safeTxGas,
            txData.baseGas,
            txData.gasPrice,
            txData.gasToken,
            txData.refundReceiver,
            NONCE
        );
    }

    function decode(bytes32 dataHash, bytes memory signature)
        internal
        pure
        returns (address signer, bytes32 r, bytes32 s, uint8 v)
    {
        (v, r, s) = signatureSplit(signature, 0);

        signer = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)), v, r, s);
    }

    function run() public {
        SafeTxData memory txData = loadSafeTxData();

        loadSignatures(hashData(txData));

        signers.sort();

        for (uint256 i; i < signers.length; ++i) {
            txData.signatures = bytes.concat(txData.signatures, signatureOf[signers[i]]);
        }

        // Execute tx.
        // vm.broadcast(SENDER);
        SAFE.execTransaction(
            txData.to,
            txData.value,
            txData.data,
            txData.operation,
            txData.safeTxGas,
            txData.baseGas,
            txData.gasPrice,
            txData.gasToken,
            txData.refundReceiver,
            txData.signatures
        );
        vm.stopBroadcast();
    }

    function loadSignatures(bytes32 dataHash) internal {
        bytes memory line = bytes(vm.readLine(SIGNATURES_FILE));

        while (line.length > 0 && signatures.length < THRESHOLD) {
            parseSignature(dataHash, line);

            line = bytes(vm.readLine(SIGNATURES_FILE));
        }

        uint256 nbSignatures = signatures.length;
        require(
            nbSignatures >= THRESHOLD,
            string.concat(
                "Not enough signatures (found: ", vm.toString(nbSignatures), "; expected: ", vm.toString(THRESHOLD), ")"
            )
        );
    }

    function parseSignature(bytes32 dataHash, bytes memory line) internal {
        require(
            line.length == 132,
            string.concat(
                "Malformed signature: ", string(line), " (length: ", vm.toString(line.length), "; expected: 132)"
            )
        );

        bytes memory hexSignature = new bytes(130);
        for (uint256 j; j < 130; ++j) {
            hexSignature[j] = line[j + 2];
        }

        bytes memory signature = vm.parseBytes(string(hexSignature));

        (address signer, bytes32 r, bytes32 s, uint8 v) = decode(dataHash, signature);
        require(signatureOf[signer].length == 0, string.concat("Duplicate signature: ", string(line)));

        signatureOf[signer] = abi.encodePacked(r, s, v + 4);
        signatures.push(signature);
        signers.push(signer);
    }
}
