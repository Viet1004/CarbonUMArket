import React from "react";
import { useState, useEffect } from 'react';
import { BigNumber } from "ethers";
import {Routes, Route, Outlet, Link} from 'react-router-dom';
import { createRoot } from 'react-dom/client';
import ValidatorSpace from './ValidatorSpace/ValidatorSpace';
import CarbonUMArket from '../../abi/CarbonUMArket.json';
import TestnetERC20 from '../../abi/TestnetERC20.json';

import '../css/Claim.css';
// import PredictionMarket from '../../PredictionMarket.json';

const ethers = require("ethers");

const Claim = ({ accounts, setAccounts, marketId }) => {

    const isConnected = Boolean(accounts[0]);
    const description = "The project saves 100 tons of carbon this year";
    const [credits, setCredits] = useState(100); // [0]
    const [carbonCredits, setCarbonCredits] = useState(10); // [0]
    const [convertibleCarbonCredits, setConvertibleCarbonCredits] = useState(10); // [1]
    const required_bond = 5000;
    const images = 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/Adirondacks_in_May_2008.jpg/1280px-Adirondacks_in_May_2008.jpg';

    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const signer = provider.getSigner();

    const buyerAddress = "0xbAd501482BCDF94a38245fABA566c845AcDABC42";

    const address = "0xAc7816f07DaE7a574e1e5F1cbAECfc13FB90b659";
    const abi = CarbonUMArket.abi;
    const contract = new ethers.Contract(address, abi, signer);

    const ERC20Address = "0x220aD3e788eF81662b1E82978660a8B4D01dDb11";
    const ERC20abi = TestnetERC20.abi;
    const ERC20contract = new ethers.Contract(ERC20Address, ERC20abi, signer);

    

    marketId = "0x6124b907f4676c34285a6ebacd21b97fe74370345a1293c2dbbedb0e54f84b4d";
    
    const [inputValue, setInputValue] = useState(0);

    const [convertibleCredit, setConvertibleCredit] = useState(convertibleCarbonCredits);
        
    
    const buyCarbonCredit = async (nb_credits) => {
            ERC20contract.allocateTo(buyerAddress, BigNumber.from(nb_credits*1e15));
            // setMarketId(async () => await contract.initializeMarket(BigNumber.from(1e18), BigNumber.from(0), BigNumber.from(100), description));
            await contract.mintCredit(marketId, nb_credits,{gasLimit: 5000000});
    
            const carbonCreditMinted = await contract.carbonCreditBalance(marketId);
            console.log(`carbonCreditMinted ${carbonCreditMinted}`);
            const convertibleCarbonCreditMinted = await contract.convertibleCarbonCreditBalance(marketId);
            setCredits((prevTokens) => prevTokens - nb_credits);
            setCarbonCredits((prevTokens) => prevTokens + carbonCreditMinted);
            setConvertibleCarbonCredits((prevTokens) => prevTokens + convertibleCarbonCreditMinted);
    }    

    return (
        <div className="Claim">
            <h2>Market {0} : {description}</h2>
            <img src={images} alt="Claim" />
            <br></br>

            {isConnected ? (
                <div>
                    <input type="number" value={inputValue} onChange={(e) => setInputValue(Math.max(0, parseInt(e.target.value)))} />
                    {/* <input type="number" value={inputValue} onChange={(e) => setInputValue(parseInt(e.target.value))} /> */}
    
                    <button onClick={() => buyCarbonCredit(inputValue)}>Buy </button>
                    <p>Carbon Credits left: {credits}</p>
                    <p>Number of CarbonCredit of Client: {carbonCredits}</p>
                    <p>Number of convertible CarbonCredit of Client: {convertibleCarbonCredits}</p>
                    <div className="space">
                        <Link className="space-element" to="/clientSpace" carbonCredits={carbonCredits} convertibleCarbonCredits={convertibleCarbonCredits} >Client Space</Link>
                        <Link className="space-element" to="/validatorSpace">Validator Space</Link>
                    </div>
                </div>
            ) : (
                <p>Connect your wallet to buy carbon credits</p>
            )
                
            }
            
        </div>
    );
};

export default Claim;