// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

contract GoldVault {
    uint private status;
    uint private notEntered = 1;
    uint private entered = 2;

    mapping(address => uint) goldBalance;

    modifier nonReentrant() {
        require(status != entered, "chalu banega");
        status = entered;
        _;
        status = notEntered;
    }

    function deposit() external payable {
        require(msg.value > 0, "gareeb");
        goldBalance[msg.sender] += msg.value;
    }

    function vulnerableWithdraw() public {
        require(goldBalance[msg.sender] > 0, "gullak khali hai");

        (bool success, ) = msg.sender.call{value: goldBalance[msg.sender]}("");
        require(success, "transaction failed");
        goldBalance[msg.sender] = 0;
    }

    function safeWithdraw() public nonReentrant {
        require(goldBalance[msg.sender] > 0, "gullak khali hai");

        goldBalance[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: goldBalance[msg.sender]}("");
        require(success, "transaction failed");
    }

    function getBalance() public view returns (uint) {
        return goldBalance[msg.sender];
    }

    //! check > effect > interactions
}
