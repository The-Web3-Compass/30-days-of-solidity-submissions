pragma solidity ^0.8.10;
import "./BaseDeposit.sol";
contract PremiumVault is BaseDeposit {
    struct SetTimingInfos{
        uint endTime;
        uint startTime;
        uint timeInterval;
        bool isUpdatedOnTime;
        address Beneficiary;
    }
    string private metaData;
    bool private isSentToBeneficiary=false;
    uint public timeInterval;
    FileVault private attachedFile;
    bool isUpdated=false;
    SetTimingInfos private time;
    bool hasFile=false;
    bool sentToBeneficiary=false;
    event ownershipTrasferredToBeneficiary(address owner);
    constructor(address _owner,uint _timeInterval,address beneficiary) {
        box.BoxType = "Premium";
        box.owner = _owner;
        time.timeInterval = _timeInterval;
        time.Beneficiary=beneficiary;
    }
    event MetadataUpdated(address indexed owner);
    event FileAttached(string fileName, string ipfsHash);
    event TimeUpdated(uint time);
    function getBoxType() external pure override returns (string memory) {
        return box.BoxType;
    }
    function setMetaData(string memory _mData) external onlyOwner {
        metaData = _mData;
    }
    function getMetaData() external view onlyOwner returns (string memory) {
        return metaData;
    }
    function startTimerAgain()internal{
        time.startTime=block.timestamp;
        time.endTime=time.timeInterval+block.timestamp;
        time.isUpdatedOnTime=false;
    }
    function attachFile(string calldata _hash,string calldata _name,string calldata _type) external onlyOwner {
        attachedFile = FileVault(_hash, _name, _type);
        hasFile = true;
        startTimerAgain();
        emit FileAttached(_name, _hash);
    }
    // NEW: Function to retrieve the file data
    function getFileData()external view onlyOwner() returns (FileVault memory){
        require(hasFile, "No file attached to this vault");
        return attachedFile;
    }
    modifier isSentToBeneficiery(){
        require(sentToBeneficiary==false,"Already sent to Beneficery!");
        _;
    }
    function updateContract()external onlyOwner() {
        require(block.timestamp<time.endTime,"Time Passed !");
        time.isUpdatedOnTime=true;
    }

    function checkAtEnd() isSentToBeneficiery external{
        require(block.timestamp>=time.endTime,"Time Passed !");
        if(time.isUpdatedOnTime==true){
            startTimerAgain();
            return;
        }else{
            sentToBeneficiary=true;
            box.owner=time.Beneficiary;
            emit ownershipTrasferredToBeneficiary(box.owner);
        }
    }
}
