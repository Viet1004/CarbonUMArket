import {useState} from 'react';
import "../../css/ClientSpace/ClientSpace.css";
import CarbonUMArket from '../../../abi/CarbonUMArket.json';


function ClientSpace({ carbonCredits, convertibleCarbonCredits }) {
    
    // Use props 
    return (
        <div className='client-space'>
            <div>
                <h1>Client Space</h1>
                <br />
            </div>

            <div className='balance'>
                <h2>Carbon Credit: {carbonCredits}</h2>
                <h2>Convertible Carbon Credit Price: {convertibleCarbonCredits}</h2>
            </div>
        </div>
    );

}

export default ClientSpace;