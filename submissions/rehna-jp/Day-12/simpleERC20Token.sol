// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleERC20 {

    address owner;
    string public name = "SimpleToken";
    string public symbol = "SIM";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    uint256 public feePercent = 2; 
    address public feeReceiver;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(uint256 _initialSupply) {
        owner = msg.sender;
        feeReceiver = msg.sender;
        totalSupply = _initialSupply * (10 ** uint256(decimals));
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    modifier onlyOwner{
        require(msg.sender == owner, "You are not the owner");
        _;
    }

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

    function _transfer(address _from, address _to, uint256 _value) internal {
    require(_to != address(0), "Invalid address");

    uint256 fee = (_value * feePercent) / 100;
    uint256 amountAfterFee = _value - fee;

    balanceOf[_from] -= _value;

    balanceOf[_to] += amountAfterFee;
    balanceOf[feeReceiver] += fee;

    emit Transfer(_from, _to, amountAfterFee);
    emit Transfer(_from, feeReceiver, fee);
}

function mint(address to, uint256 amount) public onlyOwner {
    totalSupply += amount;
    balanceOf[to] += amount;
    emit Transfer(address(0), to, amount);
}

function burn(uint256 amount) public {
    require(balanceOf[msg.sender] >= amount);
    balanceOf[msg.sender] -= amount;
    totalSupply -= amount;
    emit Transfer(msg.sender, address(0), amount);
}

}
