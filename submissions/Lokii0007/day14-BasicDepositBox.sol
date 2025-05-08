// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

import "./day14-BaseDepositBox.sol";

contract BasicDepositBox is BaseDepositBox {

    function getBoxType()external pure virtual override returns(string memory){
        return "Basic deposit box";
    }
}