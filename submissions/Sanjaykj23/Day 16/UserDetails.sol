pragma solidity ^0.8.10;
contract UserDetails{
    struct User{
        bytes32 name;
        bytes15 avatar;
        uint8 level;
        uint8 userID;
        uint8[] friends;
    }
    User[] users;
    uint8 public index=0;
    function createUser(bytes32 _name, bytes15 _avatar, uint8 _level)public{
        User memory newUser=User(_name,_avatar,_level,index,new uint8[](0));
        index++;
        users[index]=newUser;
    }
    function getUser(uint8 _userID)external view returns(User memory){
        require(_userID<index,"Wrong UID!");
        return users[_userID];
    }
    function addNewFriends(uint8 userID,uint8 friendID)external{
        require(friendID<index && userID <index,"Wrong UID!");
        require(userID!=friendID,"Same ID ");
        users[userID].friends.push(friendID);
    } 
}