import { useState } from 'react';
import { useEffect } from 'react';
import NavBar from './NavBar';
import Claim from './Claim';
import { ethers, BigNumber } from 'ethers';
import CarbonUMArket from '../../abi/CarbonUMArket.json';

import '../css/Home.css';

function Home({ accounts , setAccounts }){
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const [marketId, setMarketId] = useState(0);
    const signer = provider.getSigner();
    const address = "0xAc7816f07DaE7a574e1e5F1cbAECfc13FB90b659";
    const abi = CarbonUMArket.abi;
    const contract = new ethers.Contract(address, abi, signer);
    // const description = "The project saves 100 tons of carbon this year";
    // const rewardAmount = ethers.utils.parseEther('0.001', 'ether');
    // useEffect(() => {
    //     // setMarketId(async () => await contract.initializeMarket(BigNumber.from(1e18), BigNumber.from(0), BigNumber.from(100), description));
    //     const initializeMarket = async () => {
    //         const marketId = await contract.initializeMarket(rewardAmount, BigNumber.from(0), BigNumber.from(100), description);
    //         setMarketId(marketId);
    //     }
    //     initializeMarket();
    // }, []);
    // console.log("Printing marketId");
    // console.log(marketId);

    return(
        <div className="Home">
            {/* <NavBar className="NavBar" accounts={accounts} setAccounts={setAccounts} /> */}
            <div className="Home-header">
                <p>
                    CarbonUMArkets
                </p>
            </div>
            <Claim className="Claim" accounts={accounts} setAccounts={setAccounts} marketId={0} />   
        </div>
    )
}

export default Home;
