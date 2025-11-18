//SPDX-License-Identifier:MIT
pragma solidity ^0.8.2;
// Sell tokens before the project officially lauches on top of ERC20 token.
// In real-world crypto projets---they run a token sale(also called a preale or ICO),where users send ETH and receive tokens in return at a fixed rate.

// We’re about to build a **simple but powerful token sale contract** — the kind you’d use for a presale, early backer round, or launch event.
// This contract will allow you to:
// - Sell your custom ERC-20 token at a fixed price in ETH
// - Set a start and end time for the sale
// - Enforce minimum and maximum purchase amounts
// - Automatically handle token distribution
// - Prevent transfers during the sale (to stop flipping or bot dumping)
// - Finalize the sale and transfer raised ETH to the project owner

// So the flow will look like this:
// 1. You(Project party) deploy the token sale contract
// 2. It(contract) creates and holds all the tokens
// 3. Buyers send ETH and get tokens in return
// 4. Transfers are **locked** during the sale
// 5. After the sale ends, you finalize it and claim your ETH

import "./Day12ERC20.sol";
//This contract inherits from "SimpleERC20".
contract SimplifiedTokenSale is SimpleERC20{
    uint256 public tokenPrice;// How much ETH(in wei) each token costs
    uint256 public saleStartTime;
    uint256 public saleEndTime;
    uint256 public minPurchase;
    uint256 public maxPurchase;
    uint256 public totalRaised;
    address public projectOwner;// The address that receives the ETH once the sale is done.
    bool public finalized=false;// Has the sale been officially closed?
    bool private initialTransferDone=false;// Used to ensure the contract received all tokens before locking transfers.

    // Triggered when someone successfully buys tokens. It logs who bought,how much ETH they paid, and how many tokens they received.
    event TokenPurchased(address indexed buyer,uint256 etherAmount,uint256 tokenAmount);
    // Triggered when the sale ends.Logs the total ETH raised and the number of tokens sold.
    event SaleFinalized(uint256 totalRaised,uint256 totalTokensSold);

    //This contract inherits from "SimpleERC20",so we need to pass "_initialSupply" to the parent contract.
    constructor(uint256 _initialSupply,uint256 _tokenPrice,uint256 _saleDurationInSeconds,uint256 _minPurchase,uint256 _maxPurchase,address _projectOwner)SimpleERC20(_initialSupply){
        tokenPrice=_tokenPrice;
        saleStartTime=block.timestamp;
        saleEndTime=block.timestamp+_saleDurationInSeconds;
        // These two lines define the limits on how much ETH a buyer can send.
        minPurchase=_minPurchase;
        maxPurchase=_maxPurchase;
        projectOwner=_projectOwner;

        // Transfer all tokens to this contract for sale.
        // "totalSupply" is public state variable in parent contract.
        _transfer(msg.sender,address(this),totalSupply);

        //Mark that we've moved tokens from the deployer
        initialTransferDone=true;
    }

    function isSaleActive() public view returns (bool){
        return(!finalized&&block.timestamp>=saleStartTime&&block.timestamp<=saleEndTime);
    }

    function buyTokens() public payable{
        require(isSaleActive(),"Sale is not active");
        require(msg.value>=minPurchase,"Amount is below minimum purchase");
        require(msg.value<=maxPurchase,"Amount exceeds maximum purchase");

        uint256 tokenAmount=(msg.value*10**uint256(decimals))/tokenPrice;
        require(balanceOf[address(this)]>=tokenAmount,"Not enough tokens left for sale");

        totalRaised+=msg.value;
        _transfer(address(this),msg.sender,tokenAmount);
        emit TokenPurchased(msg.sender,msg.value,tokenAmount);

    }
    
    // This function overrides the "transfer" function in parent contracts.
    function transfer(address _to,uint256 _value) public override returns(bool){
        //To ensure that no one can send tokens to others or trade them during the sale period.This helps prevent:
        // - Premature trading or speculation;
        // - Bots scooping up tokens and flipping them;
        // - Manipulation before the token is live.
        // Once the sale is finialized, the condition becomes false and transfers are allowed as usual.
        if(!finalized && msg.sender!=address(this) && initialTransferDone){
            require(false,"Tokens are locked until sale is finalized");
        }
        // If the sale not satisfy the condition above, call the parent contarct 's "transfer()" function.
        return super.transfer(_to,_value);
    }

    // This function overrides the "transferFrom" function in parent contracts.
    function transferFrom(address _from,address _to,uint256 _value) public override returns(bool){
        // Check if the sale still going and if the transfer comes from the contract.
        // If we block the transaction, this ensures that even approved spenders cannot move tokens around on someone else's behalf during the sale.
        if(!finalized && _from!=address(this)){
            require(false,"Tokens are locked until sale is finalized");
        }
        return super.transferFrom(_from,_to,_value);
    } 

    // This is the function that ends the token sale.
    function finalizeSale() public payable{
        require(msg.sender==projectOwner,"only Owner can call the function");
        require(!finalized,"Sale already finalized");
        require(block.timestamp>saleEndTime,"Sale not finished yet");

        // Update the "finalized" staet variable so that other funtions(like "transfer()" and "transferFrom()") know the sale is over.
        finalized=true;
        uint256 tokensSold = totalSupply-balanceOf[address(this)];
        
        (bool success,)=projectOwner.call{value:address(this).balance}("");
        require(success,"Transfer to project owner failed");

        // Emit a "SaleFinalized" event with the total ETH raised and the number of tokens sold. 
        emit SaleFinalized(totalRaised,tokensSold);
    }


    function timeRemaining() public view returns(uint256){
        if(block.timestamp>=saleEndTime){
            return 0;
        }
        return saleEndTime-block.timestamp;
    }

    // This function tells you how many tokens are available for purchase.
    function tokensAvailable() public view returns (uint256){
        return balanceOf[address(this)];
    }

    // "receive()" function is a special fallback function that fets triggered when someone sends ETH directly to the contract address and doesn't specify any function to call.
    // Anytime someone sends ETH to this contract, the contract will automatically call "buyTokens()".
    receive() external payable{
        buyTokens();
    }



}
