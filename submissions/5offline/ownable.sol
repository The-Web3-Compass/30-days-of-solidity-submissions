//SPDX-License-Identifier:MIT
pragma solidity^0.8.0;

//即将写两个合同，这次要用到继承模型Inherientance，有母合同和子合同两个部分
//如何更改继承的东西：母合同里标记virtual，子合同里标记override，必须同时使用两者
contract ownable{
    address private owner;
    //一个母合同里，这个变量（或函数）只能在当前合约的内部访问，连继承它的子合约也看不到
    //避免子合约直接篡改，通过父合约提供的函数安全访问
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    //event是看什么东西写在日志里，这里有两个索引，不写其他的参数了
    constructor(){
        owner = msg.sender;
        //emit OwnershipTransferred(address(0), msg.sender)；
        //原来是没人是owner，现在这个发消息的人是owner
    }

    modifier onlyOwner(){
        require(msg.sender ==  owner, "only owner could do this.");
        _;
    }

    function getOwneraddress() public view returns(address){
        return owner;
    }
    function transferOwnership(address _newOwner) public onlyOwner{
        require(_newOwner != address(0),"new owner address is invalid.");
        address previous =owner;
        //转移时要看到前一位owner，再看下一位owner,将当前owner赋值给previous
        owner = _newOwner;

        emit OwnershipTransferred(previous, _newOwner);

        
    }
}


