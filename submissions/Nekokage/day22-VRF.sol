// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleLottery {
    address public owner;
    
    enum LotteryState { OPEN, CLOSED, CALCULATING }
    LotteryState public lotteryState;
    
    address payable[] public players;
    address public recentWinner;
    uint256 public entryFee;
    
    event LotteryStarted();
    event PlayerEntered(address player);
    event LotteryEnded(address winner, uint256 prize);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }
    
    constructor(uint256 _entryFee) {
        owner = msg.sender;
        entryFee = _entryFee;
        lotteryState = LotteryState.CLOSED;
    }
    
    function enter() public payable {
        require(lotteryState == LotteryState.OPEN, "Lottery not open");
        require(msg.value == entryFee, "Must pay exact entry fee");
        
        players.push(payable(msg.sender));
        emit PlayerEntered(msg.sender);
    }
    
    function startLottery() public onlyOwner {
        require(lotteryState == LotteryState.CLOSED, "Lottery already open");
        lotteryState = LotteryState.OPEN;
        emit LotteryStarted();
    }
    
    function endLottery() public onlyOwner {
        require(lotteryState == LotteryState.OPEN, "Lottery not open");
        require(players.length > 0, "No players");
        
        lotteryState = LotteryState.CALCULATING;
        
        uint256 winnerIndex = _generateRandomNumber() % players.length;
        address payable winner = players[winnerIndex];
        recentWinner = winner;
        
        uint256 prize = address(this).balance;
        
        (bool success, ) = winner.call{value: prize}("");
        require(success, "Transfer failed");
        
        players = new address payable[](0);
        lotteryState = LotteryState.CLOSED;
        
        emit LotteryEnded(winner, prize);
    }
    
    function _generateRandomNumber() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty,
            players.length
        )));
    }
    
    function getPlayerCount() public view returns (uint256) {
        return players.length;
    }
    
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    function getCurrentPrize() public view returns (uint256) {
        return address(this).balance;
    }
    
    function withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}