// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
contract tipAdder{
    address owner;
    constructor(){
        owner=msg.sender;
    }
    mapping (string=>uint)EquivalentToETH;
    uint totalAmt;
    string[] allowedCurrences;
    address[] donars;
    function getEquivalentEth(string memory curr)public returns(uint ){

    }
     
    modifier onlyOwner(){
        require(msg.sender==owner,"Not an owner");
        _;
    }
    //Function To add a New Currency
    function addNewCurrencies(string memory curr,uint _amt)onlyOwner public{
        bool found=false;
        for(uint i=0;i<allowedCurrences.length;i++){
            if(keccak256(bytes(allowedCurrences[i]))==keccak256(bytes(curr))){
                found=true;
                break ;
            }
        }
        require(found==false,"Currency is Already there!");
        allowedCurrences.push(curr);
        EquivalentToETH[curr]=_amt;
    }

    function donateAmount(string memory curr,uint amt)public payable {
        require(amt>=0,"No amount");
        require(EquivalentToETH[curr]!=0,"Currency is Already there!");
        uint inETH=amt*EquivalentToETH[curr];
        //uint inwei=InETH/(10^18);
        require(inETH<=msg.value,"No enough Value");
        totalAmt+=msg.value;
    }

    function withdraw()onlyOwner public {
        uint amt=totalAmt;
        require(amt>0,"Too less");
        (bool success,)=payable (owner).call{value:amt}("");
        require(success==true,"Failure");
        totalAmt=0;
    }
}