// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleERC20{
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;//代币供应量

    constructor(string memory _name ,string memory _symbol ,uint8 _decimals,uint256 _initialSupply){
       name=_name;
       symbol=_symbol;
       decimals=_decimals;
       totalSupply=_initialSupply*(10**uint256(decimals));
        balanceOf[msg.sender]=totalSupply;
        emit Transfer(address(0),msg.sender,totalSupply);
    }

    mapping(address=>uint256) public balanceOf;//告诉你每个地址有多少代币
    mapping(address=>mapping(address=>uint256)) public allowance;//双重映射，在你的地址簿里，谁被允许花了多少钱

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);



    function transfer(address _to, uint256 _value) public virtual returns(bool){//这一变化（指加virtua）会告诉 Solidity：如果有其他合约继承了这个合约，这个函数是可以被重新修改的
        require(balanceOf[msg.sender]>0,"Not enough balance");
        _transfer(msg.sender,_to,_value);//调用一个内部辅助函数 _transfer() 来执行实际的代币转移
        return true;
    }
    
    function _transfer(address _from, address _to, uint256 _value) internal{
        require(_to!=address(0),"Invaild address");
        balanceOf[_from]-=_value;
        balanceOf[_to]+=_value;

        emit Transfer(_from,_to,_value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public virtual returns(bool){
        require(balanceOf[_from]>0,"Not enough balance");
        require(allowance[_from][msg.sender]>=_value,"Not enough balance");
        _transfer(_from,_to,_value);
        return true;
    }

    function approve(address _spender,uint256 _value) public returns(bool){
        allowance[msg.sender][_spender]=_value;
        emit Approval(msg.sender,_spender,_value);
        return true;
    }
}