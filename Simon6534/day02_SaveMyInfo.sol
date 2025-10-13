// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SaveMyInfo{
    string name;
    string bio;
    string homeAddress;
    
    // function addInfo(string memory _name, string memory _bio, string memory _homeAddress) public {
    //     name = _name;
    //     bio = _bio;
    //     homeAddress = _homeAddress;
    // }
    // function retrieve() public view returns(string memory, string memory, string memory) {
    //     return (name, bio, homeAddress);
    // }
    // function saveAndRetrieve(
    //     string memory _name, 
    //     string memory _bio, 
    //     string memory _homeAddress
    // ) public returns (string memory, string memory, string memory){
    //     name = _name;
    //     bio = _bio;
    //     homeAddress = _homeAddress;
    //     return (name, bio, homeAddress);
    // }
    function saveAndRetrieveOptimized(
        string memory _name,
        string memory _bio,
        string memory _homeAddress
    ) public returns (string memory, string memory, string memory) {
        // 写入 storage（必要）
        name = _name;
        bio = _bio;
        homeAddress = _homeAddress;

        // ✅ 直接返回内存变量（不需要再去 storage 拷贝）
        return (_name, _bio, _homeAddress);
    }

    // 用于查看链上存储结果（验证确实存入了）
    function retrieve() public view returns (string memory, string memory, string memory) {
        return (name, bio, homeAddress);
    }
}