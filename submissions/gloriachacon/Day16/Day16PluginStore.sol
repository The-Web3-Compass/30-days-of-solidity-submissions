// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

error NotOwner();
error NoPlugin();

contract PluginStore {
    address public owner;
    mapping(bytes4 => address) public plugin;

    mapping(address => bytes32) public name;
    mapping(address => bytes32) public avatar;
    mapping(address => mapping(bytes32 => bool)) public badge;

    event PluginSet(bytes4 sel, address impl);
    event PluginRemoved(bytes4 sel);

    constructor() { owner = msg.sender; }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    function setPlugin(bytes4 sel, address impl) external onlyOwner {
        plugin[sel] = impl;
        emit PluginSet(sel, impl);
    }

    function removePlugin(bytes4 sel) external onlyOwner {
        delete plugin[sel];
        emit PluginRemoved(sel);
    }

    function exec(bytes calldata data) external payable returns (bytes memory out) {
        address impl = plugin[bytes4(data)];
        if (impl == address(0)) revert NoPlugin();
        (bool ok, bytes memory ret) = impl.delegatecall(data);
        if (!ok) assembly { revert(add(ret, 32), mload(ret)) }
        return ret;
    }

    fallback() external payable {
        address impl = plugin[msg.sig];
        if (impl == address(0)) revert NoPlugin();
        assembly {
            calldatacopy(0, 0, calldatasize())
            let ok := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(0, 0, size)
            switch ok
            case 0 { revert(0, size) }
            default { return(0, size) }
        }
    }

    receive() external payable {}
}

contract NamePlugin {
    address public owner;
    mapping(bytes4 => address) public plugin;
    mapping(address => bytes32) public name;
    mapping(address => bytes32) public avatar;
    mapping(address => mapping(bytes32 => bool)) public badge;

    event NameSet(address indexed user, bytes32 name_);

    function setName(bytes32 n) external {
        name[msg.sender] = n;
        emit NameSet(msg.sender, n);
    }

    function getName(address u) external view returns (bytes32) {
        return name[u];
    }
}

contract AvatarBadgePlugin {
    address public owner;
    mapping(bytes4 => address) public plugin;
    mapping(address => bytes32) public name;
    mapping(address => bytes32) public avatar;
    mapping(address => mapping(bytes32 => bool)) public badge;

    event AvatarSet(address indexed user, bytes32 avatar_);
    event BadgeGiven(address indexed user, bytes32 badge_);

    function setAvatar(bytes32 a) external {
        avatar[msg.sender] = a;
        emit AvatarSet(msg.sender, a);
    }

    function giveBadge(bytes32 b) external {
        badge[msg.sender][b] = true;
        emit BadgeGiven(msg.sender, b);
    }

    function hasBadge(address u, bytes32 b) external view returns (bool) {
        return badge[u][b];
    }
}