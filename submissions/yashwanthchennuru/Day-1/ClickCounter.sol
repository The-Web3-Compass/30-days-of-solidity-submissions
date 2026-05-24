//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract ClickCounter{

    uint256 public counter;
            function click() public {
                counter =counter+1;

            }
           
            function reset() public{
                counter=0;
                
            }

            function dec() public {

                counter =counter -1;
                
            }
}
