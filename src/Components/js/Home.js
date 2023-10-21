import { useState } from 'react';
import NavBar from './NavBar';
import Claim from './Claim';

import '../css/Home.css';

function Home(){
    return(
        <div className="Home">
            {/* <NavBar className="NavBar" accounts={accounts} setAccounts={setAccounts} /> */}
            <div className="Home-header">
                <p>
                    CarbonUMArkets
                </p>
            </div>
            <Claim className="Claim" tokens={100} images="https://picsum.photos/200" />   
        </div>
    )
}

export default Home;
