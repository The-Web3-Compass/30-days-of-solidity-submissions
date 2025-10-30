// SPDX-License-Identifier: MIT

/**
    * @title  IBankModule
    * @dev  Interface for Injective's Bank precompile
    * This is the getaway to the native bank module
*/

pragma solidity ^0.8.13;

interface IBankModule {
    ///  @notice Mint new to tockens to an account
    function mint(address account, uint256 amount) external payable returns (bool);

    /// @notice Get the balance of an account for an specific token
    function balanceOf(address tocken, address account) external view returns (uint256);

    /// @notice Burn tokens from an account 
    function burn(address account, uint256 amount) external payable returns (bool);

    /// @notice Transfer tockens from one account to another 
    function transfer(address from,address to, uint256 amount) external payable returns (bool);

    /// @notice Get the total suply of a tocken 
    function totalSupply(address tocken) external view returns (uint256);

    /// @notice Get tocken metadata
    function metadata(address tocken) external view returns (string memory name,string memory symbol,uint8 decimals);

    /// @notice Set tocken metadata
    function setMetadata(string memory name,string memory symbol,uint8 decimals) external payable returns (bool);

}
