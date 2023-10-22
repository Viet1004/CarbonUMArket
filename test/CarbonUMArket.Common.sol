// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;
import "./common/CommonOptimisticOracleV3Test.sol";
import "../contracts/CarbonUMArket.sol";

// import "@uma/core/contracts/optimistic-oracle-v3/implementation/examples/carbonUMArket.sol";

contract CarbonUMArketTestCommon is CommonOptimisticOracleV3Test {
    CarbonUMArket public carbonUMArket;
    string description = "This is a project in Brazil";
    uint256 reward = 1000e12;
    uint256 requiredBond;
    uint256 creditCap = 10000;

    function _commonCarbonUMArketSetUp() public {
        _commonSetup();
        // carbonUMArket = new CarbonUMArket(address(finder), address(defaultCurrency), address(optimisticOracleV3));
        carbonUMArket = new CarbonUMArket(address(defaultCurrency), address(optimisticOracleV3));
        uint256 minimumBond = optimisticOracleV3.getMinimumBond(address(defaultCurrency));
        requiredBond = minimumBond < 1000e12 ? 1000e12 : minimumBond; // Make sure the bond is sufficient.
        _fundInitializationReward();
    }

    function _fundInitializationReward() internal {
        defaultCurrency.allocateTo(TestAddress.owner,  requiredBond + reward);
        vm.prank(TestAddress.owner);
        defaultCurrency.approve(address(carbonUMArket),  requiredBond + reward);
    }

    function _changeState(bytes32 marketId, uint64 state) internal {
        vm.prank(TestAddress.owner);
        carbonUMArket.changeMarketState(marketId, state);
    }

    function _initializeMarket() internal returns (bytes32) {
        _fundInitializationReward();
        vm.prank(TestAddress.owner);
        return carbonUMArket.initializeMarket(reward, requiredBond, creditCap, description);
    }

    function _fundAssertionBond() internal {
        defaultCurrency.allocateTo(TestAddress.account1,  requiredBond);
        vm.prank(TestAddress.account1);
        defaultCurrency.approve(address(carbonUMArket),  requiredBond);
    }

    function _assertMarket(bytes32 marketId) internal returns (bytes32 assertionId) {
        _fundAssertionBond();
        _changeState(marketId, 1);
        vm.prank(TestAddress.account1);
        assertionId = carbonUMArket.declareFalsePromise(marketId);
    }

    function _fundCurrencyForMinting(address account) internal {
        defaultCurrency.allocateTo(account, 2 * creditCap * 1e12);
        vm.prank(account);
        defaultCurrency.approve(address(carbonUMArket), 2 * creditCap * 1e12);
    }

    function _mintCredits(bytes32 marketId) internal {
        _fundCurrencyForMinting(TestAddress.account2);
        _changeState(marketId, 0);
        vm.prank(TestAddress.account2);
        carbonUMArket.mintCredit(marketId, creditCap / 2);
    }

    function _registerValidator(bytes32 marketId) internal {
        _fundCurrencyForMinting(TestAddress.account3);
        _changeState(marketId, 1);
        vm.prank(TestAddress.account3);
        carbonUMArket.registerValidator(marketId);
    }

    function _settleAssertionAndTokens(bytes32 assertionId) internal {
        (, bytes32 marketId) = carbonUMArket.assertedMarkets(assertionId);
        CarbonUMArket.Market memory market = carbonUMArket.getMarket(marketId);

        _changeState(marketId, 2);

        // Settle the assertion after liveness.
        timer.setCurrentTime(timer.getCurrentTime() + defaultLiveness );
        assertTrue(optimisticOracleV3.settleAndGetAssertionResult(assertionId));
        // Settle the outcome tokens.
        vm.prank(TestAddress.account2);
        carbonUMArket.settleMarket(marketId, 0);
        assertEq(IERC20(market.validatorToken).balanceOf(TestAddress.account3), 1);
        assertTrue(market.promiseDelivered);
        
        vm.prank(TestAddress.account3);
        carbonUMArket.settleMarket(marketId, 10000);

        // Verify the outcome tokens were burned.
        assertEq(IERC20(market.convertibleCarbonCredit).balanceOf(TestAddress.account2), 0);
        assertEq(IERC20(market.validatorToken).balanceOf(TestAddress.account3), 0);
    }
}
