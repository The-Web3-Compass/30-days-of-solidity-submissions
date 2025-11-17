//SPDX-License-Identifier:MIT
pragma solidity ^0.8.2;
// Build a decentralized lottery
// It can give a random number, a cryptographic proof that it was generated fairly and it delivers both directly to smart contract. This is how we bring trusted randomness into an untrusting world.
// It is provably fair, fully automated and imposssible to rig.
// In this contract, we are building a tamper-proof, automated, on-chain lottery system that anyone can enter.

// "VRFConsumerBaseV2Plus": This is a base contract provided by Chainlink. When inheriting from this contract, we can get a special function called "fulfillRandomWords" that Chainlink automatically calls when the random number is ready.
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
// "VRFV2PlusClient": This is a helper library that gives us an easy way to structure and format the randomness request we send to Chainlink.
    // It can configure how many random numbers we want, how much gas to use for the callback and which chainlink job to use via keyHash.
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract FairChainLottery is VRFConsumerBaseV2Plus{
    // "enum" is a way of creating a list of named states that a variable can take.
    // open: the lottery is liva and players can enter;
    // closed:the lottery is inactive. No entries, no picks.
    // calculating: the lottery is currently asking chainlink for a random number, and no one can enter or restart the game until we get the result.
    enum LOTTERY_STATE{OPEN,CLOSED,CALCULATING}
    LOTTERY_STATE public lotteryState;

    address payable[] public players;
    address public recentWinner;
    uint256 public entryFee;

    // Chainlink VRF config
    // Some variables for randomness engine
    uint256 public subscriptionId;// chainlink account ID
    bytes32 public keyHash;// This identifies which Chainlink oracle job you want to run. This is a unique identifier for the specific configuration of the VRF service.
    uint32 public callbackGasLimit=100000;// This set a gas budget for chainlink when it calls the contract back with the result.
    uint16 public requestConfirmations=3;// This set how many block confirmations Chainlink waits for before generating the random number.
    uint32 public numWords=1;// It tells how many random numbers in one request.
    uint256 public latestRequestId;// Every time making a randomness request, Chainlink would give a request ID. It is mainly for tracking purpose.

    constructor(
        address vrfCoordinator,// This is the address of Chainlink's VRF Coordinator on the blockchain you are depolying to. It acts as the middleman that receives randomness requests and returns the results.
        uint256 _subscriptionId,// This is Chainlink suscription ID which is used for paying VRF requests.
        bytes32 _keyHash,// This defines which randomness job Chainlink should use.
        uint256 _entryFee// This is the amount of ETH required to enter the lottery.
    )VRFConsumerBaseV2Plus(vrfCoordinator){
        subscriptionId=_subscriptionId;
        keyHash=_keyHash;
        entryFee=_entryFee;
        lotteryState=LOTTERY_STATE.CLOSED;
    }

    function enter() public payable{
        require(lotteryState==LOTTERY_STATE.OPEN,"Lottery not open");
        require(msg.value>=entryFee,"Not enough ETH");
        // Wrap "msg.sender" in "payable(...)" because it is potentially send ETH back to this address if they win.
        players.push(payable(msg.sender));
    }

    function startLottery() external onlyOwner{
        require(lotteryState==LOTTERY_STATE.CLOSED,"Can't start yet");
        lotteryState=LOTTERY_STATE.OPEN;

    }

    // When someone needs to officially end the game and ask Chainlink to roll the dice.
    // Make the request and send it to Chainlink.
    function endLottery() external onlyOwner{
        require(lotteryState==LOTTERY_STATE.OPEN,"Lottery not open");
        lotteryState=LOTTERY_STATE.CALCULATING;

        // Owner is making a randomness request to send to Chainlink. It tells :
            // which randomness job to use "keyHash";
            // who is paying shown in "subscriptionId";
            // how many confirmation to wait for;
            // how much gas to use when it responds;
            // how many random numbers we want.
        VRFV2PlusClient.RandomWordsRequest memory req=VRFV2PlusClient.RandomWordsRequest({keyHash:keyHash,subId:subscriptionId,requestConfirmations:requestConfirmations,callbackGasLimit:callbackGasLimit,numWords:numWords,extraArgs:VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment:true}))});
        // This line actually sends the request to Chainlink VRF.
        latestRequestId=s_vrfCoordinator.requestRandomWords(req);

    }

    // Once Chainlink receives our request and it could send the result back by automatically calling this function.
    function fulfillRandomWords(uint256,uint256[] calldata randomWords) internal override{
        require(lotteryState==LOTTERY_STATE.CALCULATING,"Not ready to pick winner");
        uint256 winnerIndex=randomWords[0]%players.length;
        address payable winner=players[winnerIndex];
        recentWinner=winner;

        // Clear all the players.
        players= new address payable[](0);
        lotteryState=LOTTERY_STATE.CLOSED;

        (bool sent,)=winner.call{value:address(this).balance}("");
        require(sent,"Failed to send ETH to winner");

    }

    function getPlayers() external view returns(address payable[] memory){
        return players;
    }


}
