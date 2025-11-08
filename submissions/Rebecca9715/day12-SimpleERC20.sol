 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleERC20 {
    // 定义一下profile
    string public name = "SimpleToken";
    string public symbol = "SIM";
    // 比如ETH的18为小数点最大位数
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    // 两个address之间传递的允许数量
    mapping(address => mapping(address => uint256)) public allowance;

// 记录事件
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

// 需要传入代币的数量
    constructor(uint256 _initialSupply) {
        // 10的decimals次方
        totalSupply = _initialSupply * (10 ** uint256(decimals));
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    // 直接传递代币，没有allowance做限制
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balanceOf[msg.sender] >= _value, "Not enough balance");
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(balanceOf[_from] >= _value, "Not enough balance");
        require(allowance[_from][msg.sender] >= _value, "Allowance too low");

        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    // transfer的底层函数，from和to增加和减少
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0), "Invalid address");
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
    }
}

// owner：0x5B38Da6a701c568545dCfcB03FcB875f56beddC4 
// address 1：0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2 
// address 2：0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
