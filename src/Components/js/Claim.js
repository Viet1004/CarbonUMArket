import React from "react";
import { useState } from 'react';
import {Routes, Route, Outlet, Link} from 'react-router-dom';
import { createRoot } from 'react-dom/client';
import ValidatorSpace from './ValidatorSpace/ValidatorSpace';

import '../css/Claim.css';
// import PredictionMarket from '../../PredictionMarket.json';

const ethers = require("ethers");

const Claim = ({ tokens, images }) => {

    const description = "The project saves 100 tons of carbon this year";
    const outcome_one = "True";
    const outcome_two = "False";
    const carbonCredits = tokens;
    const required_bond = 5000;

    // const abi_code = PredictionMarket.abi;
    // const contract_address = "0xAaA252c6Ec8F0561479b787C3Adf6106e437dA4A";

    // const provider = new ethers.providers.Web3Provider(window.ethereum);
    // const signer = provider.getSigner();
    // const marketContract = new ethers.Contract(contract_address, abi_code, signer);
    // marketContract.connect(signer);
    // const getMarket = async () => {
    //     const marketId = await marketContract.initializeMarket(outcome_one, outcome_two, description, ethers.utils.parseEther('0.001', 'ether'), ethers.utils.parseEther('0.002', 'ether'), {gasLimit: 3e7});
    //     return await marketContract.getMarket(marketId);
    // } 
    // const market = getMarket();


    const [inputValue, setInputValue] = useState(0);
    const [credits, setCredits] = useState(carbonCredits);
    const buyCarbonCredit = (nb_credits) => {
        // if (amounts > forTokens) {
        //     return;
        // }
        setCredits((prevTokens) => prevTokens - nb_credits);
    };



    return (
        <div className="Claim">
            <h2>{description}</h2>
            <p>{tokens}</p>
            <img src={images} alt="Claim" />
            <br></br>
            <input type="number" value={inputValue} onChange={(e) => setInputValue(Math.max(0, parseInt(e.target.value)))} />
            {/* <input type="number" value={inputValue} onChange={(e) => setInputValue(parseInt(e.target.value))} /> */}

            <button onClick={() => buyCarbonCredit(inputValue)}>Buy </button>
            <p>Carbon Credits left: {credits}</p>
            <Link to="/validatorSpace">Validator Space</Link>
        </div>
    );
};

export default Claim;