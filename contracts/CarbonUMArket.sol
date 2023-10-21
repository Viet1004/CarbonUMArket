// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.12;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import "@uma/core/contracts/common/implementation/AddressWhitelist.sol";
import "@uma/core/contracts/common/implementation/ExpandedERC20.sol";
import "@uma/core/contracts/data-verification-mechanism/implementation/Constants.sol";
import "@uma/core/contracts/data-verification-mechanism/interfaces/FinderInterface.sol";
import "@uma/core/contracts/optimistic-oracle-v3/implementation/ClaimData.sol";
import "@uma/core/contracts/optimistic-oracle-v3/interfaces/OptimisticOracleV3Interface.sol";
import "@uma/core/contracts/optimistic-oracle-v3/interfaces/OptimisticOracleV3CallbackRecipientInterface.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./DataAsserter.sol";

contract CarbonUMArket is OptimisticOracleV3CallbackRecipientInterface{

    using SafeERC20 for IERC20;
    FinderInterface public immutable finder;
    IERC20 public immutable currency;
    OptimisticOracleV3Interface public immutable oo;
    OptimisticOracleV3Interface public data_oo;
    uint64 public constant assertionLiveness = 2 minutes;
    uint64 public constant validatorFee = 0.001e18;
    bytes32 public immutable defaultIdentifier;
    

    struct Market {
        address owner;
        uint256 requiredBond;
        uint256 reward; // Amount of default currency to be deposited as bond as a reward for the asserter
        uint256 creditCap;
        
        ExpandedIERC20 carbonCredit; // ERC20 token representing the credits of the total promised credits.
        ExpandedIERC20 convertibleCarbonCredit; // ERC20 token representing the credits that can be converted to carbon credits.
        ExpandedIERC20 validatorToken; // ERC20 token representing the belief that the institution cannot fulfil their promise.

        uint256 startingTime;
        uint256 openingPeriod;
        uint256 auditPeriod;

        string description;
        bool promiseDelivered;
        uint64 marketState; // 0 means market is open, 1 means market is closed and wait for audit, 2 means market is closed and audited.
    }

    struct AssertedMarket {
        address asserter;
        bytes32 marketId;
    }

    mapping (bytes32 => Market) public markets;

    mapping (bytes32 => AssertedMarket) public assertedMarkets;

    event MarketInitialized(
        bytes32 indexed marketId,
        string description,
        // uint256 startingTime,
        // uint256 openingPeriod,
        // uint256 auditPeriod,
        uint256 reward,
        uint256 requiredBond,
        address owner
        // address carbonCredit,
        // address convertibleCarbonCredit,
        // address validatorToken
    );

    event FalsePromisedDeclared(
        bytes32 indexed marketId,
        bytes32 indexed assertionId
    );

    event MarketResolved(bytes32 indexed marketId);

    event CreditsMinted(bytes32 indexed marketId, address indexed account, uint256 creditsMinted);

    event ValidatorRegistered(bytes32 indexed marketId, address indexed account);

    event MarketSettled(bytes32 indexed marketId, address indexed account, uint256 individualReward, uint256 creditReceived);

    constructor(
        address _finder,
        address _currency,
        address _optimisticOracleV3
    ){
        finder = FinderInterface(_finder);
        currency = IERC20(_currency);
        oo = OptimisticOracleV3Interface(_optimisticOracleV3);
        defaultIdentifier = oo.defaultIdentifier();
    }

    function getMarket(bytes32 marketId) public view returns (Market memory) {
        return markets[marketId];
    }

    function initializeMarket(
        uint256 _reward, // Amount of default currency to be deposited as bond as a reward for the asserter,
        uint256 _requiredBond, // Amount of default currency to be deposited as bond by the asserter,
        uint256 _creditCap,
        string memory _description,
        uint256 _openingPeriod,
        uint256 _auditPeriod
    ) public returns (bytes32 marketId) {
        marketId = keccak256(abi.encode(block.number, _creditCap, msg.sender, _description));
        require(markets[marketId].owner == address(0), "Market already exists");
        
        ExpandedIERC20 carbonCredit = new ExpandedERC20(string(abi.encodePacked(_description, " Credit")), "CC", 1);
        ExpandedIERC20 convertibleCarbonCredit = new ExpandedERC20(string(abi.encodePacked(_description, " Convertible Credit")), "CCC", 1);
        ExpandedIERC20 validatorToken = new ExpandedERC20(string(abi.encodePacked(_description, " Validator Token")), "VT", 1);

        carbonCredit.addMinter(address(this));
        convertibleCarbonCredit.addMinter(address(this));
        validatorToken.addMinter(address(this));
        
        carbonCredit.addBurner(address(this));
        convertibleCarbonCredit.addBurner(address(this));
        validatorToken.addBurner(address(this));

        uint256 startingTime = block.timestamp;

        markets[marketId] = Market({
            owner: msg.sender,
            requiredBond: _requiredBond,
            reward: _reward,
            creditCap: _creditCap,
            carbonCredit: carbonCredit,
            convertibleCarbonCredit: convertibleCarbonCredit,
            validatorToken: validatorToken,
            startingTime: startingTime,
            openingPeriod: _openingPeriod,
            auditPeriod: _auditPeriod,
            description: _description,
            promiseDelivered: true,
            marketState: 0
        });

        if (_requiredBond > 0) currency.safeTransferFrom(msg.sender, address(this), _requiredBond); // Pull reward.

        emit MarketInitialized(
            marketId, 
            _description,
            _reward, 
            _requiredBond, 
            msg.sender 
        );
    }

    function carbonCreditBalance(bytes32 marketId) public view returns (uint256) {
        return markets[marketId].carbonCredit.balanceOf(msg.sender);
    }

    function convertibleCarbonCreditBalance(bytes32 marketId) public view returns (uint256) {
        return markets[marketId].convertibleCarbonCredit.balanceOf(msg.sender);
    }

    function accountBalance() public view returns (uint256) {
        return currency.balanceOf(msg.sender);
    }

    function changeMarketState(bytes32 marketId, uint64 state) public {
        require(markets[marketId].owner == msg.sender, "Only owner can change market state");
        require(state <= 2, "Invalid state");
        markets[marketId].marketState = state;
    }

    function declareFalsePromise(bytes32 marketId) public returns (bytes32 assertionId){
        Market storage market = markets[marketId];
        
        require((block.timestamp >= market.startingTime + market.openingPeriod && block.timestamp < market.startingTime + market.openingPeriod + market.auditPeriod ) || 
                    market.marketState == 1, 
                    "Project is not ready for audit yet!");
        require(market.owner != address(0), "Market not initialized");

        require(assertedMarkets[marketId].asserter == address(0), "Market already asserted");
//        require(market.requiredBond > 0, "Market does not require bond");
        uint256 minimumBond = oo.getMinimumBond(address(currency)); // OOv3 might require higher bond.
        uint256 bond = market.requiredBond > minimumBond ? market.requiredBond : minimumBond;

        // Pull bond from asserter.
        currency.safeTransferFrom(msg.sender, address(this), bond);
        currency.safeApprove(address(oo), bond);        
        assertionId = oo.assertTruth(
            "The institution cannot deliver the promised amount of carbon credit",
            msg.sender, // Asserter
            address(this), // Receive callback in this contract.
            address(0), // No sovereign security.
            assertionLiveness,
            currency,
            bond,
            defaultIdentifier,
            bytes32(0) // No domain.
        );

        assertedMarkets[assertionId] = AssertedMarket({
            asserter: msg.sender,
            marketId: marketId
        });

        emit FalsePromisedDeclared(marketId, assertionId);
    }

    function assertionResolvedCallback( bytes32 assertionId, bool assertedTruthfully) public {
        require(msg.sender == address(oo), "Only OOv3 can call this function");
        Market storage market = markets[assertedMarkets[assertionId].marketId];
        
        if (assertedTruthfully) {
            market.promiseDelivered = false;            
            uint256 minimumBond = oo.getMinimumBond(address(currency)); // OOv3 might require higher bond.
            uint256 bond = market.requiredBond > minimumBond ? market.requiredBond : minimumBond;
            market.carbonCredit.burnFrom(address(this), market.carbonCredit.totalSupply());
            currency.safeTransfer(assertedMarkets[assertionId].asserter, bond);                            
        }
        market.marketState = 2;

        emit MarketResolved(assertedMarkets[assertionId].marketId);
    }

    // Dispute callback does nothing.
    function assertionDisputedCallback(bytes32 assertionId) public {}

    function mintCredit(bytes32 marketId, uint256 creditToCreate) public {
        Market storage market = markets[marketId];
        require((block.timestamp >= market.startingTime && block.timestamp < market.startingTime + market.openingPeriod)|| 
                    market.marketState == 0, 
                    "Market is closed!");
        require(market.owner != address(0), "Market is not initialized");
        require(creditToCreate > 0, "The number of credit generated should be bigger than 0");
        uint256 totalSupplyOfCarbonCredit = market.carbonCredit.totalSupply();
        require(totalSupplyOfCarbonCredit + creditToCreate <= market.creditCap, string.concat("Only ", Strings.toString(market.creditCap - totalSupplyOfCarbonCredit), " tokens left!"));

        currency.safeTransferFrom(msg.sender, market.owner, creditToCreate*1e18);
        market.carbonCredit.mint(address(this), creditToCreate);
        market.convertibleCarbonCredit.mint(msg.sender, creditToCreate);
        
        emit CreditsMinted(marketId, msg.sender, creditToCreate);
    }

    function registerValidator(bytes32 marketId) public {
        Market storage market = markets[marketId];
        require(block.timestamp < market.startingTime + market.openingPeriod + market.auditPeriod ||
                market.marketState < 2, 
                "Market is audited!");
        require(market.owner != address(0), "Market is not initialized");
        require(market.validatorToken.balanceOf(msg.sender) == 0, "Validator can register only one time");
        market.validatorToken.mint(msg.sender, 1); 
        currency.safeTransferFrom(msg.sender, address(this), validatorFee);          
        emit ValidatorRegistered(marketId, msg.sender);
    }

    function initializeDataPool(bytes32 marketId, address data_optimisticOracleV3) public returns (address) {
        require(IERC20(markets[marketId].validatorToken).balanceOf(msg.sender) == 1, "Only validator can initialize data pool");
        Market storage market = markets[marketId];
        require(block.timestamp < market.startingTime + market.openingPeriod + market.auditPeriod ||
                market.marketState < 2, 
                "Market is audited!");
        data_oo = OptimisticOracleV3Interface(data_optimisticOracleV3);
        DataAsserter dataAsserter = new DataAsserter(address(currency), address(data_oo));
        return address(dataAsserter);
    }

    function submitAndAssertData(bytes32 marketId, bytes32 dataId, string calldata dataPath, string calldata description, address dataAsserterAddress) public returns (bytes32 assertionId) {
        require(dataAsserterAddress != address(0), "Datapool not initialized");
        Market storage market = markets[marketId];
        require(block.timestamp < market.startingTime + market.openingPeriod + market.auditPeriod ||
                market.marketState < 2, 
                "Market is audited!");
        require(IERC20(markets[marketId].validatorToken).balanceOf(msg.sender) == 1, "Only validator can submit data");
        DataAsserter dataAsserter = DataAsserter(dataAsserterAddress);
        currency.safeTransferFrom(msg.sender, address(this), dataAsserter.oo().getMinimumBond(address(currency)));
        currency.safeApprove(dataAsserterAddress, dataAsserter.oo().getMinimumBond(address(currency)));
        assertionId = dataAsserter.assertDataFor(dataId, dataPath, description);
    }

    function settleValidatorToken(bytes32 marketId, address dataAsserterAddress) public {
        
        require(dataAsserterAddress != address(0), "Data pool not initialized");
        Market storage market = markets[marketId];
        require(block.timestamp >= market.startingTime + market.openingPeriod + market.auditPeriod || 
                market.marketState == 2, 
                "Market not ready for settle!");
        uint256 validatorTokenBalance = DataAsserter(dataAsserterAddress).checkTokenBalance();
        DataAsserter(dataAsserterAddress).burnToken();
        market.validatorToken.mint(msg.sender, validatorTokenBalance);
    }

    function settleMarket(bytes32 marketId) public {
        Market storage market = markets[marketId];
        require(block.timestamp >= market.startingTime + market.openingPeriod + market.auditPeriod || 
                market.marketState == 2, 
                "Market not ready for settle!");

        uint256 creditBalance = IERC20(market.convertibleCarbonCredit).balanceOf(msg.sender);
        uint256 creditDelivered = 0;

        uint256 validatorTokenBalance = market.validatorToken.balanceOf(msg.sender);

        uint256 individualReward = market.validatorToken.totalSupply() > 0 ? market.reward * market.validatorToken.balanceOf(msg.sender) / market.validatorToken.totalSupply() : 0;

        market.convertibleCarbonCredit.burnFrom(msg.sender, creditBalance);    
        market.validatorToken.burnFrom(msg.sender, validatorTokenBalance);

        if(market.promiseDelivered){
            creditDelivered = creditBalance;
            if (creditDelivered > 0) {
                IERC20(market.carbonCredit).safeTransfer(msg.sender, creditDelivered);
            }            
        }
        else{
            if(individualReward > 0){
                currency.safeTransferFrom(market.owner, msg.sender, individualReward);
            }
        }
         
        emit MarketSettled(marketId, msg.sender, individualReward, creditDelivered);    
    }
}
