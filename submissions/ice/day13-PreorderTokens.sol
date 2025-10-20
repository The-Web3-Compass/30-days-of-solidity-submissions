// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// 导入第12天的代币合约
import "./day12-MyFirstToken.sol";

/**
 * @title TokenPresale
 * @dev 代币预售合约
 * 用户可以用以太币购买代币，合约所有者可以管理预售参数
 */
contract TokenPresale {
    ERC20 public token;
    
    // 预售参数
    address public owner;
    uint256 public rate; // 1 ETH = rate tokens
    uint256 public minPurchase; // 最小购买金额（wei）
    uint256 public maxPurchase; // 最大购买金额（wei）
    uint256 public hardCap; // 硬顶（wei）
    uint256 public softCap; // 软顶（wei）
    
    // 预售状态
    bool public presaleActive;
    uint256 public totalRaised; // 总筹集金额
    uint256 public totalTokensSold; // 总售出代币数量
    
    // 购买记录
    mapping(address => uint256) public contributions; // 用户贡献的ETH
    mapping(address => uint256) public tokensPurchased; // 用户购买的代币
    address[] public contributors; // 贡献者列表
    
    // 事件
    event TokensPurchased(address indexed buyer, uint256 ethAmount, uint256 tokenAmount);
    event PresaleStarted();
    event PresalePaused();
    event PresaleFinalized();
    event RateUpdated(uint256 oldRate, uint256 newRate);
    event FundsWithdrawn(address indexed owner, uint256 amount);
    event RefundIssued(address indexed buyer, uint256 amount);
    
    /**
     * @dev 修饰符：只有所有者可以调用
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "TokenPresale: caller is not the owner");
        _;
    }
    
    /**
     * @dev 修饰符：预售必须激活
     */
    modifier presaleIsActive() {
        require(presaleActive, "TokenPresale: presale is not active");
        _;
    }
    
    /**
     * @dev 构造函数
     * @param _token 预售代币合约地址
     * @param _rate 兑换率（1 ETH = _rate tokens）
     * @param _minPurchase 最小购买金额
     * @param _maxPurchase 最大购买金额
     * @param _softCap 软顶
     * @param _hardCap 硬顶
     */
    constructor(
        address _token,
        uint256 _rate,
        uint256 _minPurchase,
        uint256 _maxPurchase,
        uint256 _softCap,
        uint256 _hardCap
    ) {
        require(_token != address(0), "TokenPresale: token address cannot be zero");
        require(_rate > 0, "TokenPresale: rate must be greater than 0");
        require(_minPurchase > 0, "TokenPresale: min purchase must be greater than 0");
        require(_maxPurchase >= _minPurchase, "TokenPresale: max purchase must be >= min purchase");
        require(_hardCap > _softCap, "TokenPresale: hard cap must be greater than soft cap");
        
        token = ERC20(_token);
        owner = msg.sender;
        rate = _rate;
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
        softCap = _softCap;
        hardCap = _hardCap;
        presaleActive = false;
    }
    
    /**
     * @dev 接收以太币并购买代币
     */
    receive() external payable {
        buyTokens();
    }
    
    /**
     * @dev 购买代币
     */
    function buyTokens() public payable presaleIsActive {
        require(msg.value >= minPurchase, "TokenPresale: purchase amount below minimum");
        require(msg.value <= maxPurchase, "TokenPresale: purchase amount above maximum");
        require(totalRaised + msg.value <= hardCap, "TokenPresale: hard cap exceeded");
        
        // 计算代币数量
        uint256 tokenAmount = calculateTokenAmount(msg.value);
        require(tokenAmount > 0, "TokenPresale: token amount must be greater than 0");
        
        // 检查合约是否有足够的代币
        require(token.balanceOf(address(this)) >= tokenAmount, "TokenPresale: insufficient tokens in contract");
        
        // 记录购买信息
        if (contributions[msg.sender] == 0) {
            contributors.push(msg.sender);
        }
        
        contributions[msg.sender] += msg.value;
        tokensPurchased[msg.sender] += tokenAmount;
        totalRaised += msg.value;
        totalTokensSold += tokenAmount;
        
        // 转移代币给购买者
        require(token.transfer(msg.sender, tokenAmount), "TokenPresale: token transfer failed");
        
        emit TokensPurchased(msg.sender, msg.value, tokenAmount);
    }
    
    /**
     * @dev 计算代币数量
     * @param ethAmount 以太币数量
     * @return 代币数量
     */
    function calculateTokenAmount(uint256 ethAmount) public view returns (uint256) {
        return (ethAmount * rate) / 1 ether;
    }
    
    /**
     * @dev 启动预售（只有所有者）
     */
    function startPresale() external onlyOwner {
        require(!presaleActive, "TokenPresale: presale is already active");
        presaleActive = true;
        emit PresaleStarted();
    }
    
    /**
     * @dev 暂停预售（只有所有者）
     */
    function pausePresale() external onlyOwner {
        require(presaleActive, "TokenPresale: presale is not active");
        presaleActive = false;
        emit PresalePaused();
    }
    
    /**
     * @dev 更新兑换率（只有所有者）
     */
    function updateRate(uint256 newRate) external onlyOwner {
        require(newRate > 0, "TokenPresale: rate must be greater than 0");
        uint256 oldRate = rate;
        rate = newRate;
        emit RateUpdated(oldRate, newRate);
    }
    
    /**
     * @dev 提取筹集的资金（只有所有者）
     */
    function withdrawFunds() external onlyOwner {
        require(totalRaised >= softCap, "TokenPresale: soft cap not reached");
        uint256 balance = address(this).balance;
        require(balance > 0, "TokenPresale: no funds to withdraw");
        
        payable(owner).transfer(balance);
        emit FundsWithdrawn(owner, balance);
    }
    
    /**
     * @dev 提取剩余代币（只有所有者）
     */
    function withdrawRemainingTokens() external onlyOwner {
        uint256 remainingTokens = token.balanceOf(address(this));
        require(remainingTokens > 0, "TokenPresale: no tokens to withdraw");
        
        require(token.transfer(owner, remainingTokens), "TokenPresale: token transfer failed");
    }
    
    /**
     * @dev 退款（如果未达到软顶）
     */
    function refund() external {
        require(!presaleActive, "TokenPresale: presale is still active");
        require(totalRaised < softCap, "TokenPresale: soft cap reached, no refunds");
        require(contributions[msg.sender] > 0, "TokenPresale: no contribution to refund");
        
        uint256 refundAmount = contributions[msg.sender];
        contributions[msg.sender] = 0;
        
        payable(msg.sender).transfer(refundAmount);
        emit RefundIssued(msg.sender, refundAmount);
    }
    
    /**
     * @dev 获取预售信息
     */
    function getPresaleInfo() external view returns (
        bool active,
        uint256 currentRate,
        uint256 raised,
        uint256 tokensSold,
        uint256 remainingTokens,
        uint256 progress
    ) {
        return (
            presaleActive,
            rate,
            totalRaised,
            totalTokensSold,
            token.balanceOf(address(this)),
            hardCap > 0 ? (totalRaised * 100) / hardCap : 0
        );
    }
    
    /**
     * @dev 获取用户购买信息
     */
    function getUserInfo(address user) external view returns (
        uint256 contribution,
        uint256 tokens
    ) {
        return (
            contributions[user],
            tokensPurchased[user]
        );
    }
    
    /**
     * @dev 获取贡献者数量
     */
    function getContributorCount() external view returns (uint256) {
        return contributors.length;
    }
    
    /**
     * @dev 检查是否达到软顶
     */
    function isSoftCapReached() external view returns (bool) {
        return totalRaised >= softCap;
    }
    
    /**
     * @dev 检查是否达到硬顶
     */
    function isHardCapReached() external view returns (bool) {
        return totalRaised >= hardCap;
    }
}


// /**
//  * @title 使用示例合约
//  * @dev 展示如何使用第12天的代币合约进行预售
//  */
// contract PreorderExample {
//     ERC20 public immutable token;
//     TokenPresale public immutable presale;
    
//     constructor() {
//         // 1. 部署代币合约（使用第12天的MyFirstToken）
//         token = new MyFirstToken("PreorderToken", "POT", 18);
        
//         // 2. 部署预售合约
//         presale = new TokenPresale(
//             address(token),
//             1000,           // 1 ETH = 1000 tokens
//             0.01 ether,     // 最小购买 0.01 ETH
//             10 ether,       // 最大购买 10 ETH
//             50 ether,       // 软顶 50 ETH
//             100 ether       // 硬顶 100 ETH
//         );
        
//         // 3. 将代币转移到预售合约（预留50%用于预售）
//         uint256 presaleAmount = token.totalSupply() / 2;
//         token.transfer(address(presale), presaleAmount);
        
//         // 4. 启动预售
//         presale.startPresale();
//     }
    
//     /**
//      * @dev 获取预售和代币的完整信息
//      */
//     function getFullInfo() external view returns (
//         // 代币信息
//         string memory tokenName,
//         string memory tokenSymbol,
//         uint8 tokenDecimals,
//         uint256 tokenTotalSupply,
//         // 预售信息
//         bool presaleActive,
//         uint256 currentRate,
//         uint256 totalRaised,
//         uint256 totalTokensSold,
//         uint256 remainingTokens,
//         uint256 progress
//     ) {
//         // 获取代币信息
//         tokenName = token.name();
//         tokenSymbol = token.symbol();
//         tokenDecimals = token.decimals();
//         tokenTotalSupply = token.totalSupply();
        
//         // 获取预售信息
//         (
//             presaleActive,
//             currentRate,
//             totalRaised,
//             totalTokensSold,
//             remainingTokens,
//             progress
//         ) = presale.getPresaleInfo();
//     }
// }