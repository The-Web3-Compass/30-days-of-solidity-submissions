//SPDX-License-Identifier:MIT
pragma solidity ^0.8.2;
// Build a modular subscription manager,the kind you'd use for a SaaS app or dApp.

// Upgradeable contracts: seperate storage from logic.
// Contract that stores the data --- proxy. Another contract holds the logic. The proxy uses "delegatecall" to execute logic from the external contarct but on its own storage.
// If the contract is not upgradeable, it will lose all the old data when deploying a new contract.

// This contract is the blueprint. It defines who the owner is, where the logic contract lives and the actual storage layout:user subscriptions, plan prices, drations,etc.
// Think of this like the shared brain that both the proxy and logic contracts understand.

// This is standalone contract that only holds state variables---it doesn't include any functions.
// By importing and inheriting this layout, both contracts can share and manipulate the same data.
contract SubscriptionStorageLayout{
    address public logicContract;// This stores the current implementation address，the logic contract address.
    address public owner; // The one who can upgrade to new logic versions.

    struct Subscription{
        uint8 planId; // The number symbol for the user's plan.
        uint256 expiry; // The timestamp indicating when the subscription runs out.
        bool paused; // A switch to temporarily stop a user's subscription without deleting it.
    }

    mapping(address=>Subscription) public subscriptions; // user address=> subscription project
    mapping(uint8=>uint256) public planPrices; // plan=> eth costs
    mapping(uint8=>uint256) public planDuration;// plan=> duration of plan
}

// Deployment:
// 1. create 3 contracts;
// 2. compile all contracts;
// 3. deploy the logic contract(V1);
// 4. deploy the proxy contract:SubscriptionStorage
// 5. interact with V1 via the Proxy
// 6. test the subscription flow(V1);
// 7. upgrade to V2 logic;
// 8. use V2 features via the same proxy.