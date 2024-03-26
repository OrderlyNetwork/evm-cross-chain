// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./BaseScript.s.sol";
import "./OperationHelper.s.sol";
import "./Utils.sol";

import "evm-cross-chain/contracts/axelar/AxelarCCAdapter.sol";
import "evm-cross-chain/contracts/OrderlyProxy.sol";


contract RelayHelper is BaseScript, OperationHelper {
    using StringUtils for string;

    function upgradeAxelarAdapter(address proxyAddress) internal returns (address) {
        AxelarCCAdapter adapter = new AxelarCCAdapter();
        AxelarCCAdapter proxy = AxelarCCAdapter(payable(proxyAddress));
        adapter.upgradeTo(address(this));
        return address(adapter);
    }

    function deployAxelarAdapter() internal returns (address, address) {
        AxelarCCAdapter adapter = new AxelarCCAdapter();
        OrderlyProxy proxy = new OrderlyProxy(address(adapter), "");
        adapter.initialize();
        return (address(adapter), address(proxy));
    }

    function setAxelarAdapterConfig(address proxyAddress, address gasService, address gateway) internal {
        AxelarCCAdapter adapter = AxelarCCAdapter(payable(proxyAddress));
        adapter.setAxelarConfig(gasService, gateway);
    }

    function setAxelarChainsConfig(address proxy, uint256 chainId, string memory chainName, string memory uaAddress) internal {
        AxelarCCAdapter adapter = AxelarCCAdapter(payable(proxy));
        adapter.setChainId2Name(chainId, chainName, uaAddress);
    }
}