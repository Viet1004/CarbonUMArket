import * as dotenv from "dotenv";

import { HardhatUserConfig } from "hardhat/config";

require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-foundry");

dotenv.config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.16",
  networks: {
    scrollTestnet: {
      url: process.env.SCROLL_TESTNET_URL || "",
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
  },
  etherscan: {
    apiKey: process.env.REACT_APP_ETHERSCAN_KEY,
  },
};
