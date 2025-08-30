// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

contract EtherPiggyBank {

    address public bankManager;
    uint256 deposited;
    mapping(address => uint256) userBalance;
    mapping(address => bool) registeredMembers;
    address[] members;
    
    constructor(){
        bankManager = msg.sender;
        members.push(msg.sender);
        registeredMembers[msg.sender] = true;
    }

    modifier onlyBankManager(){
        require(bankManager == msg.sender, "not authorized");
        _;
    }

    modifier isRegistered(){
        require(registeredMembers[msg.sender] == true, "member is not registered");
        _;
    }

    function addUser(address _newUser) public onlyBankManager() {
        require(_newUser != address(0), "Invalid address");
        require(_newUser != msg.sender, "bank manager is already registered");
        require(!registeredMembers[_newUser], "Already registered");

        members.push(_newUser);
        registeredMembers[_newUser] = true;
        userBalance[_newUser] = 0;
    }

    function deposit (uint256 _amount) external payable isRegistered {
        require(_amount > 0 , "deposit amount must be greater than 0");

        userBalance[msg.sender] += _amount;
        deposited += _amount;
    }

    function depositEther () external payable isRegistered {
        require(msg.value > 0 , "deposit amount must be greater than 0");

        userBalance[msg.sender] += msg.value;
        deposited += msg.value;
    }

    function withdraw(uint256 _withdrawAmount) external payable isRegistered {
        require(_withdrawAmount > 0 , "withdraw amount must be greater than 0");
        require(_withdrawAmount <= userBalance[msg.sender] , "Insufficient balance");


        userBalance[msg.sender] -= _withdrawAmount;
        deposited -= _withdrawAmount;
    }

    function getMembers() public view returns(address[] memory) {
        return members;
    }

    function getBalance() public view returns(uint256) {
        return deposited;
    }

    function getUserBalance(address _user) public view returns(uint256){
        return userBalance[_user];
    }
}