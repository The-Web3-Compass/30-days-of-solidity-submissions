// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleERC20{
    //元数据
    string public name = "SimpleToken";
    string public symbol = "SIM";
    uint8 public decimals = 18;

    //代币供应
    uint256 public totalSupply;
    // 余额和额度 核心功能！允许其他人（如 DApp 或智能合约）移动你的代币
    mapping(address => uint256) public balanceOf; //每个地址持有多少代币
    mapping(address => mapping(address => uint256)) public allowance;//追踪谁被允许代表谁花费代币

    // 事件：智能合约与外界交互的关键部分
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    //构造函数
    constructor(uint256 _initialSupply) {
        totalSupply = _initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    
    function _transfer(address _from,address _to,uint256 _value)internal{
        require(_to!=address(0),"Invalid address");
        balanceOf[_from]-=_value;
        balanceOf[_to]+=_value;
        emit Transfer(_from,_to,_value);
    }
    function transfer(address _to,uint256 _value)public virtual  returns (bool){
        require(balanceOf[msg.sender]>=_value,"Not enough balance");
        //内部辅助函数
        _transfer(msg.sender,_to,_value);
        return true;
    }
    //允许已获批准的人代为转移代币
    function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool) {
        require(balanceOf[_from]>=_value,"Not enough balance");
        require(allowance[_from][msg.sender]>=_value,"Not enough allowance");

        allowance[_from][msg.sender]-=_value;
        _transfer(_from, _to, _value);
        return true;
    }

    //允许你授权另一个地址（通常是智能合约）代表你花费代币
    function approve(address _spender,uint256 _value)public  returns (bool){
        allowance[msg.sender][_spender]=_value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

}