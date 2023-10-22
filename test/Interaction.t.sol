// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.12;
// import "./common/CommonOptimisticOracleV3Test.sol";
// import "../contracts/DataAsserter.sol";
// import "../contracts/CarbonUMArket.sol";
// import "./CarbonUMArket.Common.sol";


// contract InteractionTest is CarbonUMArketTestCommon {
//     address public dataAsserterAddress;
//     bytes32 marketId;
//     bytes32 dataId = bytes32("dataId");
//     string correctDataPath = "correctData";
//     string incorrectDataPath = "incorrectData";
//     string description_ = "description";

//     function setUp() public {
//         _commonCarbonUMArketSetUp();
//         marketId = _initializeMarket();
//         _changeState(marketId, 1);
//         _registerValidator(marketId);
//     }

//     function test_initializeDataPool() public {
//         vm.expectRevert("Only validator can initialize data pool");
//         vm.prank(TestAddress.account2);
//         dataAsserterAddress = carbonUMArket.initializeDataPool(marketId, address(optimisticOracleV3));
//     }

//     function test_submitAndAssertData() public {
//         vm.prank(TestAddress.account3);
//         dataAsserterAddress = carbonUMArket.initializeDataPool(marketId, address(optimisticOracleV3));
// //        DataAsserter dataAsserterInstance = DataAsserter(dataAsserterAddress);
//         vm.expectRevert("Only validator can submit data");
//         vm.prank(TestAddress.account2);
//         carbonUMArket.submitAndAssertData(marketId, dataId, correctDataPath, description_, dataAsserterAddress);
//     }

//     function test_settleValidatorToken() public {
//         _fundCurrencyForMinting(TestAddress.account3);
//         vm.prank(TestAddress.account3);
//         dataAsserterAddress = carbonUMArket.initializeDataPool(marketId, address(optimisticOracleV3));
// //        DataAsserter dataAsserterInstance = DataAsserter(dataAsserterAddress);
//         vm.prank(TestAddress.account3);
        
//         bytes32 assertionId = carbonUMArket.submitAndAssertData(marketId, dataId, correctDataPath, description_, dataAsserterAddress);
        
//         timer.setCurrentTime(timer.getCurrentTime() + DataAsserter(dataAsserterAddress).assertionLiveness());

//         optimisticOracleV3.settleAssertion(assertionId);

//         _changeState(marketId, 2);
//         vm.prank(TestAddress.account3);
//         carbonUMArket.settleValidatorToken(marketId, dataAsserterAddress);
//         assertEq(IERC20(carbonUMArket.getMarket(marketId).validatorToken).balanceOf(TestAddress.account3), 2);
//     }
// }