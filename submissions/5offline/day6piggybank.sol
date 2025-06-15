//SPDX-License-Identifier:MIT
pragma solidity^0.8.0;
contract Etherpiggybank{
    address public bankmanager;
    address[]members;
    mapping(address=>bool)public registermembers;
    mapping(address=>uint256)balance;

    constructor(){
        bankmanager=msg.sender;
        members.push(msg.sender);

    }
    modifier onlybankmanager(){
        require(msg.sender==bankmanager, "only bank manager can perform this action.");
        _;
    }
    modifier onlyregistermember(){
        require(registermembers[msg.sender],"member is not registered.");
        _;
    }
    function addmembers(address _member)public onlybankmanager{
        require(_member !=address(0),"invalid address");
        require(_member !=msg.sender,"bank manager is already a member");
        require(!registermembers[_member],"member already registered");
        registermembers[_member]=true;
        members.push(_member);

    }
    function getmembers()public view returns(address[]memory){
        return members;
    }
    function deposit(uint256 _amount)public  onlyregistermember{
        require(_amount>0,"invalid amount");
        balance[msg.sender] +=_amount;

    }
        function depositeth()public payable onlyregistermember{
        require(msg.value >0,"invalid amount");
        balance[msg.sender] += msg.value;

    }
    function getbalance(address _member)public view returns(uint256){

        require(_member !=address(0) ,"invalid address");
        return balance[_member];
    }

    function withdraw(uint256 _amount) public onlyregistermember{
        require(_amount>0, "invalid amount");
        require(balance[msg.sender]>= _amount,"insufficient balance");
        balance[msg.sender]-=_amount;


    }


}