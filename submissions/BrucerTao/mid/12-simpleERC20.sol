// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleERC20 {
    string public name = "SimpleToken";
    string public symbol = "SIM";
    uint8 public decimals = 18;
    uint256 public totalSupply;  //部署时确认发布的代币总数

    mapping(address => uint256) public balanceOf;  //每个地址有多少代币
    mapping(address => mapping(address => uint256)) public allowance;  //表示谁被允许代表谁花费代币多少

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);  //当有人授权另一个地址代表他们花费代币时，会触发

    //锻造初始供应
    constructor(uint256 _initialSuppoly) {
        totalSupply = _initialSuppoly * (10 ** uint256(decimals));
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);

    }

    //转移,内部辅助函数_transfer
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balanceOf[msg.sender] >= _value, "not enough balance");
        _transfer(msg.sender, _to, _value);
        return true;

    }

    //批准一个地址（通常是智能合约）代表你使用代币的权限
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;

    }

    //允许批准人实际代表其他人移动代币
    function transFrom(address _from ,address _to, uint256 _value) public returns (bool) {
        require(balanceOf[_from] >= _value, "not enough balance");
        require(allowance[_from][msg.sender] >= _value, "Allowance too low");

        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;

    }

    //转移的实际引擎
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0), "Invalid address");
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);

    }

}