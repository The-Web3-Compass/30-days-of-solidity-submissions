// SPDX-License-Identifier:MIT

pragma solidity ^0.8.26;

contract SimpleERC20{
    string public name = 'SimpleToken';
    string public symbol = "SIM";
    uint8 public decimals = 18;
    uint256 public totalSupply;//令牌总数

    mapping(address=>uint256) public balanceOf;//余额，告诉每个地址有多少代币
    //备抵，跟踪谁被允许代表谁花费代币以及花费多少
    // 让其他人（如DApp或者智能合约）移动您的代币，当前前提是你批准了它
    mapping(address=>mapping(address=>uint256)) public allowance;

    event Transfer(address indexed from, address indexed to,uint256 value);//代币地址移动时会触发
    event Approval(address indexed owner,address indexed spender,uint256 value);//有人授予另一个地址代表他们使用代币时触发

    constructor(uint256 _initialSupply){
        totalSupply = _initialSupply * (10**uint256(decimals));
        balanceOf[msg.sender]=totalSupply;

        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function transfer(address _to,uint256 _value) public returns (bool){
        require(balanceOf[msg.sender]>=_value,"Not enough balance");
        _transfer(msg.sender,_to,_value);
        return true;
    }

    function approve(address _spender,uint256 _value)public returns (bool){
        allowance[msg.sender][_spender]=_value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from,address _to,uint256 _value) public returns (bool){
        require(balanceOf[_from]>=_value,"Not enough balance");
        require(allowance[_from][msg.sender]>=_value,"Allowance too low");

        allowance[_from][msg.sender]-=_value;
        _transfer(_from, _to, _value);
        return true;
    }

    function _transfer(address _from,address _to,uint256 _value) internal {
        require(_to!=address(0),"Invalid address");
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
    }

}