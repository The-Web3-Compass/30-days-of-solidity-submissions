// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IBankModule.sol";

contract InjectiveBankDemo {
    // Injective Bank precompile address
    IBankModule private constant BANK = IBankModule(0x0000000000000000000000000000000000000064);

    address public immutable TOKEN_ADDRESS;

    event BankOp(string operation, bool success);

    constructor() {
        TOKEN_ADDRESS = address(this);

        // Optional: set metadata once
        bool ok = BANK.setMetadata("DemoToken", "DMT", 18);
        emit BankOp("setMetadata", ok);

        // optional initial mint to deployer
        bool minted = BANK.mint(msg.sender, 1_000 * 10**18);
        emit BankOp("mint", minted);
    }

    function getBalance(address account) external view returns (uint256) {
        return BANK.balanceOf(TOKEN_ADDRESS, account);
    }

    function transferToken(address to, uint256 amount) external returns (bool) {
        bool ok = BANK.transfer(msg.sender, to, amount);
        emit BankOp("transfer", ok);
        return ok;
    }

    function supply() external view returns (uint256) {
        return BANK.totalSupply(TOKEN_ADDRESS);
    }
}
