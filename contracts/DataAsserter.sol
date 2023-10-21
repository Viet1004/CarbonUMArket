// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "@uma/core/contracts/common/implementation/AddressWhitelist.sol";
import "@uma/core/contracts/common/implementation/ExpandedERC20.sol";
import "@uma/core/contracts/data-verification-mechanism/implementation/Constants.sol";
import "@uma/core/contracts/data-verification-mechanism/interfaces/FinderInterface.sol";
import "@uma/core/contracts/optimistic-oracle-v3/implementation/ClaimData.sol";
import "@uma/core/contracts/optimistic-oracle-v3/interfaces/OptimisticOracleV3Interface.sol";
import "@uma/core/contracts/optimistic-oracle-v3/interfaces/OptimisticOracleV3CallbackRecipientInterface.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// This contract allows assertions on any form of data to be made using the UMA Optimistic Oracle V3 and stores the
// proposed value so that it may be retrieved on chain. The dataId is intended to be an arbitrary value that uniquely
// identifies a specific piece of information in the consuming contract and is replaceable. Similarly, any data
// structure can be used to replace the asserted data.
contract DataAsserter {
    using SafeERC20 for IERC20;
    IERC20 public immutable defaultCurrency;
    ExpandedERC20 public validatorToken;
    OptimisticOracleV3Interface public immutable oo;
    uint64 public constant assertionLiveness = 7200;
    bytes32 public immutable defaultIdentifier;

    struct DataAssertion {
        bytes32 dataId; // The dataId that was asserted.
        string dataPath; // This could be an arbitrary data type.
        string description; // A description of the data.
        address asserter; // The address that made the assertion.
        bool resolved; // Whether the assertion has been resolved.
    }

    mapping(bytes32 => DataAssertion) public assertionsData;

    event DataAsserted(
        bytes32 indexed dataId,
        string dataPath,
        string description,
        address indexed asserter,
        bytes32 indexed assertionId
    );

    event DataAssertionResolved(
        bytes32 indexed dataId,
        string dataPath,
        string description,
        address indexed asserter,
        bytes32 indexed assertionId
    );

    constructor(address _defaultCurrency, address _optimisticOracleV3) {
        defaultCurrency = IERC20(_defaultCurrency);
        oo = OptimisticOracleV3Interface(_optimisticOracleV3);
        defaultIdentifier = oo.defaultIdentifier();
        validatorToken = new ExpandedERC20(
            "DataAsserter Validator Token",
            "DAVT",
            1
        );
        validatorToken.addMinter(address(this));
        validatorToken.addBurner(address(this));
        validatorToken.addMinter(address(oo));
    }

    // For a given assertionId, returns a boolean indicating whether the data is accessible and the data itself.
    function getData(bytes32 assertionId) public view returns (bool, string memory, string memory) {
        if (!assertionsData[assertionId].resolved) return (false, "*blank*", "Data not resolved");
        return (true, assertionsData[assertionId].dataPath, assertionsData[assertionId].description);
    }

    // Data can be asserted one time. If it passes, it will be displayed. The consumer contract must store the returned assertionId
    // identifiers to able to get the information using getData.
    function assertDataFor(
        bytes32 dataId,
        string memory dataPath,
        string memory description
    ) public returns (bytes32 assertionId) {
        
        uint256 bond = oo.getMinimumBond(address(defaultCurrency));
        defaultCurrency.safeTransferFrom(msg.sender, address(this), bond);
        defaultCurrency.safeApprove(address(oo), bond);
        // The claim we want to assert is the first argument of assertTruth. It must contain all of the relevant
        // details so that anyone may verify the claim without having to read any further information on chain. As a
        // result, the claim must include both the data id and data, as well as a set of instructions that allow anyone
        // to verify the information in publicly available sources.
        // See the UMIP corresponding to the defaultIdentifier used in the OptimisticOracleV3 "ASSERT_TRUTH" for more
        // information on how to construct the claim.
        assertionId = oo.assertTruth(
            abi.encodePacked(
                "Data asserted at ", 
                dataPath,
                " with description ",
                description,
                " for dataId: 0x",
                ClaimData.toUtf8Bytes(dataId),
                " and asserter: 0x",
                ClaimData.toUtf8BytesAddress(msg.sender),
                " at timestamp: ",
                ClaimData.toUtf8BytesUint(block.timestamp),
                " in the DataAsserter contract at 0x",
                ClaimData.toUtf8BytesAddress(address(this)),
                " is valid."
            ),
            msg.sender,
            address(this),
            address(0), // No sovereign security.
            assertionLiveness,
            defaultCurrency,
            bond,
            defaultIdentifier,
            bytes32(0) // No domain.
        );
        assertionsData[assertionId] = DataAssertion(
            dataId,
            dataPath,
            description,
            msg.sender,
            false
        );
        emit DataAsserted(dataId, dataPath, description, msg.sender, assertionId);
    }

    function checkTokenBalance() public view returns (uint256) {
        return validatorToken.balanceOf(msg.sender);
    }

    function burnToken() public {
        validatorToken.burnFrom(msg.sender, validatorToken.balanceOf(msg.sender));
    }

    // OptimisticOracleV3 resolve callback.
    function assertionResolvedCallback(
        bytes32 assertionId,
        bool assertedTruthfully
    ) public {
        require(msg.sender == address(oo));
        // If the assertion was true, then the data assertion is resolved.
        if (assertedTruthfully) {
            assertionsData[assertionId].resolved = true;
            validatorToken.mint(assertionsData[assertionId].asserter, 1);
            DataAssertion memory dataAssertion = assertionsData[assertionId];
            emit DataAssertionResolved(
                dataAssertion.dataId,
                dataAssertion.dataPath,
                dataAssertion.description,
                dataAssertion.asserter,
                assertionId
            );
            // Else delete the data assertion if it was false to save gas.
        } else delete assertionsData[assertionId];
    }

    // If assertion is disputed, do nothing and wait for resolution.
    // This OptimisticOracleV3 callback function needs to be defined so the OOv3 doesn't revert when it tries to call it.
    function assertionDisputedCallback(bytes32 assertionId) public {}
}