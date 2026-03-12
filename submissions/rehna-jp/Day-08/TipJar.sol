// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract tipJar{

    // AggregatorV3Interface internal priceFeed;

    address public owner;
    address[]  creators;
    mapping (address => uint) creatorAllocation;
    mapping (address => bool) isCreator;
    mapping(address => mapping(address => uint256)) public creatorTokenBalances;

    event TipSent(address indexed sender, address indexed recipient, uint amount);
    event TokenTipSent(address indexed sender, address indexed creator, address token, uint256 amount);
    event CreatorAdded(address indexed creator);
    event TokenWithdrawn(address indexed creator, address token, uint256 amount);
    event EthWithdrawn(address indexed creator, uint256 amount);

    constructor(address _priceFeed){
        require(_priceFeed != address(0), "Invalid price feed address");
        owner = msg.sender;
        // priceFeed = AggregatorV3Interface(
        // _priceFeed
        // );
    }

    modifier onlyOwner{
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyCreator{
        require(isCreator[msg.sender], "You are not a creator" );
        _;
    }

    function registerCreator(address _creator)external onlyOwner{
        require(!isCreator[_creator], "Already registered");
        isCreator[_creator] = true;
        creators.push(_creator);

        emit CreatorAdded(_creator);

    }


    // function getLatestPrice() public view returns (uint256) {
    // (, int256 price,,,) = priceFeed.latestRoundData();
    // return uint256(price); // price has 8 decimals
    // }

    // function convertUsdToEth(uint256 usdAmount) public view returns(uint256) {
    // uint256 ethPrice = getLatestPrice();
    // return (usdAmount * 1e18) / ethPrice;
    // }

    function tipCreatorToken(address creator, address token, uint256 amount) external {
    require(isCreator[creator], "Not a creator");
    require(amount > 0, "Amount must be > 0");

    // Update creator's balance for this token
    creatorTokenBalances[creator][token] += amount;

    // Transfer token from sender to contract
    // bool success = IERC20(token).transferFrom(msg.sender, address(this), amount);
    // require(success, "Token transfer failed");

    emit TokenTipSent(msg.sender, creator, token, amount);
}

    function sendEth(address _creator) external payable{
        require(msg.value > 0, "You must send some ETH!");
        require(isCreator[_creator], "Creator not registered");

        // uint256 minTip = convertUsdToEth(1); // Minimum $1 tip
        // require(msg.value >= minTip, "Tip must be at least $1");

        creatorAllocation[_creator] += msg.value;

        emit TipSent(msg.sender, _creator, msg.value);
    }

    function withdrawToken(address token) external onlyCreator {
    uint256 amount = creatorTokenBalances[msg.sender][token];
    require(amount > 0, "No funds");

    creatorTokenBalances[msg.sender][token] = 0;

    // bool success = IERC20(token).transfer(msg.sender, amount);
    // require(success, "Token transfer failed");

    emit TokenWithdrawn(msg.sender, token, amount);
}

    function withdrawFunds() external onlyCreator{
         require(creatorAllocation[msg.sender] > 0, "No Funds have been allocated to you");

          uint amount = creatorAllocation[msg.sender];
          creatorAllocation[msg.sender] = 0;
         ( bool success, ) = msg.sender.call{value: amount}("");
         require(success, "Transaction Failed");
        
        emit EthWithdrawn(msg.sender, amount);

    }

}