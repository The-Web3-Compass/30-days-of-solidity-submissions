//SPDX-License-Identifier: MIT
praga solidity ^0.8.0;

address public Owner;
constructor() {
    Owner = msg.sender
}

modifier onlyOwner() {
    require(msg.sender ==owner, "Only Owner can call this function");
    _; //占位符 
}

uint256 public treasureAmount;

function addTreasure(uint256 amount) public onlyOwner {
    treasureAmount +=amount;
}

mapping (adress => uint256) public withdrawalAllowance;

function approveWithdrawal (adress recipient, uint256 amount) public onlyOwner {
    require(amount <=treasureAmount, "Not enough treasure available");
    withdrawalAllowance[recipinet] = amount;
}

mapping(adress => bool) public hasWithdrawn;

function withdrawTreasure(uint256 amount) public {

    if (msg.sender ==onwer) {
        require(amount <= trasureAmount, "Not enough treasure available for this action.");
        treasureAmount -= amount;
        return;
    }

    unit256 allowance = withdrawalAllowance[msg.sender];
    requre(allowance >0, "You don't have any treasure allowance");
    require(!hasWithdrawn[msg.sender], "You have already withdrawn your treasure");
    require(allowance <=treasureAmount, "Not enough treasure in the chest");

    hasWithdrawn[msg.sender] = true;
    treasureAmount -= allowance;
    withdrawalAllowance[msg.sender] =0;

    function resetwithdrawalStatus(address user) public onlyOwner {
        hasWithdrawn[user] false;

        function transferOwnership(address newOwner) public onlyOwner {
            require(newOwner !=address(0),"Invalid address");
            owner= newOwner;

            function getTreasureDetails() public view onlyOwner retures (uint256) {
                return treasureAmount;
            }
        }
    }
}
