// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../contracts/CarbonUMArket.sol";

contract CarbonUMArketScript is Script {

    address finder;
    address currency;
    address optimisticOracleV3;

    function run() external {
        finder = vm.envAddress("FINDER_ADDRESS");
        currency = vm.envAddress("CURRENCY_ADDRESS");
        optimisticOracleV3 = vm.envAddress("OOV3_ADDRESS");
        
        // uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        // vm.startBroadcast(deployerPrivateKey);
        vm.startBroadcast();
        CarbonUMArket carbonUMArket = new CarbonUMArket(finder, currency, optimisticOracleV3);
        vm.stopBroadcast();
    }
}
