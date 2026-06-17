// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);   
    event Transfer(address indexed from, address indexed to, uint256 value); 
}

contract AthenaToken is IERC20 {
    string public name = "Athena Token";
    string public symbol = "ATH";
    uint8 public decimals = 18; // Changed to uint8 for standard compliance
    uint256 public maxSupply = 10_000_000 * 10**uint256(decimals);
    address public owner;

    uint256 public override totalSupply;
    mapping(address => uint256) public override balanceOf;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    constructor(uint256 _initialSupply) {
        owner = msg.sender;
        uint256 amount = _initialSupply * 10**uint256(decimals);
        
        require(amount <= maxSupply, "Exceeds max supply");
        
        totalSupply = amount;
        balanceOf[msg.sender] = amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    function mint(uint256 _amount) public onlyOwner {
        uint256 amountToMint = _amount * 10**uint256(decimals); 

        require(totalSupply + amountToMint <= maxSupply, "Would exceed max supply");
        require(_amount > 0, "Invalid amount");

        totalSupply += amountToMint;
        balanceOf[msg.sender] += amountToMint;

        emit Transfer(address(0), msg.sender, amountToMint);
    }

    function transfer(address _to, uint256 _amount) public override returns (bool) {
        require(_to != address(0), "Invalid Address");
        require(_amount <= balanceOf[msg.sender], "Insufficient tokens");

        balanceOf[msg.sender] -= _amount;
        balanceOf[_to] += _amount;

        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
}