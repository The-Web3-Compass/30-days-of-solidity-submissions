//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract MyToken{

    string public Name = "Kuma";
    string public Symbol = "WBT";
    uint8 public Decimals = 18;
    uint256 public TotalSupply;

    mapping(address => uint256) public BalanceOf;
    mapping(address => mapping(address => uint256)) public Allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(uint256 _InitialSupply_){
        TotalSupply = _InitialSupply_ * (10 ** Decimals);
        BalanceOf[msg.sender] = TotalSupply;
        emit Transfer(address(0), msg.sender, _InitialSupply_);

    }

    function _transfer(address _from_ , address _to_ , uint256 _value_) internal {
        require(_to_ != address(0), "Cannot transfer to the 0 address");
        BalanceOf[_from_] -= _value_;
        BalanceOf[_to_] += _value_;
        emit Transfer(_from_, _to_, _value_);

    }

    function transfer(address _to_, uint256 _value_) public returns(bool success){
        require(BalanceOf[msg.sender] >= _value_, "Not enough balance");
        _transfer(msg.sender, _to_, _value_);
        return true;

    }

    function transferfrom(address _from_,address _to_,uint256 _value_) public returns(bool){
        require(BalanceOf[_from_] >= _value_, "Not enough balance");
        require(Allowance[_from_][msg.sender] >= _value_, "Not enough allowance");
        Allowance[_from_][msg.sender] -= _value_;
        _transfer(_from_, _to_, _value_);
        return true;

    }

    function approve(address _spender_, uint256 _value_) public returns(bool){
        Allowance[msg.sender][_spender_] = _value_;
        emit Approval(msg.sender, _spender_, _value_);
        return true;

    }

}
