// SPDX-LICENSE-Identifier: MIT
pragma solidity ^0.8.17;


library StringCompare {
    function compare(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}