// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract WrongImplementationData {
    uint256 public data;
}

contract WrongImplementation is WrongImplementationData, UUPSUpgradeable, OwnableUpgradeable {
    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function upgradeTo(address newImplementation) public override onlyOwner onlyProxy {
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }
}
