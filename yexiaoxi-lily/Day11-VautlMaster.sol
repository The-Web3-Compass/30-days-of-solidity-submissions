// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Ownable{
    address private owner;

    event OwnershipTransferred(address indexed previousOwner,address indexed newOwner);

    constructor(){
        owner = msg.sender;
        emit OwnershipTransferred(address(0),owner); 
    }

    modifier onlyOwner(){
        require(msg.sender == owner,"Only owner can perform this action");
        _;
    }

    function ownerAddress() public view returns(address){
        return owner;
    }

    function transferOwnership(address newOwner)public onlyOwner{
        require(newOwner != address(0),"invalid address");
        address previous = owner;
        owner =newOwner;
        emit OwnershipTransferred(previous, newOwner);
    }
}

//owner:0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
//1:0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import"./Ownable.sol";
contract VaultMaster is Ownable{
    //存事件
    event DepositSuccessful(address indexed account,uint256 value);
    //取事件
    event WithdrawSuccessful(address indexed recipient,uint256 value);

    function getBalance()public view returns(uint256){
        return address(this).balance;
    }

    function deposit()public payable{
        require(msg.value >0,"enter a valid amount");
        emit DepositSuccessful(msg.sender,msg.value);
    }

    function withdraw(address _to,uint256 _amount)public onlyOwner{
        require(_amount <=getBalance(),"Insufficient balance");
        (bool success,) = payable(_to).call{value:_amount}("");
        require(success,"transfer failed");
        emit WithdrawSuccessful(_to,_amount);
    }

}

//owner:0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
//depost:0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
//从 OpenZeppelin 库包中获取-该包内的实际文件夹和文件路径
import "@openzeppelin/contracts/access/Ownable.sol";
contract VaultMaster is Ownable{
    //存事件
    event DepositSuccessful(address indexed account,uint256 value);
    //取事件
    event WithdrawSuccessful(address indexed recipient,uint256 value);

    constructor()Ownable(msg.sender){}  //告诉 OpenZeppelin 将部署者设置为第一个所有者

    function getBalance()public view returns(uint256){
        return address(this).balance;
    }

    function deposit()public payable{
        require(msg.value >0,"enter a valid amount");
        emit DepositSuccessful(msg.sender,msg.value);
    }

    function withdraw(address _to,uint256 _amount)public onlyOwner{
        require(_amount <=getBalance(),"Insufficient balance");
        (bool success,) = payable(_to).call{value:_amount}("");
        require(success,"transfer failed");
        emit WithdrawSuccessful(_to,_amount);
    }

}

//owner:0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
//depost:0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB
