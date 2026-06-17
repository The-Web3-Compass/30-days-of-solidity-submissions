// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library PluginStore{
     function feeMaths(uint256 fee, uint256 amount )public returns(uint256){
         return fee * amount; 

     }
}