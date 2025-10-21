//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract ClickCounter{
    uint256 public counter ;
    //计数器加一
    function click() public{
        counter++;
    }
    //计数器重置
    function reset() public{
        counter = 0;
    }
    //计数器减一
    function decrease() public{
        require(counter > 0,"Counter cannot < 0");
        counter--;
    }
    //返回计数器的当前值
    function getCounter() public view returns(uint256){
        return counter;
    }
    //计数器成倍增加
    function clickMultiple(uint256 times) public{
        require(times > 0,"times must > 0");
        counter += times;

    }

}