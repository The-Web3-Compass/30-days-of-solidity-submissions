interface IDepositBox {
    // 获取金库所有者地址
    function getOwner() external view returns (address);
    // 转移金库所有权
    function transferOwnership(address newOwner) external;
    // 存储秘密（敏感字符串）
    function storeSecret(string calldata secret) external;
    // 读取秘密（仅所有者可调用）
    function getSecret() external view returns (string memory);
    // 获取金库类型（如"Basic"/"Premium"）
    function getBoxType() external pure returns (string memory);
    // 获取金库创建时间（区块时间戳）
    function getDepositTime() external view returns (uint256);
}