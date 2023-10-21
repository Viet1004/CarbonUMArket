// import '../css/App.css';

import {useState} from 'react';

import { BrowserRouter, Routes, Route } from 'react-router-dom';

import ValidatorSpace from './ValidatorSpace/ValidatorSpace';
import NavBar from './NavBar';
import Home from './Home';
// import { ethers } from 'ethers';

function App() {
    const [accounts, setAccounts] = useState([]);
    return (
      <BrowserRouter>
        <Routes>
          <Route path='/' element={<NavBar className="NavBar" accounts={accounts} setAccounts={setAccounts} />}>
            <Route index element={<Home />} />
            <Route path='validatorSpace' element={<ValidatorSpace />} />
          </Route>
        </Routes>
      </BrowserRouter>
    );
}

export default App;
