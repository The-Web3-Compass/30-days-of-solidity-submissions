// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

error NotOwner();
error ZeroAddress();
error Locked(uint256 until);

interface IDepositBox {
    function owner() external view returns (address);
    function transferOwnership(address newOwner) external;
    function set(bytes calldata data) external;
    function get() external view returns (bytes memory);
}

abstract contract OwnableLite {
    address private _owner;
    event OwnershipTransferred(address indexed from, address indexed to);

    constructor(address initOwner) {
        if (initOwner == address(0)) revert ZeroAddress();
        _owner = initOwner;
        emit OwnershipTransferred(address(0), initOwner);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        if (msg.sender != _owner) revert NotOwner();
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) revert ZeroAddress();
        _owner = newOwner;
        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

contract BasicBox is IDepositBox, OwnableLite {
    bytes private secret;
    event SecretUpdated(bytes data);

    constructor(address _owner) OwnableLite(_owner) {}

    function owner() public view override(IDepositBox, OwnableLite) returns (address) {
        return OwnableLite.owner();
    }

    function transferOwnership(address newOwner) public override(IDepositBox, OwnableLite) onlyOwner {
        OwnableLite.transferOwnership(newOwner);
    }

    function set(bytes calldata data) external override onlyOwner {
        secret = data;
        emit SecretUpdated(data);
    }

    function get() external view override returns (bytes memory) {
        return secret;
    }
}

contract TimeLockedBox is IDepositBox, OwnableLite {
    bytes private secret;
    uint256 public unlockAt;
    event SecretUpdated(bytes data);
    event LockSet(uint256 until);

    constructor(address _owner, uint256 _unlockAt) OwnableLite(_owner) {
        unlockAt = _unlockAt;
        emit LockSet(_unlockAt);
    }

    function owner() public view override(IDepositBox, OwnableLite) returns (address) {
        return OwnableLite.owner();
    }

    function transferOwnership(address newOwner) public override(IDepositBox, OwnableLite) onlyOwner {
        OwnableLite.transferOwnership(newOwner);
    }

    function set(bytes calldata data) external override onlyOwner {
        if (block.timestamp < unlockAt) revert Locked(unlockAt);
        secret = data;
        emit SecretUpdated(data);
    }

    function get() external view override returns (bytes memory) {
        if (block.timestamp < unlockAt) revert Locked(unlockAt);
        return secret;
    }
}

contract VaultManager {
    event BoxRegistered(address box, address owner);
    event BoxOwnershipMoved(address box, address from, address to);

    function registerBasic() external returns (address box) {
        box = address(new BasicBox(msg.sender));
        emit BoxRegistered(box, msg.sender);
    }

    function registerTimeLocked(uint256 unlockAt) external returns (address box) {
        box = address(new TimeLockedBox(msg.sender, unlockAt));
        emit BoxRegistered(box, msg.sender);
    }

    function moveOwnership(address box, address newOwner) external {
        if (IDepositBox(box).owner() != msg.sender) revert NotOwner();
        IDepositBox(box).transferOwnership(newOwner);
        emit BoxOwnershipMoved(box, msg.sender, newOwner);
    }

    function store(address box, bytes calldata data) external {
        if (IDepositBox(box).owner() != msg.sender) revert NotOwner();
        IDepositBox(box).set(data);
    }

    function read(address box) external view returns (bytes memory) {
        return IDepositBox(box).get();
    }
}