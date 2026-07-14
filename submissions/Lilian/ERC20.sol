// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleERC20 {
    string public name="simpleToken";//代币全名
    string public symbol="SIM";//交易代码
    uint8 public decimals=18;//可分割程度
    uint256 public totalSupply;//追踪当前存在的代币

    mapping (address=>uint256)public balanceOf;//每个地址存在的代币
    mapping (address=>mapping(address=>uint256))public allowance;//允许其他人移动你的代币

    event Transfer (address indexed from,address indexed to,uint256 value);//代币转移的时候触发
    event Approve (address indexed owner,address indexed spender,uint256 value);//被授权转移代币的时候触发

    constructor (uint256 _initalSupply){
        totalSupply=_initalSupply * (10**uint256(decimals));//设定将存在的代币总数
        balanceOf[msg.sender]=totalSupply;//上面的数量放在totalsupply里面
        emit Transfer(address(0), msg.sender, totalSupply);//分配给msgsender
    }

    function transfer(address _to, uint256 _value) public returns (bool){
        require(balanceOf[msg.sender]>=_value,"Not enough balance");//确保msgsender有足够的代币
        _transfer(msg.sender,_to,_value);//调用transfer来调用实际转移
        return true;
    }
    function _transfer(address _from,address _to,uint256 _value)internal{
        require(_to !=address(0),"Invalid address");//确保地址不是零地址
        balanceOf[_from]-=_value;//从发送者扣除余额
        balanceOf[_to]+=_value;//给接受者加余额
        emit Transfer(_from,_to,_value);//发送一个transfer
    }
    function transferFrom (address _from,address _to,uint256 _value)public returns (bool){
        require(balanceOf[_from]>=_value,"Not enough balance");//检查是不是真的拥有
        require(allowance[_from][msg.sender]>=_value,"Allowance too low");//检查是不是被批准

        allowance [_from][msg.sender]-=_value;//减少授权额度
        _transfer(_from, _to, _value);//用transfer来执行
        return true;
    }
    function approve(address _spender, uint256 _value)public returns (bool){
        allowance[msg.sender][_spender]=_value;
        emit Approve(msg.sender, _spender, _value);//通知外界操作已发生
        return true;
    }
}