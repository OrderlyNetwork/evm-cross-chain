// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SignatureDecoder} from "safe/common/SignatureDecoder.sol";
import {Safe, Enum} from "safe/Safe.sol";

import "forge-std/console2.sol";
import "forge-std/StdJson.sol";
import "forge-std/Script.sol";

import "../baseScripts/Utils.sol";

contract HashData is Script, SignatureDecoder {
    using stdJson for string;

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

    Safe SAFE;
    address internal SENDER;
    uint256 internal NONCE;
    uint256 internal THRESHOLD;
    bytes32 internal DOMAIN_SEPARATOR;

    string internal ROOT = vm.projectRoot();
    string internal SIGNATURES_DIR = string.concat(ROOT, "/data/");

    string internal TX_FILE = vm.envString("FS_hashData_txFile");
    string internal HASH_DATA_FILE = string.concat(SIGNATURES_DIR, "hashData.txt");
    string internal SIGNATURES_FILE = string.concat(SIGNATURES_DIR, "signatures.txt");

    function setUp() public {
        string memory network = vm.envString("FS_hashData_network");
        string memory networkUpCase = StringUtils.toUpperCase(network);
        uint256 pk = vm.envUint(string.concat(networkUpCase, "_PRIVATE_KEY"));
        SENDER = vm.addr(pk);
        string memory rpcUrl = vm.envString(string.concat("RPC_URL_", networkUpCase));
        vm.createSelectFork(rpcUrl);
        SAFE = Safe(payable(vm.envAddress("SAFE")));

        NONCE = vm.envOr("SAFE_NONCE", SAFE.nonce());
        THRESHOLD = SAFE.getThreshold();
        DOMAIN_SEPARATOR = SAFE.domainSeparator();
    }


    function loadSafeTxData() internal view returns (SafeTxData memory txData) {
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

    function run() public {
        SafeTxData memory txData = loadSafeTxData();

        bytes32 dataHash = hashData(txData);

        vm.writeFile(HASH_DATA_FILE, vm.toString(dataHash));
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

}
