// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract StableCoin {
    string public constant name = "LDOLLAR";
    string public constant symbol = "LDOLLAR";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address public owner;
    address public pegManager;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier onlyOwner() {
        require(msg.sender == owner, "StableCoin: Caller is not the owner");
        _;
    }

    modifier onlyPegManager() {
        require(msg.sender == pegManager, "StableCoin: Caller is not the PegManager");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // Set PegManager contract address, only owner
    function setPegManager(address _pegManager) external onlyOwner {
        require(_pegManager != address(0), "StableCoin: Invalid PegManager address");
        pegManager = _pegManager;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(to != address(0), "StableCoin: Transfer to zero address");
        require(balanceOf[msg.sender] >= value, "StableCoin: Insufficient balance");

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        require(spender != address(0), "StableCoin: Approve to zero address");
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(from != address(0), "StableCoin: Transfer from zero address");
        require(to != address(0), "StableCoin: Transfer to zero address");
        require(balanceOf[from] >= value, "StableCoin: Insufficient balance");
        require(allowance[from][msg.sender] >= value, "StableCoin: Allowance exceeded");

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }

    // Mint tokens, only PegManager
    function mint(address to, uint256 value) external onlyPegManager {
        require(to != address(0), "StableCoin: Mint to zero address");
        totalSupply += value;
        balanceOf[to] += value;
        emit Transfer(address(0), to, value);
    }

    // Burn tokens, only PegManager
    function burn(address from, uint256 value) external onlyPegManager {
        require(from != address(0), "StableCoin: Burn from zero address");
        require(balanceOf[from] >= value, "StableCoin: Burn amount exceeds balance");

        totalSupply -= value;
        balanceOf[from] -= value;
        emit Transfer(from, address(0), value);
    }
}
