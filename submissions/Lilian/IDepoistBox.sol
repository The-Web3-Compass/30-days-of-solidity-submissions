interface IDepoistbox {
    function getOwner() external view returns (address);////返回存款箱所有者
    function transferOwnerShip(address newOwner)external;//允许将所有权转让给其他人
    function storeSecret (string calldata secret) external ;//一个保存字符串的函数
    function getSecret()external view returns(string memory);//检索存储的函数
    function getBoxType()external pure returns(string memory);//是哪种类型的存储
    function getDepoistTime() external view returns(uint256);//返回存款箱的设置时间
}