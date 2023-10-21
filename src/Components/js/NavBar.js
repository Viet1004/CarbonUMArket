//import { boolean } from 'hardhat/internal/core/params/argumentTypes';
import React from 'react';
import '../css/NavBar.css';
import { Outlet, Link } from 'react-router-dom';
import { createRoot } from 'react-dom/client';

const NavBar = ({ accounts , setAccounts }) => {
    const isConnected = Boolean(accounts[0]);
    const connect = async () => {
        if (window.ethereum){
            const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });    
            setAccounts(accounts);
        }
    };

    return (
        <div>
            <div className='NavBar'>
                <ul>
                    <li><Link to="/">Home</Link></li>
                </ul>
                {!isConnected ? 
                <button id='button' onClick={connect}>Connect</button>:
                <p id='text'>Connected</p> }
            </div>

            <Outlet />
        </div>
        
    );
}

export default NavBar;
