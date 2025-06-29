// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleERC20{
    string public name = "SimpleToken";
    string public symbol = "SIM";
    uint8 public decimals = 18;  //定义可整除性
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf; //存储每个地址有的代币数
    mapping(address => mapping(address => uint256)) public allowance; //跟踪允许谁代表谁花费多少代币

    event Transfer(address indexed from, address indexed to, uint256 value);  //当代币从一个地址移动到另一个地址时触发该事件
    event Approval(address indexed owner, address indexed spender, uint256 value);  //当有人允许另一个地址代表他们花费代币时触发该事件

    //铸造初始供应
    constructor(uint256 _initialSupply){
        totalSupply = _initialSupply * (10 ** uint256(decimals));
        balanceOf[msg.sender] = totalSupply;  //部署者开始时持有初始所有代币
        emit Transfer(address(0), msg.sender, totalSupply); //address(0)表示代币时凭空创建的
    }

    function transfer(address _to, uint256 _value) public virtual returns (bool){  //前端按钮
        require(balanceOf[msg.sender] >= _value, "Not enough balance");
        _transfer(msg.sender, _to, _value);  //调用一个内部辅助函数来执行实际的token移动
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool){
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // 允许从已获得批准的人那里转给别人代币
    function transferFrom(address _from, address _to, uint256 _value) public virtual returns(bool){
        require(balanceOf[_from] >= _value, "Not enough balance");
        require(allowance[_from][msg.sender] >= _value, "Allowance too low");

        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    // 移动token的实际引擎，标记为internal（表示只能从这个contract或其派生contract中调用，不能被external用户或其他contract调用）
    function _transfer(address _from, address _to, uint256 _value) internal {  //后端引擎
        require(_to != address(0), "Invalid address");
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
    }
} 
