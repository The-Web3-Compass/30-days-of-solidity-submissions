//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
contract VaultMaster is Ownable{
    //写两个事件，存钱、取钱
    event depositSuccessful(address account, uint256 value);
    event withdrawSuccessful(address recipient,uint256 value);
//操作
    //1、查看合约金额
    function getBalance()public view returns(uint256){
        return address(this).balance;

    }
    //2、存钱
    function deposit()public payable{
        require(msg.value>0,"invalid value");
        emit depositSuccessful(msg.sender, msg.value);

    }
    //3、取钱
    function withdraw(address _account,uint256 _value)public onlyOwner{
        //需要取款小于存款（安全
        require(_value<=address(this).balance,"invalid value");
        //用call转账(call还是不太会写
        (bool success,)=payable(_account).call{value:_value}("");
        require(success,"withdraw failed");
        //触发事件
        emit withdrawSuccessful(_account, _value);

    }



}
