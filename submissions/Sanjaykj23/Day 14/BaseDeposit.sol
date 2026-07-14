pragma solidity ^0.8.10;
import "./IDepositBox.sol";
abstract contract BaseDeposit is IDepositBox {
    address private owner;
    //string private secret;
    struct BoxData {
        address owner; // Who owns it
        uint256 createdAt; // When it was made
        string secretCode; // The "text" secret (password/seed phrase)
        bool isActive; // Is the vault still open or destroyed?
        string BoxType;
    }
    struct FileVault {
        string ipfsHash; // The CID from IPFS (e.g., "QmXoyp...")
        string fileName; // "Life_Insurance_Policy.pdf"
        string fileType; // "application/pdf" or "video/mp4"
        //uint256 uploadTime; // When you saved it
    }
    BoxData internal box;
    FileVault vault;
    constructor() {
        box.createdAt = block.timestamp;
    }
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event SecretStored(address indexed owner);
    modifier onlyOwner() {
        require(box.owner == msg.sender, "Not a Owner");
        _;
    }
    function getOwner() public view override returns (address) {
        return box.owner;
    }
    function storeSecret(
        string calldata _mes
    ) external virtual override onlyOwner {
        box.secretCode = _mes;
        emit SecretStored(msg.sender);
    }
    function getSecret()
        public
        view
        virtual
        override
        onlyOwner
        returns (string memory)
    {
        return box.secretCode;
    }
    function getDepositTime() external view override returns (uint256) {
        return box.createdAt;
    }
    function transferOwnership(address newOwner) external override onlyOwner {
        require(newOwner != address(0), "Invalid Address");
        emit OwnershipTransferred(msg.sender, newOwner);
        box.owner = newOwner;
    }
    function getBoxType() external pure returns (string memory) {
        return "Not Set";
    }
}
