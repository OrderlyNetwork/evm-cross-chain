pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "./CrossChainManagerSetup.t.sol";
import "../contracts/interface/IOrderlyCrossChain.sol";

contract CrossChainManagerTest is Test, CrossChainManagerSetup {
    event MessageSent(OrderlyCrossChainMessage.MessageV1 message, bytes payload);
    event MessageReceived(OrderlyCrossChainMessage.MessageV1 message, bytes payload);

    CrossChainManagerFactory factory;

    function setUp() public {
        deployCrossChainManager();
        setupCrossChainManager();
        factory = new CrossChainManagerFactory();
    }

    function test_sendTestWithdrawMessage() public {
        (bool suc1,) = payable(_dstRelayProxy).call{value: 1 ether}("");
        (bool suc2,) = payable(_srcRelayProxy).call{value: 1 ether}("");
        require(suc1 && suc2, "failed to send ether to relays");

        OrderlyCrossChainMessage.MessageV1 memory message = OrderlyCrossChainMessage.MessageV1({
            method: uint8(OrderlyCrossChainMessage.CrossChainMethod.Withdraw),
            option: uint8(OrderlyCrossChainMessage.CrossChainOption.LayerZero),
            payloadDataType: uint8(OrderlyCrossChainMessage.PayloadDataType.EventTypesWithdrawData),
            srcCrossChainManager: address(_ledgerManagerProxy),
            dstCrossChainManager: address(_vaultManagerProxy),
            srcChainId: _dstChainId,
            dstChainId: _srcChainId
        });

        vm.expectEmit(true, false, false, false);
        emit MessageReceived(message, bytes(""));

        vm.expectEmit(true, false, false, false);
        emit MessageReceived(message, bytes(""));

        vm.expectEmit(true, false, false, false);
        emit MessageSent(message, bytes(""));

        vm.expectEmit(true, false, false, false);
        emit MessageSent(message, bytes(""));

        _ledgerManagerProxy.sendTestWithdraw(_srcChainId);
    }

    function testFail_vaultUpgradeTo(address newImplementation) public {
        _vaultManagerProxy.upgradeTo(newImplementation);
    }

    function testFail_ledgerUpgradeTo(address newImplementation) public {
        _ledgerManagerProxy.upgradeTo(newImplementation);
    }

    function test_upgradeTo() public {
        _vaultManagerProxy.upgradeTo(address(new VaultCrossChainManagerUpgradeable()));
        _ledgerManagerProxy.upgradeTo(address(new LedgerCrossChainManagerUpgradeable()));
    }

    function testFuzz_tokenDecimal(
        bytes32 tokenHash,
        uint256 chainId1,
        uint256 chainId2,
        uint128 decimal1,
        uint128 decimal2,
        uint128 tokenAmount
    ) public {
        vm.assume(decimal1 < 24 && decimal2 < 24);
        vm.assume(decimal1 > decimal2);
        vm.assume(decimal1 - decimal2 <= 12);
        vm.assume(tokenAmount < 340_000_000_000_000_000_000_000_000);
        vm.assume(chainId1 != chainId2);
        _ledgerManagerProxy.setTokenDecimal(tokenHash, chainId1, decimal1);
        _ledgerManagerProxy.setTokenDecimal(tokenHash, chainId2, decimal2);

        _ledgerManagerProxy.convertDecimal(tokenAmount, tokenHash, chainId1, chainId2);
        _ledgerManagerProxy.convertDecimal(tokenAmount, tokenHash, chainId2, chainId1);

        // assertEq(convertedAmount, tokenAmount * (10 ** decimal2) / (10 ** decimal1));

        // _ledgerManagerProxy.setTokenDecimal(tokenHash, chainId1, decimal2);
        // _ledgerManagerProxy.setTokenDecimal(tokenHash, chainId2, decimal1);

        // convertedAmount = _ledgerManagerProxy.convertDecimal(tokenAmount, tokenHash, chainId1, chainId2);

        // assertEq(convertedAmount, tokenAmount * (10 ** decimal1) / (10 ** decimal2));
    }

    function test_notOwnerSetTokenDecimalFail() public {
        LedgerCrossChainManagerUpgradeable ledgerManagerProxy =
            LedgerCrossChainManagerUpgradeable(address(factory.newLedgerCrossChainManager()));

        vm.expectRevert("Ownable: caller is not the owner");
        ledgerManagerProxy.setTokenDecimal(bytes32(0), 0, 0);
    }
}
