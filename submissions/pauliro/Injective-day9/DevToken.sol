// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

//@openzeppelin/=lib/openzeppelin-contracts/
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import {IBankModule} from "./IBankModule.sol";

// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol"
// import "./IBankModule.sol";

contract DevToken is ERC20, Ownable {

    IBankModule private constant BANK = IBankModule (0x0000000000000000000000000000000000000064);

    // address private immutable tockenAddress;
    address private immutable TOKEN_ADDRESS;

    uint256 private constant INITIAL_SUPPLY = 10_000_000 * 10**18;

    event BanckOperationExecuted(string operation, bool success);
    constructor() payable ERC20 ("DevToken", "DEV") Ownable(msg.sender){
        TOKEN_ADDRESS = address(this);
        bool metadataset = BANK.setMetadata("DevToken", "DEV.",18);
        emit BanckOperationExecuted("setMetaData", metadataset);

        bool mintSuccess = BANK.mint(msg.sender, INITIAL_SUPPLY);
        require(mintSuccess, "Mintfailed");
        emit Transfer(address(0), msg.sender, INITIAL_SUPPLY);
    }

    function balanceOf(address account) public view override returns(uint256){
        return BANK.balanceOf(TOKEN_ADDRESS, account);
    }
    function totalSupply() public view override returns(uint256){
        return BANK.totalSupply(TOKEN_ADDRESS);
    }
    function transfer (address _to, uint256 _amount) public override returns (bool){
        require (_to != address(0), "ERC20: Transfer to zero address");
        require (_amount > 0, "Transfer amount must be greater than zero");

        address owner = msg.sender;
        bool success = BANK.transfer (owner, _to, _amount);
        require (success, "Bank transfer failed");

        emit BanckOperationExecuted("Transsfer", success);
        emit Transfer(owner, _to, _amount);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _amount) public override returns(bool){
        require (_to != address(0), "ERC20: Transfer to zero address");
        require (_amount > 0, "Transfer amount must be greater than zero");
        address spender = msg.sender;
        _spendAllowance(_from, spender, _amount);

        bool success = BANK.transfer(_from, _to, _amount);
        require(success, "Bank transfer failed!");

        emit BanckOperationExecuted("Transfer", success);
        emit Transfer (_from, _to, _amount);
        return true;
    }

    function supportsBannkPrecompile() external pure returns (bool){
        return true;
    }
}