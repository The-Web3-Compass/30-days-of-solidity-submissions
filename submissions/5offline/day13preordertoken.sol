//SPDX-License-Identifier:MIT
pragma solidity^0.8.0;
//代币销售 （也称为预售或 ICO），用户发送 ETH 并以固定汇率接收代币作为回报。
//一个简单的代币销售合约
import "./Mytoken.sol";
//首先要继承原来的代币合约，然后更改让他变成virtual，后面可以用override覆盖

contract PreOrderToken is Myfirsttoken {
    //这里写合约名不是文件名
    //这里报错因为没有给constructor传uint256  _initialSupply)
    // 子合约自己的初始化逻辑,要求父合约构造器参数必须在子合约构造器里显式传入.
    //卖代币阶段
    uint256 public tokenPrice;
    uint256 public saleStartTime;
    uint256 public saleEndTime;
    //起始和结束时间
    uint256 public minPurchase;
    uint256 public maxPurchase;
    //最多和最少购买
    uint256 public totalRaised;
    //一共募集到了多少金额
    address public projectOwner;
    //销售完成后接收 ETH 的地址,deploy这个合同的那个人来收钱
    bool public finalized = false;
    //销售是否完成
    bool private initialTransferDone = false;
    //用于确保合约在锁定转账之前收到所有代币，部署者会把所有代币转到合约地址，然后再设为true
    
    event TokenPurchased(address indexed buyer, uint256 etherAmount , uint256 tokenAmount);
    //记录下谁买了代币
    event SaleFinalized(uint256 totalRaised, uint256 totalTokenSold);
    //记录下最终结果
    constructor (
        //之前constructor里面没参数，现在里面有很多参数
        uint256 _initialSupply,  
        uint256 _tokenPrice,
        uint256 _saleDurationInSeconds, 
        uint256 _minPurchase, 
        uint256 _maxPurchase, 
        address _projectOwner) Myfirsttoken (_initialSupply){
     //constructor(uint256 _initialSupply) Myfirsttoken(_initialSupply) {
            //先传参数给自己，再调用母函数,填的是母函数合约名称
            //在后台调用 Herstory 构造函数，并最初向部署程序提供所有令牌
            tokenPrice = _tokenPrice;
            saleStartTime = block.timestamp;
            saleEndTime = block.timestamp+_saleDurationInSeconds;
            minPurchase = _minPurchase;
            maxPurchase = _maxPurchase ;
            projectOwner = _projectOwner;

            _transfer(msg.sender, address(this), totalSupply);
            //在mytoken合同里的这个函数
            initialTransferDone = true;
        }
        function isSaleActive() public view returns(bool) {
            return(!finalized && block.timestamp >= saleStartTime && block.timestamp <= saleEndTime);
            //没结束，时间在开始之后，结束之前，是还能买的
        }
        function buyTokens () public payable {
            require (isSaleActive(), "This sale is not active yet");
            require(msg.value >= minPurchase && msg.value <= maxPurchase, 'Amount must be between minimum and maximum');
                // 如果条件不成立，直接退出函数
            
            uint256 tokenAmount = (msg.value * 10 ** uint256(decimals))/ tokenPrice;
            //tokenAmount = (5e16 * 1e18) / 1e16 = 5e18，先把丢进来的钱的等比放大到代币
            //再除代币的价格，得到代币数量
            require(balanceOf[address(this)] >= tokenAmount, "NOT ENOUGH TOKENDS LeFT FORSALE");
            //[]这里是映射的用法，不是数组,就是查mapping
            totalRaised += msg.value;
            _transfer (address(this), msg.sender, tokenAmount);
            //从合约地址（address(this)）转出 tokenAmount 个代币，转给用户（msg.sender
            emit TokenPurchased(msg.sender, msg.value ,tokenAmount );
         //emit 发送事件的关键字，谁购买了代币，花了多少 ETH，收到了多少代币
            
        }
        function transfer(address _to ,uint256 _value) public override returns(bool){
            //销售检查，主要目标是在销售进行期间暂时限制代币转移 。
            if(!finalized && msg.sender != address(this) &&initialTransferDone){
                require(false, "Toen are locked until sale of finalized");
                //如果所有这些都为 true，则函数将还原 ，从而有效地阻止传输 
                //禁止在销售的过程中a把token转移给b

            }
            return super.transfer (_to ,_value);
            //super用于调用父合约中被重写（override）的函数。
            //调用父合约的 transfer 函数，执行标准的代币转账，并返回结果。

        }
        function transferFrom(address _from,address _to ,uint256 _value) public override returns (bool){
            //确保了即使是获得批准的花费者也不能在销售期间代表他人转移代币。
        if(!finalized && _from != address(this) ){
            require(false, "Toen are locked until sale of finalized");

        }
        return super.transferFrom (_from, _to ,_value);
        //一样返回false
    
        }
        function finalizeSale() public payable {
            require(msg.sender == projectOwner, "Only owner can call this function.");

            require(finalized == false && block.timestamp > saleEndTime,"Sale is still active");

             //如果不是已经完成销售，并且销售的时间已经结束，销售才会结束。
             finalized = true;
             //标记销售动作的结束，下一部分就要开始算卖了多少代币

      uint256 tokenSold = totalSupply - balanceOf[address(this)];
            //tokenAmount = totalSupply-balanceOf[]
            //总供应量-现在账户里的代币
            (bool success, )= projectOwner.call {value: address (this).balance}("");
            require (success, "Transfer to project owner failed.");
            //把没卖掉的代币转移走

         emit SaleFinalized (totalRaised , tokenSold);
         //叫event

        }
        function timeRemaining() public view returns (uint256){
            //看还剩多少时间 helper functions
            if(block.timestamp >= saleEndTime){
                return 0 ;

            }
            return saleEndTime - block.timestamp;
        }
        function tokensAvailable() public view returns (uint256) {
    return balanceOf[address(this)];

    //看下账户里还有多少币可以卖 mapping所以[]
    }
    receive() external payable{
        buyTokens();

        //receive()：这是 Solidity 里专门用来接收 ETH 的函数。
        //buyTokens()：当 ETH 被转进来时，自动调用 buyTokens()，也就是自动帮用户买代币。

    }





       

    





}

