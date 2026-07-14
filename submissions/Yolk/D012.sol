

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

//建立代币规则 ERC-20

contract SimpleERC20 {
    string public name = "SimpleToken"//简称SIM
    string public symbol = "SIM";//简称
    uint8 public decimals = 18;//18位小数
    uint256 public totalSupply;//追踪总数

    mapping(address => uint256) public balanceOf;//每个地址有多少代币
    mapping(address => mapping(address => uint256)) public allowance;//嵌套映射，用于追踪谁被允许代表谁花费代币——以及花费多少。允许移动，但需要得到你批注

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);//indexed 关键字——这使得这些值在事件日志中可搜索。所以如果你想要查找来自特定地址的所有转账，或是对某个特定支出者的所有批准，这就是实现方式。

    constructor(uint256 _initialSupply) {//构造函数——铸造初始供应
        totalSupply = _initialSupply * (10 ** uint256(decimals));//设定了将存在的代币总数
        balanceOf[msg.sender] = totalSupply;//部署者最初持有 100%的代币
        emit Transfer(address(0), msg.sender, totalSupply);//发一个transfer来表示“铸造”

        function transfer(address _to, uint256 _value) public returns (bool) {
            require(balanceOf[msg.sender] >= _value, "Not enough balance");//确保有钱
            _transfer(msg.sender, _to, _value);//通过_transfer来实现逻辑分离
            return true;
        }
        function _transfer(address _from, address _to, uint256 _value) internal {//内部函数
            require(_to != address(0), "Invalid address");//确保发送到有效地址
            balanceOf[_from] -= _value;//减少发送者的余额
            balanceOf[_to] += _value;//增加接收者的余额
            emit Transfer(_from, _to, _value);//发送事件
        }
        function transferForm(address _from, address _to, uint256 _value) public returns (bool) {
            require(balanceOf[_from] >=_value, "Not enough balance");
            require(allowance[_from][msg.sender] >= _value, "Allowance too low");
            allowance[_from][msg.sender] -= _value;
            _transfer(_from, _to, _value);
            return true;
        }
        function approve(address _spender, uint256 _value) public returns (bool) {//授权智能合约代表你话费代币
            allowance[msg.sender][_spender] = _value;
            emit Approval(msg.sender, _spender, _value);
            return true;
        }
    }
// OpenZeppelin ，创建代币


}