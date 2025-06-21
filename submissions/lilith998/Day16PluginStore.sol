// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Core Profile Contract (Diamond)
contract ProfileCore {
    struct PlayerProfile {
        string name;
        string avatar;
    }

    // Storage layout:
    address private _owner;
    mapping(address => PlayerProfile) private _profiles;
    mapping(bytes4 => address) private _selectorToPlugin;

    event PluginUpdated(bytes4 indexed selector, address indexed plugin);
    event ProfileUpdated(address indexed player);

    modifier onlyOwner() {
        require(msg.sender == _owner, "Unauthorized");
        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    // Register/update plugin functions
    function updatePlugin(bytes4[] calldata selectors, address plugin) external onlyOwner {
        for (uint i = 0; i < selectors.length; i++) {
            _selectorToPlugin[selectors[i]] = plugin;
            emit PluginUpdated(selectors[i], plugin);
        }
    }

    // Core profile management
    function setProfile(string calldata name, string calldata avatar) external {
        _profiles[msg.sender] = PlayerProfile(name, avatar);
        emit ProfileUpdated(msg.sender);
    }

    function getProfile(address player) external view returns (string memory, string memory) {
        PlayerProfile storage profile = _profiles[player];
        return (profile.name, profile.avatar);
    }

    // Diamond pattern fallback
    fallback() external payable {
        address plugin = _selectorToPlugin[msg.sig];
        require(plugin != address(0), "Function not implemented");
        
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), plugin, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable {}
}