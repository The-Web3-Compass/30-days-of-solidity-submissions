// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleERC20{
    string public name="SimpleToken";
    string public symbol="SIM";
    uint8 public decimals=18;
    uint256 public totalSupply;
    mapping(address=>uint256) public balanceOf;//告诉你每个地址持有多少代币。
    mapping(address=>mapping(address=>uint256)) public allowance;//用于追踪谁被允许代表谁花费代币——以及花费多少。
    event Transfer(address indexed from,address indexed to,uint256 value);
    event Approval(address indexed owner,address indexed spender,uint256 value);

    constructor(uint256 _initSupply){
        balanceOf[msg.sender]=_initSupply;
        totalSupply=_initSupply*(10**uint256(decimals));
        emit Transfer(address(0),msg.sender,totalSupply);
    }

    function transfer(address to,uint256 value) public returns(bool){
        require(balanceOf[msg.sender]>=value,"Insufficient balance");
        _transfer(msg.sender,to,value);
        return true;
    }

    function _transfer(address _from,address _to,uint256 _value) internal{
        require(_to !=address(0),"Invalid address");
        balanceOf[_from]-=_value;
        balanceOf[_to]+=_value;
        emit Transfer(_from,_to,_value);
    }
    
    function approve(address _spender, uint256 _value) public returns (bool) {
    allowance[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(balanceOf[_from] >= _value, "Not enough balance");
    require(allowance[_from][msg.sender] >= _value, "Allowance too low");
    allowance[_from][msg.sender] -= _value;
    _transfer(_from, _to, _value);
    return true;
    }

    //使用OpenZeppelin创建代币的方法
    //import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

    // contract MyToken is ERC20 {
    //     constructor(uint256 initialSupply) ERC20("MyToken", "MTK") {
    //         _mint(msg.sender, initialSupply * 10 ** decimals());
    //     }
    // }

}
