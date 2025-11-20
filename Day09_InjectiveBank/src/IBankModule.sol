// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IBankModule {
    function mint(address account, uint256 amount) external payable returns (bool);
    function burn(address account, uint256 amount) external payable returns (bool);
    function balanceOf(address token, address account) external view returns (uint256);
    function totalSupply(address token) external view returns (uint256);
    function transfer(address from, address to, uint256 amount) external payable returns (bool);
    function setMetadata(string memory name, string memory symbol, uint8 decimals) external payable returns (bool);
}
