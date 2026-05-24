// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Stablecoin {

    string public name = "MyStablecoin";
    string public symbol = "MSC";
    uint8 public decimals = 18;

    uint256 public totalSupply;
    uint256 public peg = 1 ether; // 1 MSC = 1 ETH (simplified peg)

    mapping(address => uint256) public balanceOf;

    event Mint(address indexed user, uint256 amount);
    event Burn(address indexed user, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /*
     * Mint stablecoins by depositing ETH
     */
    function mint() external payable {
        require(msg.value > 0, "Send ETH");

        uint256 tokensToMint = (msg.value * 1e18) / peg;

        balanceOf[msg.sender] += tokensToMint;
        totalSupply += tokensToMint;

        emit Mint(msg.sender, tokensToMint);
    }

    /*
     * Burn stablecoins to redeem ETH
     */
    function burn(uint256 amount) external {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");

        uint256 ethToReturn = (amount * peg) / 1e18;

        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;

        (bool success, ) = payable(msg.sender).call{value: ethToReturn}("");
        require(success, "Transfer failed");

        emit Burn(msg.sender, amount);
    }

    /*
     * Transfer tokens
     */
    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");

        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    /*
     * Get contract ETH reserves
     */
    function getReserve() external view returns (uint256) {
        return address(this).balance;
    }
}