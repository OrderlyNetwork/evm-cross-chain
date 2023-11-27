// SPDX-LICENSE-Identifier: MIT
pragma solidity ^0.8.17;

library StringUtils {
    function compare(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function equal(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function toUpperCase(string memory a) internal pure returns (string memory) {
        // clone a, do not modify input
        bytes memory b = bytes(a);
        bytes memory c = new bytes(b.length);
        for (uint256 i = 0; i < b.length; i++) {
            if ((b[i] >= 0x61) && (b[i] <= 0x7A)) {
                c[i] = bytes1(uint8(b[i]) - 0x20);
            } else {
                c[i] = b[i];
            }
        }
        return string(c);
    }

    function toLowerCase(string memory a) internal pure returns (string memory) {
        // clone a, do not modify input
        bytes memory b = bytes(a);
        bytes memory c = new bytes(b.length);
        for (uint256 i = 0; i < b.length; i++) {
            if ((b[i] >= 0x41) && (b[i] <= 0x5A)) {
                c[i] = bytes1(uint8(b[i]) + 0x20);
            } else {
                c[i] = b[i];
            }
        }
        return string(c);
    }

    function concat(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

    function formJsonKey(string memory a) internal pure returns (string memory) {
        return string(abi.encodePacked(".", a));
    }
}
