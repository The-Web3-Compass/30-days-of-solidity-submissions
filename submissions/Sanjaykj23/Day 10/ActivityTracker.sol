// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
contract activeTracker {
    address owner;
    constructor() {
        owner = msg.sender;
    }
    struct UserProfile {
        string name;
        uint weight;
        uint time;
    }
    struct Activity {
        string actv;
        uint time;
        uint dist;
    }
    mapping(address => UserProfile) User;
    mapping(address => Activity) Act;
    mapping(address => uint) totalActc;
    mapping(address => uint) totalDistance;

    event UserRegistered(address addr, string name, uint time);
    event ProfileUpdated(address addr, string name, uint new_weight, uint time);
    event MileStoneAchived(address addr, string milestone, uint time);

    function RegisterUser(string memory _name, uint _weight) public {
        require(User[msg.sender].weight == 0, "Already Registered");
        User[msg.sender] = UserProfile({
            name: _name,
            weight: _weight,
            time: block.timestamp
        });
        emit UserRegistered(msg.sender, _name, block.timestamp);
    }
    function UpdateProfile(uint _nweight) public {
        require(User[msg.sender].weight != 0, "Already Registered");
        UserProfile memory user = User[msg.sender];
        if (_nweight < user.weight - 10) {
            emit MileStoneAchived(
                msg.sender,
                "Reduced weight",
                block.timestamp
            );
        }
    }
    function addactivity(string memory activity, uint dist) public {
        Activity memory av = Act[msg.sender];
        av.dist += dist;
        if (totalActc[msg.sender] + 1 >= 5) {
            emit MileStoneAchived(
                msg.sender,
                "Done 5+ Workouts",
                block.timestamp
            );
        }
    }

}
