// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface LinkTokenInterface {
    function transfer(address to, uint value) external returns (bool);
    function balanceOf(address owner) external view returns (uint256 balance);
}

contract WeatherOracle {
    uint256 public constant MIN_RAINFALL = 500; 
    uint256 public constant INSURANCE_PRICE = 0.1 ether;
    uint256 public constant PAYOUT_AMOUNT = 1 ether;
    
    address public oracle;
    bytes32 public jobId;
    uint256 public fee;
    address public owner;
    address public chainlinkToken;
    
    struct Policy {
        address farmer;
        uint256 startDate;
        uint256 endDate;
        string location;
        uint256 rainfallThreshold;
        bool claimed;
    }
    
    mapping(bytes32 => address) public requestToFarmer;
    mapping(address => Policy) public policies;
    
    event PolicyPurchased(address indexed farmer, uint256 startDate, uint256 endDate, string location);
    event ClaimRequested(address indexed farmer, bytes32 requestId);
    event ClaimApproved(address indexed farmer, uint256 rainfallAmount);
    event ClaimRejected(address indexed farmer, uint256 rainfallAmount);
    
    constructor() {
        owner = msg.sender;
        chainlinkToken = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB; 
        oracle = 0x40193c8518BB267228Fc409a613bDbD8eC5a97b3; 
        jobId = "ca98366cc7314957b8c012c72f05aeeb";
        fee = 0.1 * 10**18; 
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Owner only");
        _;
    }
    
    function purchasePolicy(uint256 durationDays, string calldata location) external payable {
        require(msg.value == INSURANCE_PRICE, "Incorrect payment");
        require(policies[msg.sender].farmer == address(0), "Policy already exists");
        
        policies[msg.sender] = Policy({
            farmer: msg.sender,
            startDate: block.timestamp,
            endDate: block.timestamp + (durationDays * 1 days),
            location: location,
            rainfallThreshold: MIN_RAINFALL,
            claimed: false
        });
        
        emit PolicyPurchased(msg.sender, block.timestamp, block.timestamp + (durationDays * 1 days), location);
    }
    
    function requestClaim() external {
        Policy storage policy = policies[msg.sender];
        require(policy.farmer == msg.sender, "No policy found");
        require(block.timestamp > policy.endDate, "Policy not expired");
        require(!policy.claimed, "Claim already processed");
        
        
        bytes32 requestId = keccak256(abi.encodePacked(block.timestamp, msg.sender));
        requestToFarmer[requestId] = msg.sender;
        
        
        this.fulfill(requestId, 450); 
        
        emit ClaimRequested(msg.sender, requestId);
    }
    
    function fulfill(bytes32 requestId, uint256 rainfall) external {
        address farmer = requestToFarmer[requestId];
        Policy storage policy = policies[farmer];
        
        require(!policy.claimed, "Claim already processed");
        policy.claimed = true;
        
        if (rainfall < policy.rainfallThreshold) {
            payable(farmer).transfer(PAYOUT_AMOUNT);
            emit ClaimApproved(farmer, rainfall);
        } else {
            emit ClaimRejected(farmer, rainfall);
        }
    }
    
    function withdrawLink() external onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkToken);
        require(link.transfer(owner, link.balanceOf(address(this))), "Unable to transfer");
    }
    
    function withdrawFunds() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
    
    function setOracle(address _oracle) external onlyOwner {
        oracle = _oracle;
    }
    
    function setJobId(bytes32 _jobId) external onlyOwner {
        jobId = _jobId;
    }
    
    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }
    
    
    receive() external payable {}
}
