//SPDX-License-Identifier:MIT
pragma solidity ^0.8.2;

// Create our own token.

// ERC-20 lays down a consistent interface — a shared language — that all tokens should speak. It covers things like:
// - **Naming and Display**
//     Your token must have a `name`, `symbol`, and `decimals` so wallets can show them properly.
// - **Balances and Supply**
//     There must be a `totalSupply()` and a way to check how many tokens an address owns using `balanceOf(address)`.
// - **Transfers**
//     There should be a `transfer()` function that lets people send tokens from their wallet to someone else.
// - **Approvals and Delegated Spending**
//     Your token needs an `approve()` function so users can let someone else (like a smart contract) spend tokens on their behalf.
//     And a `transferFrom()` function to actually carry out those approved transfers.
// - **Event Emissions**
//     Whenever tokens move or permissions are granted, your contract should emit `Transfer` and `Approval` events.
//     These help wallets, DApps, and block explorers track what’s happening on-chain.

// Importance:
// - Show up in wallets like MetaMask
// - Be traded on decentralized exchanges
// - Work with lending protocols, DAOs, or any other app that supports ERC-20s

contract SimpleERC20{
    string public name="Web3 Compass";
    string public symbol="COM";
    uint8 public decimals=18; 
    uint256 public totalSupply; // This tracks the total number of tokens that exist.

    mapping(address=>uint256) public balanceOf;// It tells how many tokens each address holds.
    mapping(address=>mapping(address=>uint256)) public allowance;// It tracks who's allowed to spend tokens on behalf of whom and how much.
    // This is a core feature of ERC-20: letting someone else (like a DApp or smart contract) move your tokens, but only if you've approved it first.

    // You’ll notice the indexed keyword on the address parameters — this makes those values searchable in the event logs. So if you want to find all transfers from a specific address, or all approvals to a certain spender, that’s how you do it.
    event Transfer(address indexed from,address indexed to,uint256 value);
    event Approval(address indexed owner,address indexed spender,uint256 value);

    constructor(uint256 _initialSupply){
        totalSupply=_initialSupply*(10**uint256(decimals));
        balanceOf[msg.sender]=totalSupply;
        // Here set the "from" address as "address(0)", which is a special way of saying:"These tokens didn't come from another user-they were created out of thin air".
        // Wallets,explorers and frontend tools understand this pattern and display it as a minting event.
        emit Transfer(address(0),msg.sender,totalSupply);
    }

    // "Internal" function means that it can only be called within this contract or its derived contracts---not by external users or other contracts.
    function _transfer(address _from,address _to,uint256 _value) internal{
        require(_to!=address(0),"Invalid address");
        balanceOf[_from]-=_value;
        balanceOf[_to]+=_value;
        emit Transfer(_from,_to,_value);
    }

    // "virtual" means that you can override a function from a parent contract in a child contract.
    function transfer(address _to,uint256 _value) public virtual returns (bool){
        require(balanceOf[msg.sender]>=_value,"Not enough balance");
        _transfer(msg.sender,_to,_value);
        return true;

    }

    // This function allows you to give another address(usually a smart contract) permission to spend tokens on your behalf.
    // "_spender" is the address you are authorizing.
    function approve(address _spender,uint256 _value) public returns(bool){
        allowance[msg.sender][_spender]=_value;
        emit Approval(msg.sender,_spender,_value);
        return true;
    }
   // This function allows someone who has been **approved** to actually move tokens on someone else’s behalf.

    // Here’s the typical flow:

    // 1. Alice calls `approve(Bob, 100)`
    // 2. Bob calls `transferFrom(Alice, Carol, 50)`

    // In this example:

    // - Bob is `msg.sender`
    // - Alice is `_from`
    // - Carol is `_to`

    // The function does three things:

    // - It checks that Alice actually has the tokens (`balanceOf[_from] >= _value`)
    // - It checks that Bob has been approved to spend at least that amount (`allowance[_from][msg.sender] >= _value`)
    // - It decreases Bob’s allowance by the amount
    // - Then it calls `_transfer()` to perform the actual token movement

    // This function is what makes things like DEX swaps and DAO voting possible — any time a smart contract moves your tokens, it’s probably using `transferFrom()` under the hood.

    function transferFrom(address _from,address _to,uint256 _value) public virtual returns(bool){
        require(balanceOf[_from]>=_value,"Not enough balance");
        require(allowance[_from][msg.sender]>=_value,"Allowance too low");
        allowance[_from][msg.sender]-=_value;
        _transfer(_from,_to,_value);
        return true;
    }
}


// Easy way to import ERC20.sol from openzeppelin.
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// contract MyToken is ERC20{
//     constructor(uint256 initialSupply) ERC20("MyToken","MTK"){
//         _mint(msg.sender,initialSupply*10**decimals());
//     }

// }