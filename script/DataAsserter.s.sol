// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../contracts/DataAsserter.sol";

contract DataAsserterScript is Script {

    address currency;
    address optimisticOracleV3;

    function run() external {

        currency = vm.envAddress("CURRENCY_ADDRESS");
        optimisticOracleV3 = vm.envAddress("OOV3_ADDRESS");
        
        // uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        // vm.startBroadcast(deployerPrivateKey);
        vm.startBroadcast();
        DataAsserter carbonUMArket = new DataAsserter(currency, optimisticOracleV3);
        vm.stopBroadcast();
    }
}
