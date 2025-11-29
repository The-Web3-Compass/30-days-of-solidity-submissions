// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Day11-Ownable.sol";

contract VaultMaster is Ownable{
    // Deposit and withdraw require notification
    event depositSuccess(address indexed _account, uint256 _value);
    event withdrawSuccess(address indexed _account, uint256 _value);

    function getBalance() public view returns(uint256){
        return address(this).balance;//当前合约持有的金额
    }

    function deposit()public payable {
        require(msg.value>=0,"Invaild amount");
        emit depositSuccess(msg.sender, msg.value);
    }

    function withdraw(address _to, uint256 _value)public onlyOwner{
        require(_value <= getBalance(), "Insufficient balance");
        (bool success, )=payable (_to).call{value:_value}("");
        require(success,"Transfer failed!");
        emit withdrawSuccess(_to, _value);
    }


}