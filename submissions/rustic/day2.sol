//SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.30;

contract Name {
    string name;
    string bio;
    bool setting;

    function storeInfo(string memory _name, string memory _bio, bool _setting) public {
        name = _name;
        bio = _bio;
        setting = _setting;
    }

    function retriveInfo() public view returns(string memory, string memory, bool) {
        return (name, bio, setting);
    }
}