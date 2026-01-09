// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IBankModule.sol";

contract DevToken is ERC20, Ownable {
    IBankModule private constant BANK = IBankModule(0x0000000000000000000000000000000000000064);

    address private immutable tokenAddress; 
    uint256 private constant INITIAL_SUPPLY = 10_000_000 * 10**18;

    event BankOperationExecuted(string operation, bool success);

    constructor() payable ERC20("DevToken", "DEV") Ownable(msg.sender) {
        tokenAddress = address(this);

        bool metadataset  = BANK.setMetadata("DevToken", "DEV", 18);
        emit BankOperationExecuted("setMetadata", metadataset);

        bool mintSuccess = BANK.mint(msg.sender, INITIAL_SUPPLY);
        require(mintSuccess, "Minting failed");
        emit Transfer(address(0), msg.sender, INITIAL_SUPPLY);
    }
function balanceOf(address account) public view override returns(uint256){
    return BANK.balanceOf(tokenAddress, account);
}
function totalSupply() public view override returns(uint256){
    return BANK.totalSupply(tokenAddress);
}

function transfer(address to, uint256 amount) public override returns (bool) {
    require(to != address(0), "Zero/Null address");
    require(amount > 0, "Must be greater than Zero");

    address owner = msg.sender;

    bool success = BANK.transfer(owner, to, amount);
    require(success, "Bank transfer failed");

    emit BankOperationExecuted("Transfer", success);

    emit Transfer(owner, to, amount);
    return true; 
}
function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
    require(to != address(0), "Zero/Null address");
    require(amount > 0, "Must be greater than Zero");

    address spender = msg.sender;
    _spendAllowance(from, spender, amount);

    bool success = BANK.transfer(from, to, amount);
    require(success, "Bank transferFrom failed");

    emit BankOperationExecuted("Transfer", success);

    emit Transfer(from, to, amount);
    return true;
}

function supportBankPrecompile() external pure returns (bool) {
    return true;
}

}

//deployed contract address: 0xEF6A883E13C473EFcCbc95767dc7CeB26bE4b3BE

