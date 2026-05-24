// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract DecentralizedLottery {

    address public owner;
    address[] public players;
    uint256 public entryFee;

    event Entered(address indexed player);
    event WinnerPicked(address indexed winner, uint256 amount);

    constructor(uint256 _entryFee) {
        owner = msg.sender;
        entryFee = _entryFee;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner allowed");
        _;
    }

    /*
     * Enter Lottery
     */
    function enter() external payable {
        require(msg.value == entryFee, "Incorrect entry fee");

        players.push(msg.sender);

        emit Entered(msg.sender);
    }

    /*
     * Get random number (pseudo-random for demo)
     */
    function getRandomNumber() internal view returns (uint256) {
        return uint256(
            keccak256(
                abi.encodePacked(block.timestamp, msg.sender, players.length)
            )
        );
    }

    /*
     * Pick winner
     */
    function pickWinner() external onlyOwner {
        require(players.length > 0, "No players");

        uint256 randomIndex = getRandomNumber() % players.length;
        address winner = players[randomIndex];

        uint256 prize = address(this).balance;

        (bool success, ) = payable(winner).call{value: prize}("");
        require(success, "Transfer failed");

        emit WinnerPicked(winner, prize);

        // Reset lottery
        delete players;
    }

    /*
     * View players
     */
    function getPlayers() external view returns (address[] memory) {
        return players;
    }
}