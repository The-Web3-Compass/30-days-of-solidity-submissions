pragma solidity ^0.8.10;
import "./BaseDeposit.sol";
contract GoldVault is BaseDeposit {
    string private metaData;
    FileVault private attachedFile;
    bool hasFile=false;
    constructor(address _owner) {
        box.owner = _owner;
        box.BoxType = "Gold";
    }
    event MetadataUpdated(address indexed owner);
    event FileAttached(string fileName, string ipfsHash);
    function getBoxType() external pure override returns (string memory) {
        return box.BoxType;
    }
    function setMetData(string memory _data) external onlyOwner {
        metaData = _data;
        MetadataUpdated(box.owner);
    }
    function getMetaData() external view onlyOwner returns (string memory) {
        return metaData;
    }
     function attachFile(
        string calldata _hash, 
        string calldata _name, 
        string calldata _type
    ) external onlyOwner {
        attachedFile = FileVault(_hash, _name, _type);
        hasFile = true;
        emit FileAttached(_name, _hash);
    }
    // NEW: Function to retrieve the file data
    function getFileData() external view onlyOwner returns (FileVault memory) {
        require(hasFile, "No file attached to this vault");
        return attachedFile;
    }
}
