// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleERC20{
    address public owner;

    string public name = "SimpleERC20";
    string public symbol = "SIM";
    uint8 public decimals = 18;// 可分割程度，18位小数
    uint256 public totalSupply;//代币总供应量

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;//授权支付列表，如果不想对方支付呢？

    event transferLogged(address indexed _from, address indexed _to, uint256 _value);
    event approvalLogged(address indexed _from, address indexed _to, uint256 _value);

    constructor(uint256 _intialSupply){
        owner = msg.sender;
        totalSupply = _intialSupply * (10 ** uint256(decimals));
        balanceOf[owner] = totalSupply;
        emit transferLogged(address(0), owner, totalSupply);
    }

    function transfer(address _to, uint256 _value) public {
        // 判断是否可以转账
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        // 是否可以转账
        _transfer(msg.sender, _to, _value);
    } 

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to!=address(0),"address'0' is illeagal!");//防止销毁代币
        balanceOf[_from] -=_value;
        balanceOf[_to] +=_value;
        emit transferLogged(_from, _to, _value);
    }

    //function balanceOf(address)public {}
    // 授权
    function approve(address _to, uint256 _value) public{
        require(balanceOf[msg.sender]>=_value,"Insufficient value to approve");//转出账户钱不够
        allowance[msg.sender][_to] = _value;
        emit approvalLogged(msg.sender, _to, _value);
    }
    // 授权支出
    function transferFrom(address _from, address _to, uint256 _value) public{
        require(balanceOf[_from]>=_value,"Insufficient value to approve");//转出账户钱不够
        require(allowance[_from][msg.sender]>=_value, "allowance is too low");// 代为转钱的人没有权限转那么多钱
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
    }

}

/*
    
    
    pragma solidity ^0.8.20;

    import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

    contract MyToken is ERC20 {
        constructor(uint256 initialSupply) ERC20("MyToken", "MTK") {
        _mint(msg.sender, initialSupply * 10 ** decimals());
    }
}


*/