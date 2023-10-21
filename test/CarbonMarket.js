const { expect } = require('chai');

const {
    loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { ethers } = require('hardhat');

require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-waffle");


describe('CarbonMarket', function () {
    // async function deployMarketFixture() {
    //     const [owner, addr1, addr2, addr3, random] = await ethers.getSigners();

    //     const carbonMarket = await ethers.getContractFactory('CarbonMarket');

    //     const hardhatCarbonMarket = await carbonMarket.deploy(); // Add arguments inside the parentheses, they are finder, currency, and OOV3

    //     return {carbonMarket, market, addr1, addr2};
    // } 

    it("Market initialization", async function () {
        const predictionTest = await ethers.deployContract("PredictionMarket");
        predictionTest.test_ContractParameters();
    });
});