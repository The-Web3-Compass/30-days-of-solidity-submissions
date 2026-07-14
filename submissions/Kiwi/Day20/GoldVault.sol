//SPDX-License-Identifier:MIT
pragma solidity^0.8.0;

contract GoldVault{

    mapping(address => uint256)public goldenBalance;

    uint256 private _status;
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2; 

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant(){
        require(_status != _ENTERED,"Reentrant call blocked");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;

    }

    function deposit() external payable {
        require(msg.value > 0,"Deposit must be more than 0");
        goldenBalance[msg.sender] += msg.value;
    }

    function vulnerableWithdraw() external nonReentrant {
        uint256 amount = goldenBalance[msg.sender];
        require(amount > 0,"No balance to withdraw");

        (bool sent, )=msg.sender.call{value:amount}("");
        require(sent, "ETH transfer failed");
        goldenBalance[msg.sender] = 0;
    
    }
    function safeWithdraw() external nonReentrant {
        uint256 amount = goldenBalance[msg.sender];
        require(amount > 0,"No balance to withdraw");
        goldenBalance[msg.sender] = 0;
        (bool sent, )=msg.sender.call{value:amount}("");
        require(sent, "ETH transfer failed");

    }

}