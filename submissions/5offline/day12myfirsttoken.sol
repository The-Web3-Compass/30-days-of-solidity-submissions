//SPDX-License-Identifier:MIT
pragma solidity^0.8.0;

contract Myfirsttoken{
    //代币无处不在，但是token有自己的标准：ERC20是一个简单又基础的令牌
    //嘿，以太坊开发人员，以下是我们认为每个人在构建某种智能合约时都应该遵循的一组规则和行为。
    //ERC-20 建立了一个一致的接口 — 一种共享语言 — 所有代币都应该说话。
    //NFTs=Non-Fungible Token，usually digital art, music, videos, or even in-game items. 
    //今天学的比较简单，跳过了一些步骤
    //变量：
    string public name = "Herstory Token";
    string public symbol ="HER";
    uint8 public decimals = 18;
    //这个代币的最小单位是 10^-18，也就是说 1 个完整代币 = 10^18 个最小单位（通常叫 “wei” 或类似名字）。
    uint256 public totalSupply;
    //供应多少代币

    mapping(address=>uint256) public balanceOf;
    mapping(address=>mapping(address=>uint256)) public allowance;
    //给部分地址一些额度，通过一个人的允许 主管=》实习生=>额度

    event Transfer(address indexed from, address indexed to ,uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    //某人转账给xx，某人批准另外一个人花费，一个event有少于三个indexed参数的限制
    constructor (uint256 _initialSupply){
        //这次需要传参数进来
        totalSupply=_initialSupply*(10 ** uint256(decimals));
        //uint256(decimals)为了保证双方的格式一致，	10 是字面值，默认是 uint256。
        //非要写uint8可以：uint8(10) ** uint8(decimals)
        balanceOf[msg.sender]=totalSupply;
        //部署者最开始拥有全部代币
        emit Transfer(address(0),msg.sender, totalSupply);
        //从address（0）转移，将其显示为铸币事件。
    }
    //编写一个内部功能，内部函数，那么接下来的tranfer动作就不用反复出现，需要进行这一步的时候直接调用就可以了
    function _transfer(address _from, address _to,uint256 _value) internal {
        require (_to != address(0),"invalid account.");
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
    }
    //将 transfer（） 视为前端按钮，将 _transfer（） 视为后端引擎。用户只能看到按钮，但真正的作发生在幕后。
    //是一种逻辑分离
    function transfer(address _to, uint256 _value) public virtual  returns (bool){
        require (balanceOf[msg.sender]>= _value,"Not enough balance");
        _transfer(msg.sender, _to, _value);
        return true;
        //这次要在转账中加一个授权委托者，1直接转移代币 2授权人代替owner来转账
    } 
    function transferFrom(address _from, address _to, uint256 _value ) public virtual returns(bool){
        require (balanceOf[_from]>= _value, "not enough balance");
        require (allowance[_from][msg.sender] >= _value, "not enough allowance.");
        allowance[_from][msg.sender] -= _value;
        //要进行额度的扣减
        _transfer(_from , _to, _value);
        return true;
    }
    //授权委托者完成这个任务
    function approve(address _spender, uint256 _value) public returns(bool){
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender ,_value);
        return true;
        //实习生角度，允许她来花钱，委托代币移动的基础
    }




    }

    













