// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;
import "./CarbonUMArket.Common.sol";
import "forge-std/console.sol";


contract CarbonUMArketResolveTest is CarbonUMArketTestCommon {
    bytes32 marketId;

    function setUp() public {
        _commonCarbonUMArketSetUp();
        marketId = _initializeMarket();
        _mintCredits(marketId);
        _registerValidator(marketId);
    }

    function test_ResolveMarketNoDispute() public {
        
        CarbonUMArket.Market memory market = carbonUMArket.getMarket(marketId);

        bytes32 assertionId = _assertMarket(marketId);
        uint256 asserterBalanceBefore = defaultCurrency.balanceOf(TestAddress.account1);
        // Advance time past liveness and settle the assertion. This should trigger truthful assertionResolvedCallback.
        timer.setCurrentTime(timer.getCurrentTime() + defaultLiveness );
        vm.expectCall(
            address(carbonUMArket),
            abi.encodeCall(carbonUMArket.assertionResolvedCallback, (assertionId, true))
        );
        assertTrue(optimisticOracleV3.settleAndGetAssertionResult(assertionId));

        // Verify the asserter received back the bond and reward.
        assertEq(defaultCurrency.balanceOf(TestAddress.account1), asserterBalanceBefore + 2 * requiredBond );

        assertTrue(carbonUMArket.getMarket(marketId).marketState == 2);
        // Verify the amount of CarbonCredit of account2
        vm.prank(TestAddress.account2);
        carbonUMArket.settleMarket(marketId, 0);
        assertEq(IERC20(market.carbonCredit).balanceOf(TestAddress.account2), 0);
        
    }

    function test_ResolveMarketWithWrongDispute() public {

        CarbonUMArket.Market memory market = carbonUMArket.getMarket(marketId);
        
        bytes32 assertionId = _assertMarket(marketId);
        uint256 asserterBalanceBefore = defaultCurrency.balanceOf(TestAddress.account1);

        uint256 validatorBalanceBefore = defaultCurrency.balanceOf(TestAddress.account3);

        // Dispute the assertion, but resolve it true at the Oracle. This should trigger truthful assertionResolvedCallback.
        OracleRequest memory oracleRequest = _disputeAndGetOracleRequest(assertionId, requiredBond);
        _mockOracleResolved(address(mockOracle), oracleRequest, true);
        vm.expectCall(
            address(carbonUMArket),
            abi.encodeCall(carbonUMArket.assertionResolvedCallback, (assertionId, true))
        );
        assertTrue(optimisticOracleV3.settleAndGetAssertionResult(assertionId));

        // Verify the asserter received back the bond, reward and half of disputer bond.
        assertEq(
            defaultCurrency.balanceOf(TestAddress.account1),
            asserterBalanceBefore + requiredBond * 5 / 2
        );


        // Verify the amount of CarbonCredit of account2
        vm.prank(TestAddress.account2);
        carbonUMArket.settleMarket(marketId, 0);
        assertEq(IERC20(market.carbonCredit).balanceOf(TestAddress.account2), 0);

        // Verify the balance of validator doesn't change
        vm.prank(TestAddress.account3);
        carbonUMArket.settleMarket(marketId, 10000);
        assertEq(defaultCurrency.balanceOf(TestAddress.account3), validatorBalanceBefore + market.reward);

    }

    function test_AssertionWithCorrectDispute() public {
        
        CarbonUMArket.Market memory market = carbonUMArket.getMarket(marketId);

        bytes32 assertionId = _assertMarket(marketId);
        uint256 asserterBalanceBefore = defaultCurrency.balanceOf(TestAddress.account1);

        uint256 validatorBalanceBefore = defaultCurrency.balanceOf(TestAddress.account3);

        // Dispute the assertion, but resolve it false at the Oracle. This should trigger false assertionResolvedCallback.
        OracleRequest memory oracleRequest = _disputeAndGetOracleRequest(assertionId, requiredBond);
        _mockOracleResolved(address(mockOracle), oracleRequest, false);
        vm.expectCall(
            address(carbonUMArket),
            abi.encodeCall(carbonUMArket.assertionResolvedCallback, (assertionId, false))
        );
        assertFalse(optimisticOracleV3.settleAndGetAssertionResult(assertionId));

        assertEq(
            defaultCurrency.balanceOf(TestAddress.account1),
            asserterBalanceBefore
        );

        // Verify resolved in CarbonUMArket storage.
//        assertTrue(market.marketState == 2);

        // Verify the amount of CarbonCredit of account2
        vm.prank(TestAddress.account2);
        carbonUMArket.settleMarket(marketId, 0);

        assertEq(IERC20(market.carbonCredit).balanceOf(TestAddress.account2), creditCap / 2);

        // Verify the balance of validator doesn't change
        vm.prank(TestAddress.account3);
        carbonUMArket.settleMarket(marketId, 10000);
        console.log("validatorBalanceBefore", validatorBalanceBefore);
        console.log(defaultCurrency.balanceOf(TestAddress.account3));
        assertEq(defaultCurrency.balanceOf(TestAddress.account3), validatorBalanceBefore);

    }

    // function test_ResolveMarketAfterCorrectDispute() public {
    //     bytes32 assertionId = _assertMarket(marketId, outcome1);

    //     // Dispute the assertion, but resolve it false at the Oracle.
    //     OracleRequest memory oracleRequest = _disputeAndGetOracleRequest(assertionId, requiredBond);
    //     _mockOracleResolved(address(mockOracle), oracleRequest, false);
    //     assertFalse(optimisticOracleV3.settleAndGetAssertionResult(assertionId));

    //     // Assert the second outcome and settle after the liveness.
    //     bytes32 secondAssertionId = _assertMarket(marketId, outcome2);
    //     timer.setCurrentTime(timer.getCurrentTime() + defaultLiveness);

    //     assertTrue(optimisticOracleV3.settleAndGetAssertionResult(secondAssertionId));

    //     // Verify the second outcome resolved in CarbonUMArket storage.
    //     CarbonUMArket.Market memory market = carbonUMArket.getMarket(marketId);
    //     assertTrue(market.resolved);
    //     assertEq(market.assertedOutcomeId, keccak256(bytes(outcome2)));
    // }
}
