// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract WeaponStorePlugin {

    //变量：
    mapping(address => string) public equippedWeapon;


    function setWeapon(address user, string memory weapon) public {
        equippedWeapon[user] = weapon;
    }
    //写入现在的武器
    function getWeapon(address user) public view returns (string memory) {
        return equippedWeapon[user];
    }
    //写了一个自定义getter

}
//    pluginStore.runPlugin("weapon", "setWeapon(address,string)", msg.sender, "Golden Axe");
//参数，签名，装备名字
//给了key user 和address就可以进入plugin视图
//在一个合同里写很多是很臃肿的，灵活运用call可以小部分地更改部署，可以添加别的东西

//0x3328358128832A260C76A4141e19E2A943CD4B6D

   
