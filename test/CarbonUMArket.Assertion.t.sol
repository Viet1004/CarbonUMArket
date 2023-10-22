// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;
import "./CarbonUMArket.Common.sol";


contract CarbonUMArketAssertionTest is CarbonUMArketTestCommon {
    bytes32 marketId;

    function setUp() public {
        _commonCarbonUMArketSetUp();
        marketId = _initializeMarket();
    }

    function test_AssertionMade() public {
        uint256 ooBalanceBefore = defaultCurrency.balanceOf(address(optimisticOracleV3));
        // Make assertion and verify bond posted to Optimistic Oracle V3.

        _changeState(marketId, 1);

        bytes32 assertionId = _assertMarket(marketId);
        assertEq(defaultCurrency.balanceOf(address(optimisticOracleV3)), ooBalanceBefore + requiredBond);

        // Verify carbonUMArket storage.
//        CarbonUMArket.Market memory market = carbonUMArket.getMarket(marketId);
        (address storedAsserter, bytes32 storedMarketId) = carbonUMArket.assertedMarkets(assertionId);
        assertEq(storedAsserter, TestAddress.account1);
        assertEq(storedMarketId, marketId);
        


        // Verify OptimisticOracleV3 storage.
        OptimisticOracleV3Interface.Assertion memory assertion = optimisticOracleV3.getAssertion(assertionId);
        assertEq(assertion.asserter, TestAddress.account1);
        assertEq(assertion.callbackRecipient, address(carbonUMArket));
        assertEq(address(assertion.currency), address(defaultCurrency));
        assertEq(assertion.bond, requiredBond);
        
        assertEq(assertion.assertionTime, block.timestamp);
        
//        assertEq(assertion.expirationTime, block.timestamp + defaultLiveness);
        
        assertEq(assertion.identifier, defaultIdentifier);
        assertEq(assertion.escalationManagerSettings.assertingCaller, address(carbonUMArket));
        
    }

    function test_AssertMinimumBond() public {
        // Initialize second market with 0 required bond.
        _fundInitializationReward();
        vm.roll(block.number + 1);
        vm.prank(TestAddress.owner);
        bytes32 secondMarketId = carbonUMArket.initializeMarket( reward, 0, creditCap, description);
        uint256 ooBalanceBefore = defaultCurrency.balanceOf(address(optimisticOracleV3));
        uint256 minimumBond = optimisticOracleV3.getMinimumBond(address(defaultCurrency));


        // Make assertion and verify minimum bond posted to Optimistic Oracle V3.
        _changeState(secondMarketId, 1);
        _assertMarket(secondMarketId);
        assertEq(defaultCurrency.balanceOf(address(optimisticOracleV3)), ooBalanceBefore + minimumBond);
    }

    // function test_DisputeCallbackReceived() public {
    //     bytes32 assertionId = _assertMarket(marketId, outcome1);

    //     vm.expectCall(
    //         address(carbonUMArket),
    //         abi.encodeCall(carbonUMArket.assertionDisputedCallback, (assertionId))
    //     );
    //     _disputeAndGetOracleRequest(assertionId, requiredBond);
    // }
}
