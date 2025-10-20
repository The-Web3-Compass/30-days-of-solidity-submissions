// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVaultBox {
    function ownerOfBox() external view returns (address);
    function typeOfBox() external view returns (string memory);
    function addValuables(
        string memory item,
        address caller
    ) external returns (bool);
    function depositETH(address caller) external payable returns (bool);
    function withdraw(address caller) external returns (bool);
    function transferOwnership(
        address newOwner,
        address caller
    ) external returns (bool);
}

contract BasicVaultBox is IVaultBox {
    string public typeOfBox;
    address public owner;
    string[] public storedItems;

    event ItemAdded(string itemName);

    constructor(address _owner, string memory _typeOfBox) {
        owner = _owner;
        typeOfBox = _typeOfBox;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call");
        _;
    }

    receive() external payable {}

    function ownerOfBox() public view virtual override returns (address) {
        return owner;
    }

    function addValuables(
        string memory item,
        address caller
    ) public override returns (bool) {
        require(caller == owner, "Only owner can call");
        storedItems.push(item);
        emit ItemAdded(item);
        return true;
    }

    function depositETH(
        address caller
    ) public payable virtual override returns (bool) {
        require(caller == owner, "Only owner can deposit");
        require(msg.value > 0, "Send valid eth");
        return true;
    }

    function withdraw(address caller) public virtual override returns (bool) {
        require(caller == owner, "Only owner can withdraw");
        storedItems = new string[](0);
        (bool success, ) = payable(owner).call{value: address(this).balance}(
            ""
        );
        require(success, "Transaction Failed");
        return true;
    }

    function transferOwnership(
        address newOwner,
        address caller
    ) public override returns (bool) {
        require(caller == owner, "Only owner can transfer");
        require(newOwner != address(0), "Not Valid Address");
        owner = newOwner;
        return true;
    }
}

contract PremiumVaultBox is BasicVaultBox {
    mapping(address => bool) public vipAccess;
    uint256 public minimumDepositAmount = 0.1 ether;

    constructor(
        address _owner,
        string memory _typeOfBox
    ) BasicVaultBox(_owner, _typeOfBox) {
        vipAccess[_owner] = true;
    }

    modifier onlyVIP(address caller) {
        require(vipAccess[caller], "Not VIP");
        _;
    }

    function grantVIP(address user, address caller) public {
        require(caller == owner, "Only owner can grant VIP");
        vipAccess[user] = true;
    }

    function depositETH(address caller) public payable override returns (bool) {
        require(msg.value >= minimumDepositAmount, "Minimum 0.1 ETH required");
        return super.depositETH(caller);
    }

    function withdraw(
        address caller
    ) public override onlyVIP(caller) returns (bool) {
        storedItems = new string[](0);
        (bool success, ) = payable(caller).call{value: address(this).balance}(
            ""
        );
        require(success, "Transaction Failed");
        return true;
    }
}
