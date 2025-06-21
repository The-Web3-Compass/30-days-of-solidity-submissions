//SPDX-License-Identifier:MIT
pragma solidity^0.8.0;

//我们有用户，但每个用户有不同的存钱保险库要求。
//inheritance保证有一些行的代码不用写
//interface在强制结构
//absrtact contract 既可以具有已实现函数也可以具有未实现（虚拟）函数的合约—
import "./IDepositBox.sol";
abstract contract BaseDepositBox is IDepositBox{

    address private owner;
    string private secret;
    uint256 private depositTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SecretStored (address indexed owner);

    constructor(){
        owner=msg.sender; 
        depositTime = block.timestamp;
    }

    modifier onlyOwner{
      require(msg.sender==owner, "Must be the owner");
      _;
    }

    function getOwner() public view override returns (address){
        return owner;
    }
    //当你实现interface（接口）里的函数时，不需要写virtual，只需要写override

    function transferOwnership(address newOwner) external  virtual  override onlyOwner {
        //可以调用函数和函数的可见性/访问方式。这个函数只能被合约外部直接调用（比如钱包、前端、其他合约）。
        //限制只有合约的“所有者”才能调用这个函数。
        require(newOwner != address(0), "Cannot transfer to the zero address");
        owner=newOwner;
        emit OwnershipTransferred(owner, newOwner);
    }
    
    function storeSecret(string calldata _secret) external virtual override onlyOwner {
       
        secret = _secret;
        emit SecretStored(msg.sender);

    }
    //当你既重写父级函数，又想让子合约还能重写时， virtual  override写在一起

    function getSecret() public view virtual override onlyOwner returns (string memory){
        return secret;
    }
    //external指的是函数外部调用，函数内部不能用；private 只是限制 代码访问，不是防止链上被看。

function getDepositTime() public view virtual override returns (uint256){
    return depositTime;
}









}