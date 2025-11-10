// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title UpgradeableProxy (EIP-1967 style)
/// @notice Minimal upgradeable proxy that stores implementation/admin in reserved slots and forwards calls via delegatecall.
/// Admin functions: upgradeTo, changeAdmin; fallback delegates to implementation.
contract UpgradeableProxy {
    // EIP-1967 implementation slot: bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
    bytes32 private constant IMPLEMENTATION_SLOT = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
    // EIP-1967 admin slot: bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1)
    bytes32 private constant ADMIN_SLOT = bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1);

    event Upgraded(address indexed implementation);
    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);

    constructor(address _implementation, bytes memory _data) {
        require(_implementation != address(0), "impl=0");
        _setAdmin(msg.sender);
        _setImplementation(_implementation);

        // optional initializer call to implementation via delegatecall
        if (_data.length > 0) {
            (bool ok, ) = _implementation.delegatecall(_data);
            require(ok, "init-failed");
        }
    }

    // ---------------- admin ----------------
    modifier onlyAdmin() {
        require(msg.sender == _admin(), "not-admin");
        _;
    }

    function admin() external view returns (address) {
        return _admin();
    }

    function implementation() external view returns (address) {
        return _implementation();
    }

    function upgradeTo(address newImplementation) external onlyAdmin {
        require(newImplementation != address(0), "impl=0");
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    function changeAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "admin=0");
        address old = _admin();
        _setAdmin(newAdmin);
        emit AdminChanged(old, newAdmin);
    }

    // ---------------- storage helpers ----------------
    function _implementation() internal view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly { impl := sload(slot) }
    }

    function _admin() internal view returns (address adm) {
        bytes32 slot = ADMIN_SLOT;
        assembly { adm := sload(slot) }
    }

    function _setImplementation(address newImpl) internal {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly { sstore(slot, newImpl) }
    }

    function _setAdmin(address newAdmin) internal {
        bytes32 slot = ADMIN_SLOT;
        assembly { sstore(slot, newAdmin) }
    }

    // ---------------- delegate ----------------
    fallback() external payable {
        _delegate();
    }

    receive() external payable {
        _delegate();
    }

    function _delegate() internal {
        address impl = _implementation();
        require(impl != address(0), "impl-not-set");
        assembly {
            // copy calldata
            calldatacopy(0, 0, calldatasize())
            // delegatecall(gas, impl, calldata, calldatasize, 0, 0)
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            // copy returned data
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}
