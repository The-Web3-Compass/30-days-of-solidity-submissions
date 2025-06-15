// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.20;
import "./Day14-IDepositBox.sol";
import "./Day14-BasicDepositBox.sol";
import "./Day14-PremiumDepositBox.sol";
import "./Day14-TimeLockedDepositBox.sol";

contract VaultManager{

    /**- Lets users create any type of vault
    - Keeps track of which boxes belong to which users
    - Allows vaults to be renamed
    - Handles ownership transfers
    - Acts as a single point of interaction for the whole system
    */


    mapping(address => address[]) private userDepositBoxes;
    mapping(address => string) private boxNames;

    event BoxCreated(address indexed owner, address indexed boxAddress, string boxType);
    event BoxNamed(address indexed boxAddress, string name);

    function createBox() public returns(address){
        // Default create box's type is "Basic" and owner is msg.sender,depositTime is block.timestamp
        BasicDepositBox box = new BasicDepositBox();
        userDepositBoxes[msg.sender].push(address(box));
        emit BoxCreated(msg.sender, address(box), "Basic");
        return address(box);
    }

    function createPremiumBox() external returns (address) {
        // Default create box's type is "Premium" and owner is msg.sender,depositTime is block.timestamp
        PremiumDepositBox box = new PremiumDepositBox();
        userDepositBoxes[msg.sender].push(address(box));
        emit BoxCreated(msg.sender, address(box), "Premium");
        return address(box);
    }

    function createTimeLockedBox(uint256 lockDuration) external returns (address) {
        // Default create box's type is "TimeLocked" and owner is msg.sender,depositTime is block.timestamp
        TimeLockedDepositBox box = new TimeLockedDepositBox(lockDuration);
        userDepositBoxes[msg.sender].push(address(box));
        emit BoxCreated(msg.sender, address(box), "TimeLocked");
        return address(box);
    }


    function nameBox(address boxAddress, string calldata name) external {
        // We cast the generic address into the interface
        IDepositBox box = IDepositBox(boxAddress);
        require(box.getOwner() == msg.sender, "Not the box owner");

        boxNames[boxAddress] = name;
        emit BoxNamed(boxAddress, name);
    }

    function storeSecret(address boxAddress, string calldata secret) external {
        IDepositBox box = IDepositBox(boxAddress);
        require(box.getOwner() == msg.sender, "Not the box owner");

        box.storeSecret(secret);
    }

    function transferBoxOwnership(address boxAddress, address newOwner) external {
        IDepositBox box = IDepositBox(boxAddress);
        require(box.getOwner() == msg.sender, "Not the box owner");
        // = call BaseDepositBox's transferOwnership
        // The actual box owns the data and logic — VaultManager doesn't control it.
        // so this step ensures the box updates its own permissions.
        box.transferOwnership(newOwner);

        address[] storage boxes = userDepositBoxes[msg.sender];
        for (uint i = 0; i < boxes.length; i++) {
            if (boxes[i] == boxAddress) {
                boxes[i] = boxes[boxes.length - 1];
                boxes.pop();
                break;
            }
        }

        userDepositBoxes[newOwner].push(boxAddress);
    }

    function getBoxName(address boxAddress) external view returns (string memory) {
        return boxNames[boxAddress];
    }


    function getUserBoxes(address user) external view returns (address[] memory) {
        return userDepositBoxes[user];
    }

    function getBoxInfo(address boxAddress) external view returns (
        string memory boxType,
        address owner,
        uint256 depositTime,
        string memory name
    ) {
        IDepositBox box = IDepositBox(boxAddress);
        return (
            box.getBoxType(),
            box.getOwner(),
            box.getDepositTime(),
            // also can box.getSecret();
            boxNames[boxAddress]
        );

    }

}