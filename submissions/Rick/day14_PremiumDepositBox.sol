// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./day14_BaseDepositBox.sol";

// 带标签信息的box
contract PremiumDepositBox is BaseDepositBox {

    string private metadata;
    
    function getBoxType() external pure override  returns (string memory){
        return unicode"定时box";
    }

    function setMetaData(string memory _metadata) external checkBoxOwner {
        metadata = _metadata;
    }

    function getMetaData() external view checkBoxOwner returns  (string memory){
        return metadata;
    }
} 

 