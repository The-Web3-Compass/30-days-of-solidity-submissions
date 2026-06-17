// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract ActivityTracker{

    enum Actions{
        Workout, 
        Sleep,
         Nutrition,  
         Meditation
        
    }
    enum Status{
        Inactive,   
        Running,    
        Paused,     
        Finished   
    }

    mapping(address => mapping(Actions => Status)) public activities;
    event currently(Actions , Status);

function startWorkout() public {
     activities[msg.sender][Actions.Workout] = Status.Running;
     emit currently(Actions.Workout , activities[msg.sender][Actions.Workout]);
}
function pauseMeditation() public {
    require(activities[msg.sender][Actions.Meditation] == Status.Running , "it is not running now!");
     activities[msg.sender][Actions.Meditation] = Status.Paused;
     emit currently(Actions.Meditation , activities[msg.sender][Actions.Meditation]);
}
function InactivateNutrition() public {
        require(activities[msg.sender][Actions.Nutrition] == Status.Running , "it is not running now!");
     activities[msg.sender][Actions.Nutrition] = Status.Inactive;
     emit currently(Actions.Nutrition , activities[msg.sender][Actions.Nutrition]);
}
function finishSleep() public {
     require(activities[msg.sender][Actions.Sleep] == Status.Running , "it is not running now!");
     activities[msg.sender][Actions.Sleep] = Status.Finished;
     emit currently(Actions.Sleep , activities[msg.sender][Actions.Sleep]);
}

}