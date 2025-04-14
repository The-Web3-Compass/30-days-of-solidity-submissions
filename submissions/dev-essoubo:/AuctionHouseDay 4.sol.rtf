{\rtf1\ansi\ansicpg1252\cocoartf2821
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fswiss\fcharset0 Helvetica;}
{\colortbl;\red255\green255\blue255;}
{\*\expandedcolortbl;;}
\paperw11900\paperh16840\margl1440\margr1440\vieww28600\viewh17440\viewkind0
\pard\tx720\tx1440\tx2160\tx2880\tx3600\tx4320\tx5040\tx5760\tx6480\tx7200\tx7920\tx8640\pardirnatural\partightenfactor0

\f0\fs24 \cf0 // SPDX-License-Identifier: MIT\
pragma solidity ^0.8.0;\
\
contract AuctionHouse \{\
    address public owner;\
    string public itemName;\
    string public itemDescription;\
    uint public startingPrice;\
    uint public endTime;\
    bool public ended;\
\
    address public highestBidder;\
    uint public highestBid;\
\
    // Mapping pour suivre les montants que les ench\'e9risseurs peuvent retirer\
    mapping(address => uint) public pendingReturns;\
\
    // \'c9v\'e9nements pour informer les clients des actions\
    event NewBid(address bidder, uint amount);\
    event AuctionEnded(address winner, uint amount);\
\
    // Modificateurs\
    modifier onlyOwner() \{\
        require(msg.sender == owner, "Seul le proprietaire peut effectuer cette action");\
        _;\
    \}\
\
    modifier auctionActive() \{\
        require(block.timestamp < endTime, "L'enchere est terminee");\
        require(!ended, "L'enchere a deja ete finalisee");\
        _;\
    \}\
\
    modifier auctionEnded() \{\
        require(block.timestamp >= endTime, "L'enchere n'est pas encore terminee");\
        require(!ended, "L'enchere a deja ete finalisee");\
        _;\
    \}\
\
    constructor(\
        string memory _itemName,\
        string memory _itemDescription,\
        uint _startingPrice,\
        uint _durationInMinutes\
    ) \{\
        owner = msg.sender;\
        itemName = _itemName;\
        itemDescription = _itemDescription;\
        startingPrice = _startingPrice;\
        endTime = block.timestamp + (_durationInMinutes * 1 minutes);\
        ended = false;\
    \}\
\
    function bid() public payable auctionActive \{\
        // V\'e9rifier que l'ench\'e8re est sup\'e9rieure au prix de d\'e9part\
        require(msg.value > startingPrice, "Le montant doit etre superieur au prix de depart");\
        \
        // V\'e9rifier que l'ench\'e8re est sup\'e9rieure \'e0 l'ench\'e8re la plus \'e9lev\'e9e\
        require(msg.value > highestBid, "Il existe deja une enchere plus elevee");\
\
        // Si ce n'est pas la premi\'e8re ench\'e8re, permettre \'e0 l'ench\'e9risseur pr\'e9c\'e9dent de retirer son argent\
        if (highestBidder != address(0)) \{\
            pendingReturns[highestBidder] += highestBid;\
        \}\
\
        // Mettre \'e0 jour l'ench\'e9risseur le plus offrant et son ench\'e8re\
        highestBidder = msg.sender;\
        highestBid = msg.value;\
\
        // \'c9mettre un \'e9v\'e9nement pour notifier les clients\
        emit NewBid(msg.sender, msg.value);\
    \}\
\
    // Fonction pour qu'un ench\'e9risseur puisse r\'e9cup\'e9rer son argent s'il a \'e9t\'e9 surench\'e9ri\
    function withdraw() public returns (bool) \{\
        uint amount = pendingReturns[msg.sender];\
        if (amount > 0) \{\
            pendingReturns[msg.sender] = 0;\
            \
            if (!payable(msg.sender).send(amount)) \{\
                // Si le transfert \'e9choue, restaurer le solde\
                pendingReturns[msg.sender] = amount;\
                return false;\
            \}\
        \}\
        return true;\
    \}\
\
    // Fonction pour terminer l'ench\'e8re\
    function endAuction() public auctionEnded \{\
        ended = true;\
        emit AuctionEnded(highestBidder, highestBid);\
        \
        // Transf\'e9rer le montant de l'ench\'e8re gagnante au propri\'e9taire\
        payable(owner).transfer(highestBid);\
    \}\
\
    // Obtenir le temps restant en secondes\
    function getRemainingTime() public view returns (uint) \{\
        if (block.timestamp >= endTime) return 0;\
        return endTime - block.timestamp;\
    \}\
\
    // Obtenir des informations sur l'ench\'e8re\
    function getAuctionInfo() public view returns (\
        string memory _itemName,\
        string memory _itemDescription,\
        uint _startingPrice,\
        uint _endTime,\
        bool _ended,\
        address _highestBidder,\
        uint _highestBid\
    ) \{\
        return (itemName, itemDescription, startingPrice, endTime, ended, highestBidder, highestBid);\
    \}\
\}}