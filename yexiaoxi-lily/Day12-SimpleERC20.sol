// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract simpleERC20{
    string public name ="Web3 Compass";
    string public symbol = "COM";
    uint8 public decimals =18;
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;   //余额
    mapping (address =>mapping(address =>uint256 )) public allowance; //提取额度

    event Transfer(address indexed from ,address indexed to,uint256 value);  //转账记录
    event Approval(address indexed owner,address indexed spender,uint256 value);  //授权记录

    constructor(uint256 _initiaSupply){ //只执行一次
        totalSupply = _initiaSupply *(10**uint256(decimals));
        balanceOf[msg.sender] =totalSupply;
        emit Transfer(address(0),msg.sender,totalSupply);
    }

    function transfer(address _to,uint256 _value) public returns(bool){
        require(balanceOf[msg.sender]>=_value,"not enough balance");
        _transfer(msg.sender,_to,_value);
        return true;
    }

    function _transfer(address _from,address _to,uint256 _value) internal{
        balanceOf[_from] -=_value;
        balanceOf[_to] +=_value;
        emit Transfer(_from,_to,_value);

    }

    function approve(address _spender,uint256 _value) public returns(bool){
        allowance[msg.sender][_spender] +=_value;
        emit Approval(msg.sender,_spender,_value);
        return true;
    }

    function transferFrom(address _from,address _to,uint256 _value) public returns(bool){
        require (balanceOf[_from] >=_value,"not enough balance");
        require (allowance[_from][msg.sender] >=_value,"allowance too low");

        _transfer(_from, _to, _value);
        allowance[_from][msg.sender] -=_value;
        return true;
    }

}

//owner:0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
//1:0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
//2:0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
//3:0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB

//扩展，借用openzeppelin已设置好开发
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Mytoken is ERC20{
    constructor(uint256 initialSupply) ERC20("MYToken","MTK"){
        _mint(msg.sender,initialSupply*10**decimals());
    }
}
