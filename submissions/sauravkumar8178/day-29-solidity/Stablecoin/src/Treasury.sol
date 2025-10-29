// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/access/AccessControl.sol";
import "./StableUSD.sol";

contract Treasury is AccessControl {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    StableUSD public immutable stable;

    constructor(address stableAddress) {
        stable = StableUSD(stableAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MANAGER_ROLE, msg.sender);
    }

    // recover ERC20 tokens (fees, reserves)
    function recoverERC20(address token, uint256 amount, address to) external onlyRole(MANAGER_ROLE) {
        IERC20(token).transfer(to, amount);
    }

    // burn stable held by treasury
    function burnStable(uint256 amount) external onlyRole(MANAGER_ROLE) {
        stable.burn(address(this), amount);
    }
}