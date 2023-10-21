// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;
import "./CarbonUMArket.Common.sol";

contract CarbonUMArketPositionTest is CarbonUMArketTestCommon {
    bytes32 marketId;
    CarbonUMArket.Market market;

    function setUp() public {
        _commonCarbonUMArketSetUp();
        marketId = _initializeMarket();
        market = carbonUMArket.getMarket(marketId);
    }

    function test_MintCredits() public {
        // _fundCurrencyForMinting(TestAddress.account2);
        // uint256 minterBalanceBefore = defaultCurrency.balanceOf(TestAddress.account1);
        // vm.startPrank(TestAddress.account1);
        // carbonUMArket.mintCredit(marketId, creditCap / 2);
        _fundCurrencyForMinting(TestAddress.account2);
        uint256 minterBalanceBefore = defaultCurrency.balanceOf(TestAddress.account2);
    //    _mintCredits(marketId);
        vm.prank(TestAddress.account2);
        carbonUMArket.mintCredit(marketId, creditCap / 2);
        assertEq(defaultCurrency.balanceOf(TestAddress.account2), minterBalanceBefore - creditCap * 1e18 / 2 );
        assertEq(IERC20(market.convertibleCarbonCredit).balanceOf(TestAddress.account2), creditCap  / 2);
    
        vm.expectRevert(bytes(string.concat("Only ", Strings.toString(creditCap - creditCap / 2), " tokens left!")));
        vm.prank(TestAddress.account2);
        carbonUMArket.mintCredit(marketId, creditCap);
        
    }

    

    function test_RevertIf_SettleEarly() public {
        _fundCurrencyForMinting(TestAddress.account1);
        vm.prank(TestAddress.account1);
        carbonUMArket.mintCredit(marketId, creditCap / 2);
        _changeState(marketId, 1);
        _assertMarket(marketId);

        vm.expectRevert("Market not ready for settle!");
        carbonUMArket.settleMarket(marketId);

    }

    function test_Settle() public {
        
        _mintCredits(marketId);
        
        _changeState(marketId, 1);
        bytes32 assertionId = _assertMarket(marketId);

        _registerValidator(marketId);
        uint256 account3BalanceBefore = defaultCurrency.balanceOf(TestAddress.account3);

        _settleAssertionAndTokens(assertionId);

        // Verify the holder of first outcome tokens got all the payout.
        assertEq(IERC20(market.carbonCredit).balanceOf(TestAddress.account2), 0);
        assertEq(defaultCurrency.balanceOf(TestAddress.account3), account3BalanceBefore + reward);
    }

}
