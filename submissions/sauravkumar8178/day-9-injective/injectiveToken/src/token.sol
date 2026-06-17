// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IBankModule } from "./IBankModule.sol";

contract BguizToken is ERC20, Ownable {
    IBankModule private immutable BANK;
    address private immutable TOKEN_ADDRESS;
    uint256 private constant INITIAL_SUPPLY = 1_000_000;

    event BankOperationExecuted(string operation, bool success);

    constructor() payable ERC20("BguizToken", "BGZ") Ownable(msg.sender) {
        TOKEN_ADDRESS = address(this);
        // use hardcoded address for bank precompile
        // ref: https://docs.injective.network/developers-evm/bank-precompile
        BANK = IBankModule(address(0x0064));
        bool hasSetMetadata = BANK.setMetadata("BguizToken", "BGZ", 0);
        require(hasSetMetadata, "failed to set metadata");
        emit BankOperationExecuted("setMetadata", hasSetMetadata);
        bool hasMinted = BANK.mint(msg.sender, INITIAL_SUPPLY);
        require(hasMinted, "failed to mint");
        emit BankOperationExecuted("mint", hasMinted);
        emit Transfer(address(0x00), msg.sender, INITIAL_SUPPLY);
    }

    function decimals() public pure override returns (uint8) {
        return 0;
    }

    function balanceOf(address acc) public view override returns(uint256) {
        return BANK.balanceOf(TOKEN_ADDRESS, acc);
    }

    function totalSupply() public view override returns(uint256) {
        return BANK.totalSupply(TOKEN_ADDRESS);
    }

    function transfer(address to, uint256 amount) public override returns(bool) {
        require(to != address(0x00), "cannot transfer to null address");
        require(amount > 0, "transfer amount must be more than zero");
        bool hasTransferred = BANK.transfer(msg.sender, to, amount);
        require(hasTransferred, "failed to transfer");
        emit BankOperationExecuted("transfer", hasTransferred);
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public override returns(bool) {
        require(from != address(0x00), "cannot transfer from null address");
        require(to != address(0x00), "cannot transfer to null address");
        require(amount > 0, "transfer amount must be more than zero");
        // decrements the allowance for this contract to transfer balances of the `from` account
        _spendAllowance(from, to, amount);
        bool hasTransferred = BANK.transfer(from, to, amount);
        require(hasTransferred, "failed to transfer");
        emit BankOperationExecuted("transfer", hasTransferred);
        emit Transfer(from, to, amount);
        return true;
    }
}