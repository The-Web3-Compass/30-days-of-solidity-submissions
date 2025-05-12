// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.18;

import "./IDepositBox.sol";

abstract contract BaseDepositBox is IDepositBox {

    address internal owner;
    string private secret;
    uint256 internal depositTime;

   
    function getOwner() public view returns (address) {
        return owner;
    }

    function transferOwnership(address _newOwner) external virtual override {
        require (_newOwner != address(0), "Invalid address");
         owner = _newOwner;
    }

    function storeSecret(string calldata _Secret) external virtual override  {
        secret = _Secret;
    }

    function getSecret() public view virtual override returns(string memory) {
    return secret;
    }

    function getDepositTime() external view virtual override  returns(uint256) {
        return depositTime;
    }

    function getBoxType() external view virtual override returns (string memory) {
        
    }
}