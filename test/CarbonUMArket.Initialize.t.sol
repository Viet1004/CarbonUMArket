// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;
import "./CarbonUMArket.Common.sol";

contract CarbonUMArketInitializeTest is CarbonUMArketTestCommon {
    function setUp() public {
        _commonCarbonUMArketSetUp();
    }

    function test_ContractParameters() public {
        assertEq(address(carbonUMArket.finder()), address(finder));
        assertEq(address(carbonUMArket.currency()), address(defaultCurrency));
        assertEq(address(carbonUMArket.oo()), address(optimisticOracleV3));
        assertEq(carbonUMArket.defaultIdentifier(), defaultIdentifier);
    }


    function test_RevertIf_DuplicateMarket() public {
        vm.prank(TestAddress.owner);
        carbonUMArket.initializeMarket(reward, requiredBond, creditCap, description, marketOpeningPeriod, examinationPeriod);

        _fundInitializationReward();
        vm.expectRevert("Market already exists");
        vm.prank(TestAddress.owner);
        carbonUMArket.initializeMarket(reward, requiredBond, creditCap, description, marketOpeningPeriod, examinationPeriod);
    }

    function test_DuplicateMarketNextBlock() public {
        vm.prank(TestAddress.owner);
        bytes32 firstMarketId =
            carbonUMArket.initializeMarket(reward, requiredBond, creditCap, description, marketOpeningPeriod, examinationPeriod);

        // Next block should allow initializing market with the same parameters, but different marketId.
        vm.roll(block.number + 1);
        _fundInitializationReward();
        vm.prank(TestAddress.owner);
        bytes32 secondMarketId =
            carbonUMArket.initializeMarket(reward, requiredBond, creditCap, description, marketOpeningPeriod, examinationPeriod);
        assertFalse(firstMarketId == secondMarketId);
    }

    function test_RewardPulledOnInitialization() public {
        vm.prank(TestAddress.owner);
        carbonUMArket.initializeMarket(reward, requiredBond, creditCap, description, marketOpeningPeriod, examinationPeriod);
        assertEq(defaultCurrency.balanceOf(address(carbonUMArket)), requiredBond);
    }
}
