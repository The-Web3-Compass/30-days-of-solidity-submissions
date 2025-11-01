// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

contract ClickCounter{

    uint256 public counter;          
    address public lastClicker;    
    uint256 public lastClickTime; 
    mapping(address => uint256) public clicksByUser;  
    uint256 public totalUniqueClickers; 
    mapping(address => bool) private hasClicked; 

    event Clicked(address indexed clicker, uint256 newCounter, uint256 timestamp);

    event MilestoneReached(uint256 milestone, address indexed clicker, uint256 timestamp);

    modifier noSpam() {
        require(
            block.timestamp > lastClickTime + 10 seconds,
            "Please wait 10 seconds between clicks"
        );
        _;
    }

    function click() public noSpam {
        counter++;
        lastClicker = msg.sender;
        lastClickTime = block.timestamp;

        if (!hasClicked[msg.sender]) {
            hasClicked[msg.sender] = true;
            totalUniqueClickers++;
        }
        clicksByUser[msg.sender]++;

        emit Clicked(msg.sender, counter, block.timestamp);

        if (counter % 100 == 0) {
            emit MilestoneReached(counter, msg.sender, block.timestamp);
        }
    }

    function resetCounter() public {
        require(msg.sender == lastClicker, "Only last clicker can reset");
        counter = 0;
        emit Clicked(address(0), 0, block.timestamp);  
    }
    
    function getUserClicks(address user) public view returns (uint256) {
        return clicksByUser[user];
    }

    function hasUserClicked(address user) public view returns (bool) {
        return hasClicked[user];
    }

    function reset() public {
        counter = 0;
    }

    function decrease() public {
        require(counter > 0, "Counter cannot be negative");
        counter -= 1;
    }

     function getCounter() public view returns (uint256) {
        return counter;
    }

     function clickMultiple(uint256 times) public {
        counter += times;
    }

    uint256 public clickCooldown = 10;  

    function setClickCooldown(uint256 newCooldown) public {
        require(msg.sender == lastClicker, "Only last clicker can set cooldown");
        clickCooldown = newCooldown;
    }

}