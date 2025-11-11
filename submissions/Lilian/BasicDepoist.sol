// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import"./BaseDepoist.sol";

contract BasicDepoistBox is BaseDepoistBox{
    function getBoxType() external pure override returns (string memory){
        return "Basic";
    }
}