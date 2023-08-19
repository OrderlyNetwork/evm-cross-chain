// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../baseScripts/BaseScript.s.sol";
import "forge-std/console.sol";
import "../contracts/CrossChainRelayUpgradeable.sol";
import "../contracts/utils/OrderlyCrossChainMessage.sol";
import "../baseScripts/Utils.sol";

struct SampleJson {
    address age;
    string name;
}

contract SampleJsonIO is BaseScript {
    using StringUtils for string;

    function run() external {
        vm.createDir("config", true);
        string memory data = vm.readFile("./forgeScripts/sample.json");
        bytes memory abiEncodeData = vm.parseJson(data);
        address anotherAbiEncodeData = vm.parseJsonAddress(data, ".age");

        vm.setEnv("xxx", "123");

        SampleJson memory sampleJson = abi.decode(abiEncodeData, (SampleJson));

        string memory data3 = data.toUpperCase();
        console.logString(data3);

        console.logString(data3.toUpperCase());
        console.logString(data3.formJsonKey());
        console.logString(data3.concat(data));

        console.logString(sampleJson.name);
        console.logAddress(sampleJson.age);

        // log
        console.logBytes(abiEncodeData);
        console.logAddress(anotherAbiEncodeData);
    }

}
