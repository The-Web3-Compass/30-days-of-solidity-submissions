// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
contract scientificCalculator{
    function power(uint base , uint exp)public view  returns(uint){
        require(base>0,"Base is low!");
        uint res=(base**exp);
        return res;
    }
    function remainder(uint divide,uint divisor)public view returns(uint){
        require(divide>0,"Cannot Divide 0");
        require(divisor>0,"Cannot divide by 0");
        return divide%divisor;
    }
}