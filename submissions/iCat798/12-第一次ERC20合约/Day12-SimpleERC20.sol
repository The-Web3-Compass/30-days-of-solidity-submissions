
 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleERC20 {

    // 代币元数据
    string public name = "Web3 Compass"; // 代币名称
    string public symbol = "COM";        // 交易代码
    uint8 public decimals = 18;          // 可分割程度（小数点后18位）
    uint256 public totalSupply;          // 代币供应，追踪当前存在的代币总数

    mapping(address => uint256) public balanceOf;                     // 余额：每个地址持有多少代币

    //！！！嵌套映射，允许其他人（如 DApp 或智能合约）移动你的代币，但前提是你必须首先批准。
    mapping(address => mapping(address => uint256)) public allowance; // 额度：追踪谁被允许代表谁花费代币——以及花费多少

    event Transfer(address indexed from, address indexed to, uint256 value);       // 事件：代币从一个地址转移到另一个地址
    event Approval(address indexed owner, address indexed spender, uint256 value); // 事件：有人授权另一个地址代表他们花费代币

    // 铸造初始供应
    constructor(uint256 _initialSupply) {
        totalSupply = _initialSupply * (10 ** uint256(decimals)); // 设定将存在的代币总数,代币是18位小数，所以初始供应量乘以 10 ** decimals（=10^decimals），例如，100个代币的话是100 * 10^18 = 100000000000000000000，
        balanceOf[msg.sender] = totalSupply;                      // 将缩放后的数字存储在 totalSupply 中
        emit Transfer(address(0), msg.sender, totalSupply);       // 事件：代币被“凭空铸造”，
    }

    // 直接转账（直接转移代币）
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balanceOf[msg.sender] >= _value, "Not enough balance");
        _transfer(msg.sender, _to, _value); // !!! 逻辑分离：调用内部辅助函数执行代币转移
        return true;
    }

    // 授权
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowance[msg.sender][_spender] = _value;        // ！！！嵌套映射：allowance[owner][spender]，表示被授权者可花费的最大额度
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // ！！！授权转账：间接转移代币，让智能合约可以代表用户操作代币,是DEX、借贷协议等DeFi应用的基础!）
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(balanceOf[_from] >= _value, "Not enough balance");     // 检查 Alice 是否确实拥有这些代币
        require(allowance[_from][msg.sender] >= _value, "Allowance too low"); // 检查某用户是否已被批准花费该金额（额度够不够）

        allowance[_from][msg.sender] -= _value; // 减少某用户的授权额度
        _transfer(_from, _to, _value);          // 调用_transfer()来执行实际的代币转移
        return true;
    }

    // ！！！内部函数：实际移动代币的引擎，internal表示内部调用,可重复利用
    // transfer()和 transferFrom()都依赖于_transfer()来保持一致性并遵循 DRY（不要重复自己）原则

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0), "Invalid address");
        balanceOf[_from] -= _value;        // 减少发送者余额
        balanceOf[_to] += _value;          // 增加接收者余额
        emit Transfer(_from, _to, _value);
    }
}
