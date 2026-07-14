// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./BaseDepositBox.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract BasicDepositBox is BaseDepositBox {
    function getBoxType() external pure override returns (string memory) {
        return "Basic";
    }
}

contract PremiumDepositBox is BaseDepositBox {
    mapping(string => string) public metadata;
    
    function setMetadata(string memory key, string memory value) external onlyOwner {
        metadata[key] = value;
    }
    
    function getBoxType() external pure override returns (string memory) {
        return "Premium";
    }
}

contract TimeLockedDepositBox is BaseDepositBox {
    uint256 public unlockTime;
    
    constructor(uint256 _lockDuration) {
        unlockTime = block.timestamp + _lockDuration;
    }
    
    modifier timeUnlocked() {
        require(block.timestamp >= unlockTime, "Still locked");
        _;
    }
    
    function getSecret() public view override timeUnlocked returns (string memory) {
        return super.getSecret();
    }
    
    function getBoxType() external pure override returns (string memory) {
        return "TimeLocked";
    }
}

contract MultiSigDepositBox is BasicDepositBox{
    address[] public owners;
    uint256 public requiredApprovals;

    mapping(address => bool) public isOwner;
    mapping(address => bool) public approvals;
    uint256 public approvalCount;

    constructor(address[] memory _owners, uint256 _required) {
        require(_required <= _owners.length, "Invalid approvals");

        for(uint i = 0; i < _owners.length; i++){
            owners.push(_owners[i]);
            isOwner[_owners[i]] = true;
        }

        requiredApprovals = _required;
    }

    modifier onlyOwners() {
        require(isOwner[msg.sender], "Not owner");
        _;
    }

    function approve() external onlyOwners {
        require(!approvals[msg.sender], "Already approved");

        approvals[msg.sender] = true;
        approvalCount++;
    }

     function getSecret() public view override returns (string memory) {
        require(approvalCount >= requiredApprovals, "Not enough approvals");
        return super.getSecret();
    }

    function getBoxType() external pure override returns (string memory) {
        return "MultiSig";
    }
}

contract RecurringDepositBox is BaseDepositBox {

    uint256 public depositAmount;
    uint256 public interval;
    uint256 public lastDeposit;

    constructor(uint256 _amount, uint256 _interval) {
        depositAmount = _amount;
        interval = _interval;
        lastDeposit = block.timestamp;
    }

    function deposit() external payable {
        require(msg.value == depositAmount, "Incorrect deposit");
        require(block.timestamp >= lastDeposit + interval, "Too early");

        lastDeposit = block.timestamp;
    }

    function getBoxType() external pure override returns (string memory) {
        return "Recurring";
    }
}



contract NFTDepositBox is BaseDepositBox {

    struct StoredNFT {
        address nftContract;
        uint256 tokenId;
    }

    StoredNFT[] public storedNFTs;

    function depositNFT(address nftContract, uint256 tokenId) external onlyOwner {

        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        storedNFTs.push(StoredNFT({
            nftContract: nftContract,
            tokenId: tokenId
        }));
    }

    function withdrawNFT(uint256 index) external onlyOwner {

        StoredNFT memory nft = storedNFTs[index];

        IERC721(nft.nftContract).transferFrom(address(this), msg.sender, nft.tokenId);
    }

    function getBoxType() external pure override returns (string memory) {
        return "NFTVault";
    }
}

contract SocialRecoveryBox is BaseDepositBox {

    
    address[] public guardians;
    mapping(address => bool) public isGuardian;

    mapping(address => uint256) public recoveryVotes;

    uint256 public requiredVotes;

    constructor(address[] memory _guardians, uint256 _votes) {

        for(uint i = 0; i < _guardians.length; i++){
            guardians.push(_guardians[i]);
            isGuardian[_guardians[i]] = true;
        }

        requiredVotes = _votes;
    }

    modifier onlyGuardian() {
        require(isGuardian[msg.sender], "Not guardian");
        _;
    }

    function voteRecovery(address newOwner) external onlyGuardian {

        recoveryVotes[newOwner]++;

        if(recoveryVotes[newOwner] >= requiredVotes){
            owner = newOwner;
        }
    }

    function getBoxType() external pure override returns (string memory) {
        return "SocialRecovery";
    }
}

contract DAODepositBox is BaseDepositBox {

    mapping(address => bool) public members;
    uint256 public votes;
    uint256 public requiredVotes;

    constructor(address[] memory _members, uint256 _requiredVotes){

        for(uint i = 0; i < _members.length; i++){
            members[_members[i]] = true;
        }

        requiredVotes = _requiredVotes;
    }

    modifier onlyMember(){
        require(members[msg.sender], "Not DAO member");
        _;
    }

    function vote() external onlyMember {
        votes++;
    }

    function getSecret() public view override returns (string memory) {
        require(votes >= requiredVotes, "DAO has not approved");
        return super.getSecret();
    }

    function getBoxType() external pure override returns (string memory) {
        return "DAO";
    }
}