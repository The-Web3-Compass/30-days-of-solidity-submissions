// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

//基础抽象合约
import "./IDepositBox.sol";
abstract contract BaseDepositBox is IDepositBox{
    address private owner;
    string private secret;
    uint256 private depositTime;    

    //事件：所属权转换；秘密存储
    // event OwnershipTransferred(address indexed pre, address indexed new); //new是关键字噢！不能用
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SecretStored(address indexed owner);

    //疑问：为何不用openzepplin
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the box owner");
        _;
    }

    constructor( ) {
        owner==msg.sender;
        depositTime=block.timestamp;
    }

    function getOwner() public view override  returns (address){
        return owner;
    }

    function transferOwnership(address newOwner)external virtual override onlyOwner{
        require(newOwner != address(0), "New owner cannot be zero address"); 
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    } 
    function storeSecret(string calldata _secret) external virtual override onlyOwner{
        secret = _secret;
        emit SecretStored(msg.sender);
    }
    function getSecret() public view virtual override  onlyOwner returns (string memory){
        return secret;
    }
    function getDepositTime() external view virtual override  returns (uint256){
        return depositTime;
    }
}
