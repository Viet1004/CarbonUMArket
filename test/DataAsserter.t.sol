// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.12;
import "./common/CommonOptimisticOracleV3Test.sol";
import "../contracts/DataAsserter.sol";
import "forge-std/console.sol";

contract DataAsserterTest is CommonOptimisticOracleV3Test {
    DataAsserter public dataAsserter;
    bytes32 dataId = bytes32("dataId");
    string correctData = "correctData";
    string incorrectData = "incorrectData";
    string description_ = "description";


    function setUp() public {
        _commonSetup();
        dataAsserter = new DataAsserter(address(defaultCurrency), address(optimisticOracleV3));
    }

    function test_DataAssertionNoDispute() public {
        // Assert data.
        vm.startPrank(TestAddress.account1);
        defaultCurrency.allocateTo(TestAddress.account1, optimisticOracleV3.getMinimumBond(address(defaultCurrency)));
        defaultCurrency.approve(address(dataAsserter), optimisticOracleV3.getMinimumBond(address(defaultCurrency)));
        bytes32 assertionId = dataAsserter.assertDataFor(dataId, correctData, description_);
        vm.stopPrank(); // Return caller address to standard.

        // Store the balance of validator tokens before the assertion.
        uint256 balancesBeforeAssertion = dataAsserter.validatorToken().balanceOf(TestAddress.account1);
        vm.prank(TestAddress.account1);
        assertEq(dataAsserter.checkTokenBalance(),0);

        // Assertion data should not be available before the liveness period.
        (bool dataAvailable, string memory dataPath, string memory description) = dataAsserter.getData(assertionId);
        assertFalse(dataAvailable);

        // Move time forward to allow for the assertion to expire.
        timer.setCurrentTime(timer.getCurrentTime() + dataAsserter.assertionLiveness());

        // Settle the assertion.
        optimisticOracleV3.settleAssertion(assertionId);

        // Data should now be available.
        (dataAvailable, dataPath, description) = dataAsserter.getData(assertionId);
        assertTrue(dataAvailable);
        assertEq(dataPath, correctData);

        // Check that the validator token was minted.
        assertEq(
            dataAsserter.validatorToken().balanceOf(TestAddress.account1),
            balancesBeforeAssertion + 1
        );

        vm.prank(TestAddress.account1);
        assertEq(dataAsserter.checkTokenBalance(),1);
    }

    function test_DataAssertionWithWrongDispute() public {
        // Assert data.
        vm.startPrank(TestAddress.account1);
        defaultCurrency.allocateTo(TestAddress.account1, optimisticOracleV3.getMinimumBond(address(defaultCurrency)));
        defaultCurrency.approve(address(dataAsserter), optimisticOracleV3.getMinimumBond(address(defaultCurrency)));
        bytes32 assertionId = dataAsserter.assertDataFor(dataId, correctData, description_);
        vm.stopPrank(); // Return caller address to standard.

        // Store the balance of validator tokens before the assertion.
        uint256 balancesBeforeAssertion = dataAsserter.validatorToken().balanceOf(TestAddress.account1);

        // Dispute assertion with Account2 and DVM votes that the original assertion was true.
        OracleRequest memory oracleRequest = _disputeAndGetOracleRequest(assertionId, defaultBond);
        _mockOracleResolved(address(mockOracle), oracleRequest, true);
        assertTrue(optimisticOracleV3.settleAndGetAssertionResult(assertionId));

        (bool dataAvailable, string memory dataPath, ) = dataAsserter.getData(assertionId);
        assertTrue(dataAvailable);
        assertEq(dataPath, correctData);

        // Check that the validator token was minted.
        assertEq(
            dataAsserter.validatorToken().balanceOf(TestAddress.account1),
            balancesBeforeAssertion + 1
        );
    }

    function test_DataAssertionWithCorrectDispute() public {
        // Assert data.
        vm.startPrank(TestAddress.account1);
        defaultCurrency.allocateTo(TestAddress.account1, optimisticOracleV3.getMinimumBond(address(defaultCurrency)));
        defaultCurrency.approve(address(dataAsserter), optimisticOracleV3.getMinimumBond(address(defaultCurrency)));
        bytes32 assertionId = dataAsserter.assertDataFor(dataId, incorrectData, description_);
        vm.stopPrank(); // Return caller address to standard.

        // Store the balance of validator tokens before the assertion.
        uint256 balancesBeforeAssertion = dataAsserter.validatorToken().balanceOf(TestAddress.account1);

        // Dispute assertion with Account2 and DVM votes that the original assertion was wrong.
        OracleRequest memory oracleRequest = _disputeAndGetOracleRequest(assertionId, defaultBond);
        _mockOracleResolved(address(mockOracle), oracleRequest, false);
        assertFalse(optimisticOracleV3.settleAndGetAssertionResult(assertionId));

        // Check that the validator token was not minted.
        assertEq(
            dataAsserter.validatorToken().balanceOf(TestAddress.account1),
            balancesBeforeAssertion
        );

        // Check that the data assertion has been deleted
        (, , , address asserter, ) = dataAsserter.assertionsData(assertionId);
        assertEq(asserter, address(0));

        (bool dataAvailable, string memory dataPath, string memory description) = dataAsserter.getData(assertionId);
        assertFalse(dataAvailable);

        // Increase time in the evm
        vm.warp(block.timestamp + 1);

        // Same asserter should be able to re-assert the correct data.
        vm.startPrank(TestAddress.account1);
        defaultCurrency.allocateTo(TestAddress.account1, optimisticOracleV3.getMinimumBond(address(defaultCurrency)));
        defaultCurrency.approve(address(dataAsserter), optimisticOracleV3.getMinimumBond(address(defaultCurrency)));
        bytes32 ooAssertionId2 = dataAsserter.assertDataFor(dataId, correctData, description_);
        vm.stopPrank(); // Return caller address to standard.

        // Move time forward to allow for the assertion to expire.
        timer.setCurrentTime(timer.getCurrentTime() + dataAsserter.assertionLiveness());

        // Settle the assertion.
        optimisticOracleV3.settleAssertion(ooAssertionId2);

        // Data should now be available.
        (dataAvailable, dataPath, description) = dataAsserter.getData(ooAssertionId2);
        assertTrue(dataAvailable);
        assertEq(dataPath, correctData);
    }
}