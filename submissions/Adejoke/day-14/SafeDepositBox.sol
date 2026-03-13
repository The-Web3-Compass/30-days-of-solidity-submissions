// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface IDepositBox {
    function getOwner() external view returns (address);
    function transferOwnership(address newOwner) external;
    function storeSecret(string calldata secret) external;
    function getSecret() external view returns (string memory);
    function getBoxType() external pure returns (string memory);
    function getDepositTime() external view returns (uint256);
}

abstract contract BaseDepositBox is IDepositBox {
    address private owner;
    string private secret;
    uint256 private depositTime;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        depositTime = block.timestamp;
    }

    function storeSecret(string calldata _secret) external virtual override onlyOwner {
        secret = _secret;
    }

    function getSecret() public view virtual override onlyOwner returns (string memory) {
        return secret;
    }

    function getOwner() public view override returns (address) {
        return owner;
    }

    function transferOwnership(address newOwner) external override onlyOwner {
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
    }

    function getDepositTime() external view virtual override returns (uint256) {
        return depositTime;
    }

    function getBoxType() external pure virtual override returns (string memory);
}

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

contract MultiSigDepositBox is BaseDepositBox {
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public requiredApprovals;
    
    string private multiSecret;
    string private proposedSecret;
    uint256 public approvalCount;
    mapping(address => bool) public hasApprovedSecret;

    constructor(address[] memory _owners, uint256 _requiredApprovals) {
        require(_requiredApprovals > 0 && _requiredApprovals <= _owners.length);
        for(uint i = 0; i < _owners.length; i++) {
            require(!isOwner[_owners[i]]);
            isOwner[_owners[i]] = true;
            owners.push(_owners[i]);
        }
        requiredApprovals = _requiredApprovals;
    }

    modifier onlyMultiSigOwner() {
        require(isOwner[msg.sender] || msg.sender == getOwner());
        _;
    }

    function proposeSecret(string calldata _secret) external onlyMultiSigOwner {
        proposedSecret = _secret;
        approvalCount = 1;

        for (uint i = 0; i < owners.length; i++) {
            hasApprovedSecret[owners[i]] = false;
        }
        hasApprovedSecret[getOwner()] = false;
        hasApprovedSecret[msg.sender] = true;
        
        if (approvalCount >= requiredApprovals) {
            multiSecret = proposedSecret;
        }
    }

    function approveSecret() external onlyMultiSigOwner {
        require(!hasApprovedSecret[msg.sender]);
        hasApprovedSecret[msg.sender] = true;
        approvalCount++;

        if (approvalCount >= requiredApprovals) {
            multiSecret = proposedSecret;
        }
    }

    function storeSecret(string calldata) external override onlyMultiSigOwner {
        revert();
    }

    function getSecret() public view override onlyMultiSigOwner returns (string memory) {
        return multiSecret;
    }

    function getBoxType() external pure override returns (string memory) {
        return "MultiSig";
    }
}

contract RecurringDepositBox is BaseDepositBox {
    uint256 public depositInterval;
    uint256 public nextDepositTime;
    uint256 public requiredAmount;
    uint256 public totalDeposited;

    constructor(uint256 _interval, uint256 _amount) {
        depositInterval = _interval;
        requiredAmount = _amount;
        nextDepositTime = block.timestamp + _interval;
    }

    function deposit() external payable {
        require(block.timestamp >= nextDepositTime);
        require(msg.value == requiredAmount);
        totalDeposited += msg.value;
        nextDepositTime += depositInterval;
    }

    function getBoxType() external pure override returns (string memory) {
        return "Recurring";
    }
}

contract NFTDepositBox is BaseDepositBox {
    struct NFTInfo {
        address tokenAddress;
        uint256 tokenId;
    }
    
    NFTInfo[] public nfts;

    function depositNFT(address tokenAddress, uint256 tokenId) external {
        require(msg.sender == getOwner());
        IERC721(tokenAddress).transferFrom(msg.sender, address(this), tokenId);
        nfts.push(NFTInfo(tokenAddress, tokenId));
    }

    function withdrawNFT(uint256 index) external {
        require(msg.sender == getOwner());
        require(index < nfts.length);
        NFTInfo memory nft = nfts[index];
        IERC721(nft.tokenAddress).transferFrom(address(this), msg.sender, nft.tokenId);
        
        nfts[index] = nfts[nfts.length - 1];
        nfts.pop();
    }

    function getBoxType() external pure override returns (string memory) {
        return "NFT";
    }
}

contract SocialRecoveryBox is BaseDepositBox {
    address[] public guardians;
    mapping(address => bool) public isGuardian;
    uint256 public requiredRecoveries;
    
    address public proposedOwner;
    uint256 public recoveryCount;
    mapping(address => bool) public hasVotedRecovery;
    
    address public recoveredOwner;
    string private mySecret;

    constructor(address[] memory _guardians, uint256 _requiredRecoveries) {
        require(_requiredRecoveries > 0 && _requiredRecoveries <= _guardians.length);
        for(uint i = 0; i < _guardians.length; i++) {
            isGuardian[_guardians[i]] = true;
            guardians.push(_guardians[i]);
        }
        requiredRecoveries = _requiredRecoveries;
    }

    modifier onlyGuardian() {
        require(isGuardian[msg.sender]);
        _;
    }

    function initiateRecovery(address _proposedOwner) external onlyGuardian {
        if (proposedOwner != _proposedOwner) {
            proposedOwner = _proposedOwner;
            recoveryCount = 0;
            for (uint i = 0; i < guardians.length; i++) {
                hasVotedRecovery[guardians[i]] = false;
            }
        }
        
        require(!hasVotedRecovery[msg.sender]);
        hasVotedRecovery[msg.sender] = true;
        recoveryCount++;

        if (recoveryCount >= requiredRecoveries) {
            recoveredOwner = proposedOwner;
        }
    }

    function storeSecret(string calldata _secret) external override {
        require(msg.sender == getOwner() || msg.sender == recoveredOwner);
        mySecret = _secret;
    }

    function getSecret() public view override returns (string memory) {
        require(msg.sender == getOwner() || msg.sender == recoveredOwner);
        return mySecret;
    }

    function getBoxType() external pure override returns (string memory) {
        return "SocialRecovery";
    }
}

contract DAODepositBox is BaseDepositBox {
    struct Proposal {
        string proposedSecret;
        uint256 votes;
        bool executed;
    }
    
    mapping(address => uint256) public memberShares;
    uint256 public totalShares;
    
    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public voted;
    
    string private daoSecret;

    constructor(address[] memory members, uint256[] memory shares) {
        require(members.length == shares.length);
        for(uint i = 0; i < members.length; i++) {
            memberShares[members[i]] = shares[i];
            totalShares += shares[i];
        }
    }

    modifier onlyMember() {
        require(memberShares[msg.sender] > 0);
        _;
    }

    function createProposal(string calldata _secret) external onlyMember {
        proposalCount++;
        proposals[proposalCount].proposedSecret = _secret;
    }

    function vote(uint256 proposalId) external onlyMember {
        require(proposalId > 0 && proposalId <= proposalCount);
        Proposal storage p = proposals[proposalId];
        require(!voted[proposalId][msg.sender]);
        voted[proposalId][msg.sender] = true;
        p.votes += memberShares[msg.sender];
    }

    function executeProposal(uint256 proposalId) external onlyMember {
        require(proposalId > 0 && proposalId <= proposalCount);
        Proposal storage p = proposals[proposalId];
        require(!p.executed);
        require(p.votes > totalShares / 2);
        p.executed = true;
        daoSecret = p.proposedSecret;
    }

    function storeSecret(string calldata) external override {
        revert();
    }

    function getSecret() public view override returns (string memory) {
        require(memberShares[msg.sender] > 0 || msg.sender == getOwner());
        return daoSecret;
    }

    function getBoxType() external pure override returns (string memory) {
        return "DAO";
    }
}

contract VaultManager {
    mapping(address => IDepositBox[]) public userVaults;
    
    event VaultCreated(address indexed user, address vault, string vaultType);
    
    function createBasicVault() external returns (address) {
        BasicDepositBox vault = new BasicDepositBox();
        userVaults[msg.sender].push(IDepositBox(address(vault)));
        emit VaultCreated(msg.sender, address(vault), "Basic");
        return address(vault);
    }
    
    function createPremiumVault() external returns (address) {
        PremiumDepositBox vault = new PremiumDepositBox();
        userVaults[msg.sender].push(IDepositBox(address(vault)));
        emit VaultCreated(msg.sender, address(vault), "Premium");
        return address(vault);
    }
    
    function createTimeLockedVault(uint256 lockDuration) external returns (address) {
        TimeLockedDepositBox vault = new TimeLockedDepositBox(lockDuration);
        userVaults[msg.sender].push(IDepositBox(address(vault)));
        emit VaultCreated(msg.sender, address(vault), "TimeLocked");
        return address(vault);
    }

    function createMultiSigVault(address[] memory owners, uint256 requiredApprovals) external returns (address) {
        MultiSigDepositBox vault = new MultiSigDepositBox(owners, requiredApprovals);
        userVaults[msg.sender].push(IDepositBox(address(vault)));
        emit VaultCreated(msg.sender, address(vault), "MultiSig");
        return address(vault);
    }

    function createRecurringVault(uint256 interval, uint256 amount) external returns (address) {
        RecurringDepositBox vault = new RecurringDepositBox(interval, amount);
        userVaults[msg.sender].push(IDepositBox(address(vault)));
        emit VaultCreated(msg.sender, address(vault), "Recurring");
        return address(vault);
    }

    function createNFTVault() external returns (address) {
        NFTDepositBox vault = new NFTDepositBox();
        userVaults[msg.sender].push(IDepositBox(address(vault)));
        emit VaultCreated(msg.sender, address(vault), "NFT");
        return address(vault);
    }

    function createSocialRecoveryVault(address[] memory guardians, uint256 requiredRecoveries) external returns (address) {
        SocialRecoveryBox vault = new SocialRecoveryBox(guardians, requiredRecoveries);
        userVaults[msg.sender].push(IDepositBox(address(vault)));
        emit VaultCreated(msg.sender, address(vault), "SocialRecovery");
        return address(vault);
    }

    function createDAOVault(address[] memory members, uint256[] memory shares) external returns (address) {
        DAODepositBox vault = new DAODepositBox(members, shares);
        userVaults[msg.sender].push(IDepositBox(address(vault)));
        emit VaultCreated(msg.sender, address(vault), "DAO");
        return address(vault);
    }
    
    function getUserVaults(address user) external view returns (IDepositBox[] memory) {
        return userVaults[user];
    }
    
    function getVaultInfo(address vaultAddress) external view returns (
        string memory vaultType,
        address owner,
        uint256 depositTime
    ) {
        IDepositBox vault = IDepositBox(vaultAddress);
        return (
            vault.getBoxType(),
            vault.getOwner(),
            vault.getDepositTime()
        );
    }
}
