//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//合约声明
contract SimpleERC20 {

    //状态变量（存储在链上）
    string public name = "SimpleToken";
    //定义一个字符串类型的公开状态变量 name，表示代币名称；并初始化为 "SimpleToken"

    string public symbol = "STM";
    //代币符号

    uint8 public decimals = 18;
    //表示代币的小数位（ERC20 常用 18），用于前端把整数单位转换为人类可读小数

    uint256 public totalSupply;
    //代币总供应量（以最小单位计，即通常是整数）。此处没有初始化，会在构造函数中设置

    //映射——记录余额和授权
    mapping(address => uint256) public balanceOf;
    //定义一个从地址到余额的映射 balanceOf，记录每个地址的代币余额

    mapping(address => mapping(address => uint256)) public allowance;
    //实现授权表 allowance[owner][spender] = amount，表示 owner 授权 spender 在其余额中代为花费的额度（ERC20 标准）

    //event事件
    event Transfer(address indexed from,address indexed to, uint256 value);
    //声明 Transfer 事件，ERC20 标准要求：在转账时触发。前端/链上监听器可通过事件索引快速查询

    event Approval(address indexed owner, address indexed spender, uint256 value);
    //声明 Approval 事件，在 approve 时触发，ERC20 要求。用于通知授权变更

    //构造函数（部署时执行一次）
    constructor(uint256 _initialSupply) {
    //合约部署时运行一次，用于初始化总供应量并把代币分配给部署者（msg.sender）

        totalSupply = _initialSupply * (10 ** uint256(decimals));
        //把输入的 初始供应 转换为最小单位（例如用户输入 1 但实际是 1 * 10^18），然后赋值给 totalSupply

        balanceOf[msg.sender] = totalSupply;
        //把全部代币分配给合约部署者地址 msg.sender（部署交易的发送者）

        emit Transfer(address(0), msg.sender, totalSupply);
        //触发 Transfer 事件，惯例是从 address(0)（铸造）到 msg.sender，表示代币被创建并发送给部署者
    }

//transfer函数——用户给别人转代币
function transfer(address _to, uint256 _value) public returns (bool) {
//公开函数，允许调用者把自己账户的 _value 代币转给 _to。返回 true 表示成功（兼容 ERC20）

    require(balanceOf[msg.sender] >= _value, "Not enough balance");
    //检查调用者是否有足够余额，否则回退并返回错误消息

    _transfer(msg.sender, _to, _value);
    //内部调用 _transfer 函数（集中处理转账逻辑与事件），把 msg.sender 视为转出方。使用内部函数方便复用

    return true;
    //按 ERC20 习惯返回布尔值表示成功
}

//approve函数——授权别人花钱
function approve(address _spender, uint256 _value) public returns (bool) {
//让 msg.sender 授权 _spender 花费 _value 数量的代币

    allowance[msg.sender][_spender] = _value;
    //设置授权额度

    emit Approval(msg.sender, _spender, _value);
    //触发 Approval 事件，通知链上/前端授权变更

    return true;
    //返回成功
    
    }

//transferFrom函数——被授权的转账（代他人转）
function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
//允许 msg.sender 代表 _from（前者被授权者）把 _value 代币转到 _to，前提是 allowance[_from][msg.sender] 足够。常用于合约或第三方代付

    require(balanceOf[_from] >= _value, "Not enough balance");
    //检查 _from 地址的余额是否足够

    require(allowance[_from][msg.sender] >= _value, "Allowance too low");
    //检查授权额度是否足够

    allowance[_from][msg.sender] -= _value;
    //消耗对应的授权额度（减少 allowance）
    
    _transfer(_from, _to, _value);
    //复用 _transfer 执行实际余额变更与触发事件
    
    return true;
    //返回成功

    }

//_transfer内部函数——统一的转账逻辑
function _transfer(address _from, address _to, uint256 _value) internal {
//内部函数，集中处理余额变更与 Transfer 事件。标为 internal 表示只能在合约内部或继承合约中调用

    require(_to != address(0), "Invalid address");
    //防止把代币转到零地址（零地址常作为 burn/销毁的标识，或可能导致代币不可找回）。强制要求接收地址有效。

    balanceOf[_from] -= _value;
    //再次检查余额（冗余检查有助于安全）；在 Solidity >= 0.8，整数下溢/溢出会 revert，但显式 require 提供清晰错误信息

    balanceOf[_to] += _value;
    //从 _from 扣除余额

    emit Transfer(_from, _to, _value);
    //触发 Transfer 事件，外部监听器可据此更新界面或链上索引

    }

}