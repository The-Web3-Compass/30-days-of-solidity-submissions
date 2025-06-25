// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    // Token details
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    // Supply and balances
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);

    // Token transfers
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    // Allowance management
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    // Events
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
