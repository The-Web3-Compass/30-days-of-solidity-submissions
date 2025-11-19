//SPDX-License-Identifier:MIT 
pragma solidity ^0.8.20;

contract SimpleERC20{
    //定义代币名字、交易代码（简称）、可分割程度
    string public name="SimpleERC20";
    string public symbol="SIM";
    uint8 public decimals=18;

    //追踪当前代币总数
    uint256 public totalSupply;

    //个人余额和授权第三方(映射
    mapping(address=>uint256)public balanceOf;
    mapping(address=>mapping(address=>uint256))public allowance;

    //通知/记录交易和授权动作（事件
    event Transfer(address indexed from,address indexed to,uint256 value);
    event Approval(address indexed owner,address indexed spender,uint256 value);

    //初始化（构造函数
    constructor(uint256 _initialSupply){
        totalSupply=_initialSupply*10**uint256(decimals); //初始化总供应量
        balanceOf[msg.sender]=totalSupply; //创建者获得所有代币

        emit Transfer(address(0), msg.sender,totalSupply);
    }

    //正式操作
    //1、转账（移动代币
    function transfer(address _to,uint256 _value)public returns(bool){
        require(_value<=balanceOf[msg.sender],"balance not enough.");
        _transfer(msg.sender,_to,_value);
        return true;
    }
    //2、授权第三方（eg.智能合约）
    function approval(address _spender,uint256 _value)public returns(bool){
        allowance[msg.sender][_spender]=_value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    //3、第三方移动代币
    function transferFrom(address _from,address _to,uint256 _value)public returns(bool){
        //安全检查
        require(balanceOf[_from]>=_value,"didn't have enough money");
        require(allowance[_from][msg.sender]>=_value,"Allowance too low");

        allowance[_from][msg.sender]-=_value;
        //balanceOf[_from]-=_value;
        _transfer(_from,_to,_value);
        //emit Transfer(_from, _to, _value);
        return true;
    }
    //共用转帐逻辑函数，标记为internal，只允许合约内部调用，外部不可绕过其余安全检查直接转账
    function _transfer(address _from, address _to, uint256 value)internal{
        require(_to!=address(0),"invalid address"); //不能转给0地址
        balanceOf[_from]-=value; //转出方减少
        balanceOf[_to]+=value; //接收方增加
        emit Transfer(_from,_to,value); //通知
    }




    
}