//SPDX-License-Identifier:MIT
pragma solidity ^0.8.2;

// It can be seen that in traditional event management systems, identity verification often relies on centralized databases and complex permission control mechanisms. Participants need to register accounts and remember passwords, while organizers must maintain user lists and handle tedious tasks such as password recovery.
// This model not only results in a complex user experience but also carries risks of single points of failure and data breaches.
// Blockchain technology offers us a completely new approach: verifying identity through cryptographic proof rather than centralized authorization. 
// This "SignThis Contract" is a practical implementation of this concept — leveraging digital signature technology to build a decentralized, secure, and efficient event management system.


// Contract structure:
// 1. Event setup: the organizer defines the name, date and max attendee count;
// 2. Crypotographic Invites: instead of storing address, the backends signs a message for each approved guest;
// 3. Check-In Flow: guests submit their signed message and the contract uses "ecrecover" to verify it was signed by the organizer;
// 4. Security&Flexibility: no address list on-chain, no preloaded whitelist and no wasted gas. Only valid, signed attendees get in---and it's all fully verificable on-chain.

// What we wil learn:
// 1. How to hash structured data("abi.encodePacked")
// 2. Why Ethereum uses signed message prefixes
// 3. How "ecrecover()" lets you verify off-chain approvals on-chain.
// 4. How to implement a lightweight,gas-efficient access system that's actually used in production today.

// Build a signature-based,gas-optimized,private access system for an event.
contract EventEntry{
    string public eventName; // what the event is
    address public organizer;// The ethereum address of the event organizer. 
                             // Only this address can sign attendee approvals.
                             // Only this address can change the event status.
    uint256 public eventDate;
    uint256 public maxAttendees;
    uint256 public attendeeCount;
    bool public isEventActive;// It tracks whether the event is currently accepting check-ins.

    mapping(address=>bool) public hasAttended;

    event EventCreated(string name,uint256 date,uint256 maxAttendees);
    event AttendeeCheckedIn(address attendee,uint256 timestamp);
    event EventStatusChanged(bool isActive);// lets the organizer pause/resume the event.

    constructor(string memory _eventName,uint256 _eventDate_unix,uint256 _maxAttendees){
        eventName=_eventName;
        eventDate=_eventDate_unix;
        maxAttendees=_maxAttendees;
        organizer=msg.sender;
        isEventActive=true;

        emit EventCreated(_eventName,_eventDate_unix,_maxAttendees);
    }

    modifier onlyOrganizer(){
        require(msg.sender==organizer,"Only the event organizer can call this function");
        _;
    }

    // Use this function to pause or resume check-ins.
    function setEventStatus(bool _isActive) external onlyOrganizer{
        isEventActive=_isActive;
        emit EventStatusChanged(_isActive);
    }
    
                 
    // Generate the hash data for the structural information for the subsequent signatures.
    // Only one hash for specific activity and attendee.
    function getMessageHash(address _attendee) public view returns(bytes32){
        return keccak256(abi.encodePacked(address(this),eventName,_attendee));
    }

    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns(bytes32){
        // takes your origina message hash and wraps it with a prefix
        // When we recover the signer's address later using "ecrecover()", we will be recovering it from prefix-wrapped hash, not the raw hash.
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",_messageHash));
    }

    // This function can verify that if the signature is really created by the organizer and if it was for this attendee.
    // _signature = [ r (32 bytes) ] + [ s (32 bytes) ] + [ v (1 byte) ]
            //  ←────────── 65 bytes ──────────→
    // _signature:
    // The attendee (or their wallet/frontend) provides it.
    // Flow:
    // The organizer signs a message off-chain for an approved attendee.
    // The attendee receives this signature (usually via email, QR code, or app).
    // The attendee’s wallet submits it when calling checkIn().
    function verifySignature(address _attendee,bytes memory _signature) public view returns(bool){
        // This creates the exact hash that organizer signed off-chain for a specific attendee.
        // hash(contract address+event name+attendee address) : it ensures that this signature is tied to this specific contract, it's only valid for this event and it belongs to this exact user.
        bytes32 messageHash=getMessageHash(_attendee);
        // Wrap the message hash with Ethereum's standard prefix.
        bytes32 ethSignedMessageHash=getEthSignedMessageHash(messageHash);
        // Use "ecrecover()"(via the helper function "recoverSigner") to extract the address of who signed the message.
        // Compare the address with "organizer"--- the address that deployed this contract.
        // If they match, the sigature is valid. If not, someone forged it or it was signed by someone else.
        return recoverSigner(ethSignedMessageHash,_signature)==organizer;
    }

    // Final step in signature-based entry system. It looks at a signature and figures out which Ethereum address signed it.
    function recoverSigner(bytes32 _ethSignedMessageHash,bytes memory _signature) public pure returns(address){
        // All Ethereum signatures are 65 bytes long.
        require(_signature.length==65,"Invalid signature length");
        // _signature = [ r (32 bytes) ] + [ s (32 bytes) ] + [ v (1 byte) ]
        //  ←────────── 65 bytes ──────────→
        bytes32 r;
        bytes32 s;
        uint8 v;
        // Assembly is a low-level way to access data directly from memory.
        assembly{
            r:=mload(add(_signature,32))
            s:=mload(add(_signature,64))
            v:=byte(0,mload(add(_signature,96)))
        }
        if(v<27){
            v+=27;
        }
        // v is 27 or 28
        require(v==27||v==28,"Invalid signature 'v' value");
        // return the address of the signer
        return ecrecover(_ethSignedMessageHash,v,r,s);
    }

    // This is the main function that attendees will call when they arrive at the event.
    // This function can prove if someone was invited, someone is checking in within the allowed window,the event is still open,someone hasn't already checked in and there's still room.
    function checkIn(bytes memory _signature) external{
        require(isEventActive,"Event is not active");
        require(block.timestamp<=eventDate+1 days,"Event has ended");
        require(!hasAttended[msg.sender],"Attendee has already checked in");
        require(attendeeCount<maxAttendees,"Maximum attendees reached");
        require(verifySignature(msg.sender,_signature),"Invalid signature");

        hasAttended[msg.sender]=true;
        attendeeCount++;

        emit AttendeeCheckedIn(msg.sender,block.timestamp);
    }
}

