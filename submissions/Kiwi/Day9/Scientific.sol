// SPDX-License-Identifier:MIT
pragma solidity^0.8.0;

contract Scientific{
    function power(uint256 base, uint256 ex)public pure returns(uint256) {
        if(ex == 0) return 1;
        else return (base ** ex);
    }

    function square(uint256 number) public pure returns(uint256) {
        if(number == 0)return 0;
        uint256 result = number/2;
        for(uint256 i = 0; i<10; i++){
            result = (result + number / result)/2;
        }
        return result;
    }
}