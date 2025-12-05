// SPDX-License-Identifier: MIT

pragma solidity  ^0.8.0;
/*
    Build a smart bank that offers different types of deposit boxes — basic, premium, time-locked, etc. 
    Each box follows a common interface and supports ownership transfer. 
    A central VaultManager contract interacts with all deposit boxes in a unified way, letting users store 
    secrets and transfer ownership like handing over the key to a digital locker. This teaches interface design, 
    modularity, and how contracts communicate with each other safely.
*/

 
import {BaseDepositBox} from "./BaseDepositBox.sol";

interface IDepositBox {
    function getOwner() external view returns (address);
    function transferOwnership(address newOwner) external;
    function storeSecret(string calldata secret) external;
    function getSecret() external view returns (string memory);
    function getBoxType() external pure returns (string memory);
    function getDepositTime() external view returns (uint256);
}
