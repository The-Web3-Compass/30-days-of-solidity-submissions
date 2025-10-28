// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ScientificCalculator{

  function power(uint256 base, uint256 exponent)  public pure returns(uint256){
    if(exponent==0) return 1;
    else return(base**exponent);
  }

  function squareRoot(uint256 number) public pure returns(uint256){
    if (number == 0) return 0;
    if (number == 1) return 1; // 明确返回 1
    
    // 此时 number >= 2，初始猜测 result = number/2 至少为 1，不会导致除零。
    uint256 result = number / 2; 
    
    // 使用更健壮的 while 循环，避免固定 10 次的迭代
    uint256 oldResult = 0;
    while (result != oldResult && result != 0) { // 确保 result 不为 0
        oldResult = result;
        result = (result + number / result) / 2;
    }
    return result;
}
}